<?php
/**
 * Product Enriched API Controller
 *
 * Exposes enriched product data via REST-like endpoint.
 *
 * DATA ENDPOINTS:
 *   GET ?action=getByIds&ids=1|2|3|4|5&ws_key=YOUR_KEY
 *   GET ?action=getByCategory&category=123&limit=20&offset=0&ws_key=YOUR_KEY
 *   GET ?action=getByReference&reference=ABC123&ws_key=YOUR_KEY
 *   GET ?action=getByEan13&ean13=1234567890123&ws_key=YOUR_KEY
 *
 * SYNC ENDPOINTS (No cron needed):
 *   GET ?action=batchSync&batch_size=500&ws_key=YOUR_KEY                    # Sync all products
 *   GET ?action=batchSync&batch_size=500&category=123&ws_key=YOUR_KEY       # Sync specific category
 *   GET ?action=syncProgress&ws_key=YOUR_KEY                                 # Check progress
 *   GET ?action=syncProgress&category=123&ws_key=YOUR_KEY                    # Check category progress
 *   GET ?action=resetSync&ws_key=YOUR_KEY                                    # Reset progress
 *   GET ?action=getCategories&ws_key=YOUR_KEY                                # List categories
 */

class ProductEnrichedApiModuleFrontController extends ModuleFrontController
{
    public $ssl = true;

    public function initContent()
    {
        parent::initContent();

        // Set JSON response headers
        header('Content-Type: application/json; charset=utf-8');
        header('Access-Control-Allow-Origin: *');
        header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
        header('Access-Control-Allow-Headers: Content-Type, Authorization');

        // Handle preflight requests
        if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
            http_response_code(200);
            die();
        }

        // Validate API key
        $wsKey = Tools::getValue('ws_key');
        if (!$this->validateApiKey($wsKey)) {
            $this->returnError('Invalid or missing API key', 401);
            return;
        }

        // Get action parameter
        $action = Tools::getValue('action', 'getByIds');

        require_once _PS_MODULE_DIR_ . 'productenriched/classes/ProductEnrichedManager.php';

        try {
            switch ($action) {
                // Data endpoints
                case 'getByIds':
                    $this->handleGetByIds();
                    break;

                case 'getByCategory':
                    $this->handleGetByCategory();
                    break;

                case 'getByReference':
                    $this->handleGetByReference();
                    break;

                case 'getByEan13':
                    $this->handleGetByEan13();
                    break;

                case 'getStats':
                    $this->handleGetStats();
                    break;

                // Sync endpoints (no cron needed)
                case 'batchSync':
                    $this->handleBatchSync();
                    break;

                case 'syncProgress':
                    $this->handleSyncProgress();
                    break;

                case 'resetSync':
                    $this->handleResetSync();
                    break;

                case 'getCategories':
                    $this->handleGetCategories();
                    break;

                case 'syncProduct':
                    $this->handleSyncProduct();
                    break;

                case 'debug':
                    $this->handleDebug();
                    break;

                case 'findMissing':
                    $this->handleFindMissing();
                    break;

                default:
                    $this->returnError('Unknown action: ' . $action, 400);
            }
        } catch (Exception $e) {
            $this->returnError('Server error: ' . $e->getMessage(), 500);
        }

