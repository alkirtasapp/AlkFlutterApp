<?php
/**
 * Product Enriched Manager
 *
 * Handles all business logic for syncing and managing enriched product data.
 */

class ProductEnrichedManager
{
    /**
     * Sync a single product's enriched data
     *
     * @param int $productId
     * @param int $idShop
     * @return bool
     */
    public static function syncProduct($productId, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $product = new Product($productId, false, null, $idShop);

        if (!Validate::isLoadedObject($product)) {
            return false;
        }

        // Get base product data
        $priceHT = (float)$product->price;
        $taxRulesGroupId = (int)$product->id_tax_rules_group;
        $isActive = (int)$product->active;

        // Calculate tax rate
        $taxRate = self::getTaxRate($taxRulesGroupId);

        // Calculate TTC price (with tax)
        $priceTTC = $priceHT * (1 + ($taxRate / 100));

        // Get quantity from stock
        $quantity = self::getProductQuantity($productId, 0, $idShop);

        // Get discount info
        $discountInfo = self::getProductDiscount($productId, $idShop);

        // Calculate final price with discount
        $finalPriceTTC = $priceTTC;
        if ($discountInfo['has_discount']) {
            if ($discountInfo['discount_type'] === 'percentage') {
                $finalPriceTTC = $priceTTC * (1 - ($discountInfo['discount_value'] / 100));
            } else {
                $finalPriceTTC = $priceTTC - $discountInfo['discount_value'];
            }
            $finalPriceTTC = max(0, $finalPriceTTC);
        }

        // Get manufacturer name
        $manufacturerName = null;
        if ($product->id_manufacturer > 0) {
            $manufacturer = new Manufacturer($product->id_manufacturer);
            if (Validate::isLoadedObject($manufacturer)) {
                $manufacturerName = $manufacturer->name;
            }
        }

        // Prepare data for insert/update
        $data = array(
            'id_product' => (int)$productId,
            'id_product_attribute' => 0,
            'id_shop' => (int)$idShop,
            'quantity' => (int)$quantity,
            'price_ht' => number_format($priceHT, 6, '.', ''),
            'price_ttc' => number_format($priceTTC, 6, '.', ''),
            'tax_rate' => number_format($taxRate, 2, '.', ''),
            'id_tax_rules_group' => (int)$taxRulesGroupId,
            'has_discount' => $discountInfo['has_discount'] ? 1 : 0,
            'discount_type' => $discountInfo['discount_type'],
            'discount_value' => number_format($discountInfo['discount_value'], 6, '.', ''),
            'discount_from' => $discountInfo['discount_from'],
            'discount_to' => $discountInfo['discount_to'],
            'final_price_ttc' => number_format($finalPriceTTC, 6, '.', ''),
            'is_active' => $isActive,
            'reference' => pSQL($product->reference),
            'ean13' => pSQL($product->ean13),
            'id_manufacturer' => (int)$product->id_manufacturer,
            'manufacturer_name' => pSQL($manufacturerName),
            'updated_at' => date('Y-m-d H:i:s'),
            'synced_at' => date('Y-m-d H:i:s'),
        );

        // Use INSERT ... ON DUPLICATE KEY UPDATE
        return self::upsertEnrichedData($data);
    }

    /**
     * Sync multiple products by IDs
     *
     * @param array $productIds
     * @param int $idShop
     * @return int Count of synced products
     */
    public static function syncProducts(array $productIds, $idShop = null)
    {
        $count = 0;
        foreach ($productIds as $productId) {
            if (self::syncProduct((int)$productId, $idShop)) {
                $count++;
            }
        }
        return $count;
    }

    /**
     * Sync all products
     *
     * @param int $idShop
     * @return int Count of synced products
     */
    public static function syncAllProducts($idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'SELECT id_product FROM ' . _DB_PREFIX_ . 'product_shop WHERE id_shop = ' . (int)$idShop;
        $products = Db::getInstance()->executeS($sql);

        $count = 0;
        foreach ($products as $product) {
            if (self::syncProduct((int)$product['id_product'], $idShop)) {
                $count++;
            }
        }

        Configuration::updateValue('PRODUCT_ENRICHED_LAST_SYNC', date('Y-m-d H:i:s'));
        return $count;
    }