        die();
    }

    /**
     * Get enriched data for specific product IDs
     */
    private function handleGetByIds()
    {
        $ids = Tools::getValue('ids', '');

        if (empty($ids)) {
            $this->returnError('Parameter "ids" is required', 400);
            return;
        }

        // Parse IDs (supports pipe-separated: 1|2|3 or comma-separated: 1,2,3)
        $productIds = preg_split('/[|,]/', $ids);
        $productIds = array_filter(array_map('intval', $productIds));

        if (empty($productIds)) {
            $this->returnError('No valid product IDs provided', 400);
            return;
        }

        // Limit to prevent abuse
        if (count($productIds) > 100) {
            $productIds = array_slice($productIds, 0, 100);
        }

        $activeOnly = (bool)Tools::getValue('active_only', true);
        $products = ProductEnrichedManager::getEnrichedProducts($productIds, null, $activeOnly);

        // Check for products not in enriched table and sync them on-the-fly
        $missingIds = array_diff($productIds, array_keys($products));
        if (!empty($missingIds)) {
            foreach ($missingIds as $missingId) {
                ProductEnrichedManager::syncProduct($missingId);
            }
            // Re-fetch after sync
            $products = ProductEnrichedManager::getEnrichedProducts($productIds, null, $activeOnly);
        }

        $this->returnSuccess(array(
            'products' => array_values($products),
            'count' => count($products),
        ));
    }

    /**
     * Get enriched data for products in a category
     */
    private function handleGetByCategory()
    {
        $categoryId = (int)Tools::getValue('category');

        if ($categoryId <= 0) {
            $this->returnError('Parameter "category" is required and must be a valid ID', 400);
            return;
        }

        $limit = (int)Tools::getValue('limit', 20);
        $offset = (int)Tools::getValue('offset', 0);
        $activeOnly = (bool)Tools::getValue('active_only', true);

        // Sanitize limits
        $limit = min(max($limit, 1), 100);
        $offset = max($offset, 0);

        $products = ProductEnrichedManager::getEnrichedProductsByCategory(
            $categoryId,
            $limit,
            $offset,
            null,
            $activeOnly
        );

        $this->returnSuccess(array(
            'products' => $products,
            'count' => count($products),
            'limit' => $limit,
            'offset' => $offset,
            'category_id' => $categoryId,
        ));
    }

    /**
     * Get enriched data for a product by reference
     */
    private function handleGetByReference()
    {
        $reference = Tools::getValue('reference', '');

        if (empty($reference)) {
            $this->returnError('Parameter "reference" is required', 400);
            return;
        }

        $product = ProductEnrichedManager::getEnrichedProductByReference($reference);

        if (!$product) {
            // Try to find and sync product
            $sql = 'SELECT id_product FROM ' . _DB_PREFIX_ . 'product WHERE reference = "' . pSQL($reference) . '" LIMIT 1';
            $result = Db::getInstance()->getRow($sql);

            if ($result) {
                ProductEnrichedManager::syncProduct((int)$result['id_product']);
                $product = ProductEnrichedManager::getEnrichedProductByReference($reference);
            }
        }

        if (!$product) {
            $this->returnError('Product not found with reference: ' . $reference, 404);
            return;
        }

        $this->returnSuccess(array(
            'product' => $product,
        ));
    }

    /**
     * Get enriched data for a product by EAN13 (barcode)
     */
    private function handleGetByEan13()
    {
        $ean13 = Tools::getValue('ean13', '');

        if (empty($ean13)) {
            $this->returnError('Parameter "ean13" is required', 400);
            return;
        }

        $product = ProductEnrichedManager::getEnrichedProductByEan13($ean13);

        if (!$product) {
            // Try to find and sync product
            $sql = 'SELECT id_product FROM ' . _DB_PREFIX_ . 'product WHERE ean13 = "' . pSQL($ean13) . '" LIMIT 1';
            $result = Db::getInstance()->getRow($sql);

            if ($result) {
                ProductEnrichedManager::syncProduct((int)$result['id_product']);
                $product = ProductEnrichedManager::getEnrichedProductByEan13($ean13);
            }
        }

        if (!$product) {
            $this->returnError('Product not found with EAN13: ' . $ean13, 404);
            return;
        }

        $this->returnSuccess(array(
            'product' => $product,
        ));
    }

    /**
     * Get module statistics
     */
    private function handleGetStats()
    {
        $stats = ProductEnrichedManager::getStats();

        $this->returnSuccess(array(
            'stats' => $stats,
        ));
    }

    // =========================================================================
    // SYNC ENDPOINTS (No cron needed - call via URL)
    // =========================================================================

    /**
     * Batch sync products
     * Call repeatedly until status='complete'
     */
    private function handleBatchSync()
    {
        $batchSize = (int)Tools::getValue('batch_size', 500);
        $categoryId = Tools::getValue('category');

        // Sanitize batch size (100-1000)
        $batchSize = min(max($batchSize, 100), 1000);

        // Convert category to int or null
        $categoryId = $categoryId ? (int)$categoryId : null;

        $result = ProductEnrichedManager::batchSync($batchSize, $categoryId);

        $this->returnSuccess($result);
    }

    /**
     * Get current sync progress
     */
    private function handleSyncProgress()
    {
        $categoryId = Tools::getValue('category');
        $categoryId = $categoryId ? (int)$categoryId : null;

        $progress = ProductEnrichedManager::getBatchProgress($categoryId);

        $this->returnSuccess($progress);
    }

    /**
     * Reset sync progress (start over)
     */
    private function handleResetSync()
    {
        $categoryId = Tools::getValue('category');
        $categoryId = $categoryId ? (int)$categoryId : null;

        ProductEnrichedManager::resetBatchProgress($categoryId);

        $this->returnSuccess(array(
            'message' => 'Sync progress reset successfully',
            'category_id' => $categoryId,
        ));
    }

    /**
     * Get list of categories with product counts
     */
    private function handleGetCategories()
    {
        $categories = ProductEnrichedManager::getCategoriesWithCounts();

        $this->returnSuccess(array(
            'categories' => $categories,
            'count' => count($categories),
        ));
    }

    /**
     * Sync a single product by ID
     */
    private function handleSyncProduct()
    {
        $productId = (int)Tools::getValue('id');

        if ($productId <= 0) {
            $this->returnError('Parameter "id" is required and must be a valid product ID', 400);
            return;
        }

        $success = ProductEnrichedManager::syncProduct($productId);

        if ($success) {
            $product = ProductEnrichedManager::getEnrichedProducts(array($productId));
            $this->returnSuccess(array(
                'message' => 'Product synced successfully',
                'product' => isset($product[$productId]) ? $product[$productId] : null,
            ));
        } else {
            $this->returnError('Failed to sync product ID: ' . $productId, 500);
        }
    }

    /**
     * Debug endpoint to diagnose category/sync issues
     */
    private function handleDebug()
    {
        $categoryId = (int)Tools::getValue('category', 0);
        $idShop = (int)Context::getContext()->shop->id;

        // Count total in enriched table
        $totalEnriched = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE id_shop = ' . $idShop
        );

        // Count active in enriched table
        $activeEnriched = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE id_shop = ' . $idShop . ' AND is_active = 1'
        );

        // Count ALL rows in enriched (ignoring shop)
        $totalEnrichedAllShops = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_enriched`'
        );

        // Get distinct shop IDs in enriched table
        $shopsInEnriched = Db::getInstance()->executeS(
            'SELECT DISTINCT id_shop, COUNT(*) as cnt FROM `' . _DB_PREFIX_ . 'product_enriched` GROUP BY id_shop'
        );

        $categoryInfo = null;
        if ($categoryId > 0) {
            // Products in category_product for this category
            $inCategoryTable = (int)Db::getInstance()->getValue(
                'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'category_product` WHERE id_category = ' . $categoryId
            );

            // Enriched products that are also in this category (with shop filter)
            $enrichedInCatWithShop = (int)Db::getInstance()->getValue(
                'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_enriched` pe ' .
                'INNER JOIN `' . _DB_PREFIX_ . 'category_product` cp ON pe.id_product = cp.id_product ' .
                'WHERE cp.id_category = ' . $categoryId . ' AND pe.id_shop = ' . $idShop
            );

            // Enriched products that are also in this category (NO shop filter)
            $enrichedInCatNoShop = (int)Db::getInstance()->getValue(
                'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_enriched` pe ' .
                'INNER JOIN `' . _DB_PREFIX_ . 'category_product` cp ON pe.id_product = cp.id_product ' .
                'WHERE cp.id_category = ' . $categoryId
            );

            // Sample 5 product IDs from category
            $sampleFromCat = Db::getInstance()->executeS(
                'SELECT id_product FROM `' . _DB_PREFIX_ . 'category_product` WHERE id_category = ' . $categoryId . ' ORDER BY id_product DESC LIMIT 5'
            );
            $sampleIds = array_column($sampleFromCat, 'id_product');

            // Check if sample IDs exist in enriched table
            $sampleInEnriched = [];
            if (!empty($sampleIds)) {
                $sampleInEnriched = Db::getInstance()->executeS(
                    'SELECT id_product, id_shop, is_active FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE id_product IN (' . implode(',', $sampleIds) . ')'
                );
            }

            $categoryInfo = [
                'category_id' => $categoryId,
                'products_in_category_table' => $inCategoryTable,
                'enriched_in_category_with_shop_filter' => $enrichedInCatWithShop,
                'enriched_in_category_no_shop_filter' => $enrichedInCatNoShop,
                'sample_category_product_ids' => $sampleIds,
                'sample_in_enriched_table' => $sampleInEnriched,
            ];
        }

        $this->returnSuccess([
            'current_shop_id' => $idShop,
            'total_enriched_this_shop' => $totalEnriched,
            'active_enriched_this_shop' => $activeEnriched,
            'total_enriched_all_shops' => $totalEnrichedAllShops,
            'shops_in_enriched_table' => $shopsInEnriched,
            'category_debug' => $categoryInfo,
        ]);
    }

    /**
     * Find products that are active in product_shop but missing/inactive in enriched table
     */
    private function handleFindMissing()
    {
        $idShop = (int)Context::getContext()->shop->id;
        $offset = (int)Tools::getValue('offset', 0);
        $limit = (int)Tools::getValue('limit', 10);

        // Count active products in product_shop
        $activeInShop = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` WHERE id_shop = ' . $idShop . ' AND active = 1'
        );

        // Count synced as active in enriched
        $syncedActive = (int)Db::getInstance()->getValue(
            'SELECT COUNT(DISTINCT id_product) FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE id_shop = ' . $idShop . ' AND is_active = 1'
        );

        // Count total synced (active + inactive)
        $syncedTotal = (int)Db::getInstance()->getValue(
            'SELECT COUNT(DISTINCT id_product) FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE id_shop = ' . $idShop
        );

        // Find products active in product_shop but NOT in enriched table at all
        $notSyncedCount = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` ps ' .
            'LEFT JOIN `' . _DB_PREFIX_ . 'product_enriched` pe ON ps.id_product = pe.id_product AND pe.id_shop = ps.id_shop ' .
            'WHERE ps.id_shop = ' . $idShop . ' AND ps.active = 1 AND pe.id_product IS NULL'
        );
        $notSyncedSample = Db::getInstance()->executeS(
            'SELECT ps.id_product FROM `' . _DB_PREFIX_ . 'product_shop` ps ' .
            'LEFT JOIN `' . _DB_PREFIX_ . 'product_enriched` pe ON ps.id_product = pe.id_product AND pe.id_shop = ps.id_shop ' .
            'WHERE ps.id_shop = ' . $idShop . ' AND ps.active = 1 AND pe.id_product IS NULL ' .
            'ORDER BY ps.id_product DESC LIMIT ' . $offset . ', ' . $limit
        );

        // Find products active in product_shop but synced as INACTIVE in enriched
        $syncedInactiveCount = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` ps ' .
            'INNER JOIN `' . _DB_PREFIX_ . 'product_enriched` pe ON ps.id_product = pe.id_product AND pe.id_shop = ps.id_shop ' .
            'WHERE ps.id_shop = ' . $idShop . ' AND ps.active = 1 AND pe.is_active = 0'
        );
        $syncedInactiveSample = Db::getInstance()->executeS(
            'SELECT ps.id_product, p.active as ps_product_active, ps.active as ps_product_shop_active, pe.is_active as enriched_active ' .
            'FROM `' . _DB_PREFIX_ . 'product_shop` ps ' .
            'INNER JOIN `' . _DB_PREFIX_ . 'product` p ON ps.id_product = p.id_product ' .
            'INNER JOIN `' . _DB_PREFIX_ . 'product_enriched` pe ON ps.id_product = pe.id_product AND pe.id_shop = ps.id_shop ' .
            'WHERE ps.id_shop = ' . $idShop . ' AND ps.active = 1 AND pe.is_active = 0 ' .
            'LIMIT 10'
        );

        // Check active mismatch between ps_product and ps_product_shop
        $mismatchCount = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` ps ' .
            'INNER JOIN `' . _DB_PREFIX_ . 'product` p ON ps.id_product = p.id_product ' .
            'WHERE ps.id_shop = ' . $idShop . ' AND ps.active = 1 AND p.active = 0'
        );

        $this->returnSuccess([
            'shop_id' => $idShop,
            'counts' => [
                'active_in_product_shop' => $activeInShop,
                'synced_as_active' => $syncedActive,
                'synced_total' => $syncedTotal,
                'difference' => $activeInShop - $syncedActive,
            ],
            'not_synced_at_all' => [
                'count' => $notSyncedCount,
                'sample_ids' => array_column($notSyncedSample, 'id_product'),
            ],
            'synced_but_marked_inactive' => [
                'count' => $syncedInactiveCount,
                'sample' => $syncedInactiveSample,
            ],
            'ps_product_vs_ps_product_shop_mismatch' => [
                'count' => $mismatchCount,
                'explanation' => 'Products where ps_product_shop.active=1 but ps_product.active=0'
            ],
        ]);
    }

    /**
     * Validate webservice API key
     *
     * @param string $wsKey
     * @return bool
     */
    private function validateApiKey($wsKey)
    {
        if (empty($wsKey)) {
            return false;
        }

        // Check against PrestaShop webservice keys
        $sql = 'SELECT id_webservice_account
                FROM ' . _DB_PREFIX_ . 'webservice_account
                WHERE `key` = "' . pSQL($wsKey) . '"
                AND active = 1';

        $result = Db::getInstance()->getValue($sql);

        return !empty($result);
    }

    /**
     * Return success response
     *
     * @param array $data
     */
    private function returnSuccess($data)
    {
        echo json_encode(array(
            'success' => true,
            'data' => $data,
        ), JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    }

    /**
     * Return error response
     *
     * @param string $message
     * @param int $httpCode
     */
    private function returnError($message, $httpCode = 400)
    {
        http_response_code($httpCode);
        echo json_encode(array(
            'success' => false,
            'error' => $message,
        ), JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    }
}