    /**
     * Sync products by category
     *
     * @param int $categoryId
     * @param int $idShop
     * @return int Count of synced products
     */
    public static function syncProductsByCategory($categoryId, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'SELECT cp.id_product
                FROM ' . _DB_PREFIX_ . 'category_product cp
                INNER JOIN ' . _DB_PREFIX_ . 'product_shop ps ON cp.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . '
                WHERE cp.id_category = ' . (int)$categoryId;

        $products = Db::getInstance()->executeS($sql);

        $count = 0;
        foreach ($products as $product) {
            if (self::syncProduct((int)$product['id_product'], $idShop)) {
                $count++;
            }
        }

        return $count;
    }

    /**
     * Sync products by tax rules group (when tax changes)
     *
     * @param int $taxRulesGroupId
     * @return int Count of synced products
     */
    public static function syncProductsByTaxRulesGroup($taxRulesGroupId)
    {
        $sql = 'SELECT id_product FROM ' . _DB_PREFIX_ . 'product WHERE id_tax_rules_group = ' . (int)$taxRulesGroupId;
        $products = Db::getInstance()->executeS($sql);

        $count = 0;
        foreach ($products as $product) {
            if (self::syncProduct((int)$product['id_product'])) {
                $count++;
            }
        }

        return $count;
    }

    /**
     * Update only quantity for a product (faster than full sync)
     *
     * @param int $productId
     * @param int $quantity
     * @param int $idProductAttribute
     * @param int $idShop
     * @return bool
     */
    public static function updateQuantity($productId, $quantity, $idProductAttribute = 0, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'UPDATE ' . _DB_PREFIX_ . 'product_enriched
                SET quantity = ' . (int)$quantity . ',
                    updated_at = "' . date('Y-m-d H:i:s') . '"
                WHERE id_product = ' . (int)$productId . '
                AND id_product_attribute = ' . (int)$idProductAttribute . '
                AND id_shop = ' . (int)$idShop;

        $result = Db::getInstance()->execute($sql);

        // If no row was updated, do full sync (product might not exist in enriched table yet)
        if (Db::getInstance()->Affected_Rows() === 0) {
            return self::syncProduct($productId, $idShop);
        }

        return $result;
    }

    /**
     * Delete product from enriched table
     *
     * @param int $productId
     * @return bool
     */
    public static function deleteProduct($productId)
    {
        return Db::getInstance()->delete('product_enriched', 'id_product = ' . (int)$productId);
    }

    /**
     * Get enriched data for multiple products
     *
     * @param array $productIds
     * @param int $idShop
     * @param bool $activeOnly
     * @return array
     */
    public static function getEnrichedProducts(array $productIds, $idShop = null, $activeOnly = true)
    {
        if (empty($productIds)) {
            return array();
        }

        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $ids = array_map('intval', $productIds);
        $idsStr = implode(',', $ids);

        $sql = 'SELECT * FROM ' . _DB_PREFIX_ . 'product_enriched
                WHERE id_product IN (' . $idsStr . ')
                AND id_shop = ' . (int)$idShop;

        if ($activeOnly) {
            $sql .= ' AND is_active = 1';
        }

        $results = Db::getInstance()->executeS($sql);

        // Index by product ID for easy lookup
        $indexed = array();
        foreach ($results as $row) {
            $indexed[(int)$row['id_product']] = $row;
        }

        return $indexed;
    }

    /**
     * Get enriched data for products by category
     *
     * @param int $categoryId
     * @param int $limit
     * @param int $offset
     * @param int $idShop
     * @param bool $activeOnly
     * @return array
     */
    public static function getEnrichedProductsByCategory($categoryId, $limit = 20, $offset = 0, $idShop = null, $activeOnly = true)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'SELECT pe.*
                FROM ' . _DB_PREFIX_ . 'product_enriched pe
                INNER JOIN ' . _DB_PREFIX_ . 'category_product cp ON pe.id_product = cp.id_product
                WHERE cp.id_category = ' . (int)$categoryId . '
                AND pe.id_shop = ' . (int)$idShop . '
                AND pe.id_product_attribute = 0';

        if ($activeOnly) {
            $sql .= ' AND pe.is_active = 1';
        }

        $sql .= ' ORDER BY pe.id_product DESC';
        $sql .= ' LIMIT ' . (int)$offset . ', ' . (int)$limit;

        return Db::getInstance()->executeS($sql);
    }

    /**
     * Search product by reference
     *
     * @param string $reference
     * @param int $idShop
     * @return array|null
     */
    public static function getEnrichedProductByReference($reference, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'SELECT * FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE `reference` = "' . pSQL($reference) . '" AND `id_shop` = ' . (int)$idShop . ' AND `id_product_attribute` = 0';

        $results = Db::getInstance()->executeS($sql);
        return !empty($results) ? $results[0] : null;
    }

    /**
     * Search product by EAN13 (barcode)
     *
     * @param string $ean13
     * @param int $idShop
     * @return array|null
     */
    public static function getEnrichedProductByEan13($ean13, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'SELECT * FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE `ean13` = "' . pSQL($ean13) . '" AND `id_shop` = ' . (int)$idShop . ' AND `id_product_attribute` = 0';

        $results = Db::getInstance()->executeS($sql);
        return !empty($results) ? $results[0] : null;
    }

    /**
     * Get module statistics
     *
     * @return array
     */
    public static function getStats()
    {
        $idShop = (int)Context::getContext()->shop->id;

        // Total ACTIVE products in shop (only count what needs to be synced)
        $totalProducts = (int)Db::getInstance()->getValue(
            'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` WHERE id_shop = ' . $idShop . ' AND active = 1'
        );

        // Synced products (count active synced products)
        $syncedProducts = (int)Db::getInstance()->getValue(
            'SELECT COUNT(DISTINCT id_product) FROM `' . _DB_PREFIX_ . 'product_enriched` WHERE id_shop = ' . $idShop . ' AND is_active = 1'
        );

        // Last sync time
        $lastSync = Configuration::get('PRODUCT_ENRICHED_LAST_SYNC');

        return array(
            'total_products' => $totalProducts,
            'synced_products' => $syncedProducts,
            'pending_sync' => max(0, $totalProducts - $syncedProducts),
            'last_sync' => $lastSync ? $lastSync : 'Never',
        );
    }

    /**
     * Sync products that were modified since last sync (for cron)
     *
     * @param int $idShop
     * @return int Count of synced products
     */
    public static function syncModifiedProducts($idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $lastSync = Configuration::get('PRODUCT_ENRICHED_LAST_SYNC');
        if (!$lastSync) {
            $lastSync = '2000-01-01 00:00:00';
        }

        // Get products modified since last sync
        $sql = 'SELECT DISTINCT p.id_product
                FROM ' . _DB_PREFIX_ . 'product p
                INNER JOIN ' . _DB_PREFIX_ . 'product_shop ps ON p.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . '
                WHERE p.date_upd > "' . pSQL($lastSync) . '"';

        $modifiedProducts = Db::getInstance()->executeS($sql);

        // Also check for specific_price changes
        $sql = 'SELECT DISTINCT sp.id_product
                FROM ' . _DB_PREFIX_ . 'specific_price sp
                WHERE sp.date_upd > "' . pSQL($lastSync) . '" OR sp.date_add > "' . pSQL($lastSync) . '"';

        $priceChangedProducts = Db::getInstance()->executeS($sql);

        // Merge product IDs
        $productIds = array();
        foreach ($modifiedProducts as $p) {
            $productIds[$p['id_product']] = true;
        }
        foreach ($priceChangedProducts as $p) {
            $productIds[$p['id_product']] = true;
        }

        $count = 0;
        foreach (array_keys($productIds) as $productId) {
            if (self::syncProduct((int)$productId, $idShop)) {
                $count++;
            }
        }

        // Also sync products with expired discounts
        $count += self::syncExpiredDiscounts($idShop);

        Configuration::updateValue('PRODUCT_ENRICHED_LAST_SYNC', date('Y-m-d H:i:s'));
        return $count;
    }

    /**
     * Sync products whose discounts have expired
     *
     * @param int $idShop
     * @return int Count of synced products
     */
    public static function syncExpiredDiscounts($idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $now = date('Y-m-d H:i:s');

        // Find products with has_discount=1 but discount_to has passed
        $sql = 'SELECT id_product FROM ' . _DB_PREFIX_ . 'product_enriched
                WHERE has_discount = 1
                AND discount_to IS NOT NULL
                AND discount_to < "' . $now . '"
                AND id_shop = ' . (int)$idShop;

        $products = Db::getInstance()->executeS($sql);

        $count = 0;
        foreach ($products as $p) {
            if (self::syncProduct((int)$p['id_product'], $idShop)) {
                $count++;
            }
        }

        return $count;
    }

    /**
     * Get tax rate for a tax rules group
     *
     * @param int $taxRulesGroupId
     * @return float
     */
    private static function getTaxRate($taxRulesGroupId)
    {
        if ($taxRulesGroupId == 0) {
            return 0.0;
        }

        try {
            // Get default country for tax calculation
            $idCountry = (int)Configuration::get('PS_COUNTRY_DEFAULT');
            if ($idCountry === 0) {
                $idCountry = 8; // France as default fallback
            }

            // Single line SQL to avoid multiline parsing issues
            $sql = 'SELECT t.rate FROM `' . _DB_PREFIX_ . 'tax_rule` tr INNER JOIN `' . _DB_PREFIX_ . 'tax` t ON tr.id_tax = t.id_tax WHERE tr.id_tax_rules_group = ' . (int)$taxRulesGroupId . ' AND tr.id_country = ' . (int)$idCountry;

            $results = Db::getInstance()->executeS($sql);

            if (!empty($results) && isset($results[0]['rate'])) {
                return (float)$results[0]['rate'];
            }

            return 0.0;
        } catch (Exception $e) {
            return 0.0;
        }
    }

    /**
     * Get product quantity from stock
     *
     * @param int $productId
     * @param int $idProductAttribute
     * @param int $idShop
     * @return int
     */
    private static function getProductQuantity($productId, $idProductAttribute = 0, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $sql = 'SELECT quantity FROM ' . _DB_PREFIX_ . 'stock_available
                WHERE id_product = ' . (int)$productId . '
                AND id_product_attribute = ' . (int)$idProductAttribute . '
                AND id_shop = ' . (int)$idShop;

        $quantity = Db::getInstance()->getValue($sql);

        return $quantity !== false ? (int)$quantity : 0;
    }

    /**
     * Get active discount for a product
     *
     * @param int $productId
     * @param int $idShop
     * @return array
     */
    private static function getProductDiscount($productId, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $now = date('Y-m-d H:i:s');

        try {
            // Priority order:
            // 1. Specific prices (id_specific_price_rule = 0) before catalog rules (id_specific_price_rule > 0)
            // 2. Then by highest reduction
            $sql = 'SELECT * FROM `' . _DB_PREFIX_ . 'specific_price` WHERE `id_product` = ' . (int)$productId . ' AND (`id_shop` = ' . (int)$idShop . ' OR `id_shop` = 0) AND (`id_group` = 0) AND (`id_customer` = 0) AND (`id_country` = 0) AND (`id_currency` = 0) AND ((`from` = "0000-00-00 00:00:00" AND `to` = "0000-00-00 00:00:00") OR (`from` <= "' . pSQL($now) . '" AND `to` >= "' . pSQL($now) . '") OR (`from` <= "' . pSQL($now) . '" AND `to` = "0000-00-00 00:00:00") OR (`from` = "0000-00-00 00:00:00" AND `to` >= "' . pSQL($now) . '")) ORDER BY `id_specific_price_rule` ASC, `reduction` DESC, `id_specific_price` ASC';

            $results = Db::getInstance()->executeS($sql);
            $discount = !empty($results) ? $results[0] : null;
        } catch (Exception $e) {
            $discount = null;
        }

        if (!$discount) {
            return array(
                'has_discount' => false,
                'discount_type' => null,
                'discount_value' => 0,
                'discount_from' => null,
                'discount_to' => null,
            );
        }

        $reduction = (float)$discount['reduction'];
        $reductionType = $discount['reduction_type'];

        // Convert to percentage if needed
        if ($reductionType === 'percentage') {
            $discountValue = $reduction * 100; // Store as percentage (e.g., 10 for 10%)
        } else {
            $discountValue = $reduction;
        }

        $fromDate = ($discount['from'] !== '0000-00-00 00:00:00') ? $discount['from'] : null;
        $toDate = ($discount['to'] !== '0000-00-00 00:00:00') ? $discount['to'] : null;

        return array(
            'has_discount' => true,
            'discount_type' => $reductionType,
            'discount_value' => $discountValue,
            'discount_from' => $fromDate,
            'discount_to' => $toDate,
        );
    }

    /**
     * Insert or update enriched data
     *
     * @param array $data
     * @return bool
     */
    private static function upsertEnrichedData(array $data)
    {
        $columns = array();
        $values = array();
        $updates = array();

        foreach ($data as $column => $value) {
            $columns[] = '`' . $column . '`';
            if ($value === null) {
                $values[] = 'NULL';
                $updates[] = '`' . $column . '` = NULL';
            } else {
                $values[] = '"' . pSQL($value) . '"';
                $updates[] = '`' . $column . '` = "' . pSQL($value) . '"';
            }
        }

        $sql = 'INSERT INTO ' . _DB_PREFIX_ . 'product_enriched (' . implode(', ', $columns) . ')
                VALUES (' . implode(', ', $values) . ')
                ON DUPLICATE KEY UPDATE ' . implode(', ', $updates);

        return Db::getInstance()->execute($sql);
    }

    // =========================================================================
    // BATCH SYNC METHODS (No Cron Required)
    // =========================================================================

    /**
     * Batch sync products with progress tracking
     * Call this repeatedly via API until complete
     *
     * @param int $batchSize Number of products per batch
     * @param int|null $categoryId Optional category filter
     * @param int $idShop
     * @return array Progress info
     */
    public static function batchSync($batchSize = 500, $categoryId = null, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $progressKey = $categoryId ? "PRODUCT_ENRICHED_PROGRESS_CAT_{$categoryId}" : 'PRODUCT_ENRICHED_PROGRESS_ALL';

        // Get current offset from progress
        $currentOffset = (int)Configuration::get($progressKey);

        // Get total ACTIVE products count only (skip inactive products for faster sync)
        if ($categoryId) {
            $totalSql = 'SELECT COUNT(DISTINCT cp.id_product) FROM `' . _DB_PREFIX_ . 'category_product` cp INNER JOIN `' . _DB_PREFIX_ . 'product_shop` ps ON cp.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . ' AND ps.active = 1 WHERE cp.id_category = ' . (int)$categoryId;
        } else {
            $totalSql = 'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` WHERE id_shop = ' . (int)$idShop . ' AND active = 1';
        }
        $totalProducts = (int)Db::getInstance()->getValue($totalSql);

        // Check if already complete
        if ($currentOffset >= $totalProducts) {
            return array(
                'status' => 'complete',
                'total' => $totalProducts,
                'processed' => $totalProducts,
                'remaining' => 0,
                'percentage' => 100,
                'batch_synced' => 0,
                'message' => 'Sync complete!',
            );
        }

        // Get batch of ACTIVE product IDs only
        if ($categoryId) {
            $sql = 'SELECT DISTINCT cp.id_product FROM `' . _DB_PREFIX_ . 'category_product` cp INNER JOIN `' . _DB_PREFIX_ . 'product_shop` ps ON cp.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . ' AND ps.active = 1 WHERE cp.id_category = ' . (int)$categoryId . ' ORDER BY cp.id_product ASC LIMIT ' . (int)$currentOffset . ', ' . (int)$batchSize;
        } else {
            $sql = 'SELECT id_product FROM `' . _DB_PREFIX_ . 'product_shop` WHERE id_shop = ' . (int)$idShop . ' AND active = 1 ORDER BY id_product ASC LIMIT ' . (int)$currentOffset . ', ' . (int)$batchSize;
        }

        $products = Db::getInstance()->executeS($sql);

        // Sync this batch
        $syncedCount = 0;
        foreach ($products as $product) {
            if (self::syncProduct((int)$product['id_product'], $idShop)) {
                $syncedCount++;
            }
        }

        // Update progress
        $newOffset = $currentOffset + count($products);
        Configuration::updateValue($progressKey, $newOffset);

        // Calculate percentage
        $percentage = $totalProducts > 0 ? round(($newOffset / $totalProducts) * 100, 1) : 100;

        // Check if complete after this batch
        $isComplete = $newOffset >= $totalProducts;
        if ($isComplete) {
            Configuration::updateValue('PRODUCT_ENRICHED_LAST_SYNC', date('Y-m-d H:i:s'));
        }

        return array(
            'status' => $isComplete ? 'complete' : 'in_progress',
            'total' => $totalProducts,
            'processed' => $newOffset,
            'remaining' => max(0, $totalProducts - $newOffset),
            'percentage' => $percentage,
            'batch_synced' => $syncedCount,
            'batch_size' => $batchSize,
            'category_id' => $categoryId,
            'message' => $isComplete
                ? 'Sync complete!'
                : "Synced {$syncedCount} products. Progress: {$percentage}%",
        );
    }

    /**
     * Reset batch sync progress
     *
     * @param int|null $categoryId Optional category filter
     * @return bool
     */
    public static function resetBatchProgress($categoryId = null)
    {
        $progressKey = $categoryId ? "PRODUCT_ENRICHED_PROGRESS_CAT_{$categoryId}" : 'PRODUCT_ENRICHED_PROGRESS_ALL';
        return Configuration::deleteByName($progressKey);
    }

    /**
     * Get current batch sync progress
     *
     * @param int|null $categoryId Optional category filter
     * @param int $idShop
     * @return array
     */
    public static function getBatchProgress($categoryId = null, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        $progressKey = $categoryId ? "PRODUCT_ENRICHED_PROGRESS_CAT_{$categoryId}" : 'PRODUCT_ENRICHED_PROGRESS_ALL';
        $currentOffset = (int)Configuration::get($progressKey);

        // Get total ACTIVE products count only
        if ($categoryId) {
            $totalSql = 'SELECT COUNT(DISTINCT cp.id_product) FROM `' . _DB_PREFIX_ . 'category_product` cp INNER JOIN `' . _DB_PREFIX_ . 'product_shop` ps ON cp.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . ' AND ps.active = 1 WHERE cp.id_category = ' . (int)$categoryId;
        } else {
            $totalSql = 'SELECT COUNT(*) FROM `' . _DB_PREFIX_ . 'product_shop` WHERE id_shop = ' . (int)$idShop . ' AND active = 1';
        }
        $totalProducts = (int)Db::getInstance()->getValue($totalSql);

        $percentage = $totalProducts > 0 ? round(($currentOffset / $totalProducts) * 100, 1) : 0;
        $isComplete = $currentOffset >= $totalProducts && $totalProducts > 0;

        return array(
            'status' => $isComplete ? 'complete' : ($currentOffset > 0 ? 'in_progress' : 'not_started'),
            'total' => $totalProducts,
            'processed' => min($currentOffset, $totalProducts),
            'remaining' => max(0, $totalProducts - $currentOffset),
            'percentage' => $isComplete ? 100 : $percentage,
            'category_id' => $categoryId,
            'last_sync' => Configuration::get('PRODUCT_ENRICHED_LAST_SYNC'),
        );
    }

    /**
     * Get count of products in a category
     *
     * @param int $categoryId
     * @param int $idShop
     * @return int
     */
    public static function getCategoryProductCount($categoryId, $idShop = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }

        // Count only ACTIVE products
        $sql = 'SELECT COUNT(DISTINCT cp.id_product) FROM `' . _DB_PREFIX_ . 'category_product` cp INNER JOIN `' . _DB_PREFIX_ . 'product_shop` ps ON cp.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . ' AND ps.active = 1 WHERE cp.id_category = ' . (int)$categoryId;

        return (int)Db::getInstance()->getValue($sql);
    }

    /**
     * Get list of categories with product counts
     *
     * @param int $idShop
     * @param int $idLang
     * @return array
     */
    public static function getCategoriesWithCounts($idShop = null, $idLang = null)
    {
        if ($idShop === null) {
            $idShop = (int)Context::getContext()->shop->id;
        }
        if ($idLang === null) {
            $idLang = (int)Context::getContext()->language->id;
        }

        // Count only ACTIVE products per category
        $sql = 'SELECT c.id_category, cl.name, COUNT(DISTINCT cp.id_product) as product_count FROM `' . _DB_PREFIX_ . 'category` c INNER JOIN `' . _DB_PREFIX_ . 'category_lang` cl ON c.id_category = cl.id_category AND cl.id_lang = ' . (int)$idLang . ' INNER JOIN `' . _DB_PREFIX_ . 'category_shop` cs ON c.id_category = cs.id_category AND cs.id_shop = ' . (int)$idShop . ' LEFT JOIN `' . _DB_PREFIX_ . 'category_product` cp ON c.id_category = cp.id_category LEFT JOIN `' . _DB_PREFIX_ . 'product_shop` ps ON cp.id_product = ps.id_product AND ps.id_shop = ' . (int)$idShop . ' AND ps.active = 1 WHERE c.active = 1 GROUP BY c.id_category HAVING product_count > 0 ORDER BY cl.name ASC';

        return Db::getInstance()->executeS($sql);
    }
}
