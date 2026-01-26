<?php
/**
 * Product Enriched Module
 *
 * Pre-calculates and caches product enrichment data (quantity, tax, discount)
 * to reduce API calls from mobile app.
 *
 * @author Alkirtas
 * @version 1.0.0
 */

if (!defined('_PS_VERSION_')) {
    exit;
}

require_once dirname(__FILE__) . '/classes/ProductEnrichedManager.php';

class ProductEnriched extends Module
{
    public function __construct()
    {
        $this->name = 'productenriched';
        $this->tab = 'administration';
        $this->version = '1.0.0';
        $this->author = 'Alkirtas';
        $this->need_instance = 0;
        $this->bootstrap = true;

        parent::__construct();

        $this->displayName = $this->l('Product Enriched Data');
        $this->description = $this->l('Pre-calculates product data (quantity, tax, discount) for mobile app API optimization.');
        $this->ps_versions_compliancy = array('min' => '1.7.0.0', 'max' => _PS_VERSION_);
    }

    /**
     * Module installation
     */
    public function install()
    {
        return parent::install()
            && $this->installDb()
            && $this->registerHook('actionProductUpdate')
            && $this->registerHook('actionProductAdd')
            && $this->registerHook('actionProductDelete')
            && $this->registerHook('actionUpdateQuantity')
            && $this->registerHook('actionObjectSpecificPriceAddAfter')
            && $this->registerHook('actionObjectSpecificPriceUpdateAfter')
            && $this->registerHook('actionObjectSpecificPriceDeleteAfter')
            && $this->registerHook('actionObjectTaxRulesGroupUpdateAfter');
    }

    /**
     * Module uninstallation
     */
    public function uninstall()
    {
        return parent::uninstall() && $this->uninstallDb();
    }

    /**
     * Install database table
     */
    private function installDb()
    {
        $sql = file_get_contents(dirname(__FILE__) . '/sql/install.sql');
        $sql = str_replace('PREFIX_', _DB_PREFIX_, $sql);
        return Db::getInstance()->execute($sql);
    }

    /**
     * Uninstall database table
     */
    private function uninstallDb()
    {
        $sql = file_get_contents(dirname(__FILE__) . '/sql/uninstall.sql');
        $sql = str_replace('PREFIX_', _DB_PREFIX_, $sql);
        return Db::getInstance()->execute($sql);
    }

    /**
     * Hook: Product updated
     */
    public function hookActionProductUpdate($params)
    {
        if (isset($params['id_product'])) {
            ProductEnrichedManager::syncProduct((int)$params['id_product']);
        }
    }

    /**
     * Hook: Product added
     */
    public function hookActionProductAdd($params)
    {
        if (isset($params['id_product'])) {
            ProductEnrichedManager::syncProduct((int)$params['id_product']);
        }
    }

    /**
     * Hook: Product deleted
     */
    public function hookActionProductDelete($params)
    {
        if (isset($params['id_product'])) {
            ProductEnrichedManager::deleteProduct((int)$params['id_product']);
        }
    }

    /**
     * Hook: Stock quantity updated
     */
    public function hookActionUpdateQuantity($params)
    {
        if (isset($params['id_product'])) {
            $productId = (int)$params['id_product'];
            $quantity = isset($params['quantity']) ? (int)$params['quantity'] : null;

            if ($quantity !== null) {
                ProductEnrichedManager::updateQuantity($productId, $quantity);
            } else {
                ProductEnrichedManager::syncProduct($productId);
            }
        }
    }

    /**
     * Hook: Specific price (discount) added
     */
    public function hookActionObjectSpecificPriceAddAfter($params)
    {
        $this->handleSpecificPriceChange($params);
    }

    /**
     * Hook: Specific price (discount) updated
     */
    public function hookActionObjectSpecificPriceUpdateAfter($params)
    {
        $this->handleSpecificPriceChange($params);
    }

    /**
     * Hook: Specific price (discount) deleted
     */
    public function hookActionObjectSpecificPriceDeleteAfter($params)
    {
        $this->handleSpecificPriceChange($params);
    }

    /**
     * Handle specific price changes
     */
    private function handleSpecificPriceChange($params)
    {
        if (isset($params['object']) && $params['object'] instanceof SpecificPrice) {
            $productId = (int)$params['object']->id_product;
            if ($productId > 0) {
                ProductEnrichedManager::syncProduct($productId);
            }
        }
    }

    /**
     * Hook: Tax rules group updated
     */
    public function hookActionObjectTaxRulesGroupUpdateAfter($params)
    {
        if (isset($params['object']) && $params['object'] instanceof TaxRulesGroup) {
            $taxRulesGroupId = (int)$params['object']->id;
            ProductEnrichedManager::syncProductsByTaxRulesGroup($taxRulesGroupId);
        }
    }

    /**
     * Module configuration page
     */
    public function getContent()
    {
        $output = '';

        // Get stats
        $stats = ProductEnrichedManager::getStats();

        // Get categories for dropdown
        $categories = ProductEnrichedManager::getCategoriesWithCounts();

        // Get API URL base
        $apiUrl = $this->context->link->getModuleLink($this->name, 'api');

        // Get a webservice key for API calls
        $wsKey = $this->getFirstActiveWsKey();

        $output .= '
        <style>
            .sync-progress { margin: 20px 0; }
            .sync-progress .progress { height: 30px; margin-bottom: 10px; }
            .sync-progress .progress-bar { line-height: 30px; font-size: 14px; }
            .sync-log { max-height: 200px; overflow-y: auto; background: #f5f5f5; padding: 10px; border-radius: 4px; font-family: monospace; font-size: 12px; }
            .sync-log .log-entry { margin: 2px 0; }
            .sync-log .log-success { color: green; }
            .sync-log .log-info { color: blue; }
            .sync-log .log-error { color: red; }
        </style>

        <div class="panel">
            <h3><i class="icon-info-circle"></i> ' . $this->l('Product Enriched Data Status') . '</h3>
            <div class="row">
                <div class="col-md-3">
                    <div class="alert alert-info">
                        <strong id="stat-total">' . $stats['total_products'] . '</strong><br>' . $this->l('Total Products') . '
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="alert alert-success">
                        <strong id="stat-synced">' . $stats['synced_products'] . '</strong><br>' . $this->l('Synced Products') . '
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="alert alert-warning">
                        <strong id="stat-pending">' . $stats['pending_sync'] . '</strong><br>' . $this->l('Pending Sync') . '
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="alert alert-info">
                        <strong id="stat-last">' . $stats['last_sync'] . '</strong><br>' . $this->l('Last Sync') . '
                    </div>
                </div>
            </div>
        </div>

        <div class="panel">
            <h3><i class="icon-refresh"></i> ' . $this->l('Batch Sync (No Cron Required)') . '</h3>
            <p class="help-block">' . $this->l('Sync products in batches. For 80k+ products, this may take a while. You can test with a specific category first.') . '</p>

            <div class="row">
                <div class="col-md-6">
                    <div class="form-group">
                        <label>' . $this->l('Category (Optional - leave empty for all)') . '</label>
                        <select id="sync-category" class="form-control">
                            <option value="">' . $this->l('-- All Products --') . '</option>';

        foreach ($categories as $cat) {
            $output .= '<option value="' . $cat['id_category'] . '">' . htmlspecialchars($cat['name']) . ' (' . $cat['product_count'] . ' products)</option>';
        }

        $output .= '
                        </select>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="form-group">
                        <label>' . $this->l('Batch Size') . '</label>
                        <select id="sync-batch-size" class="form-control">
                            <option value="100">100 (Slower, safer)</option>
                            <option value="250">250</option>
                            <option value="500" selected>500 (Recommended)</option>
                            <option value="750">750</option>
                            <option value="1000">1000 (Faster)</option>
                        </select>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="form-group">
                        <label>&nbsp;</label>
                        <div>
                            <button type="button" id="btn-start-sync" class="btn btn-primary">
                                <i class="icon-play"></i> ' . $this->l('Start Sync') . '
                            </button>
                            <button type="button" id="btn-stop-sync" class="btn btn-danger" style="display:none;">
                                <i class="icon-stop"></i> ' . $this->l('Stop') . '
                            </button>
                        </div>
                    </div>
                </div>
            </div>

            <div class="sync-progress" style="display:none;">
                <div class="progress">
                    <div id="sync-progress-bar" class="progress-bar progress-bar-striped active" role="progressbar" style="width: 0%;">
                        0%
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-4"><strong>' . $this->l('Processed:') . '</strong> <span id="sync-processed">0</span> / <span id="sync-total">0</span></div>
                    <div class="col-md-4"><strong>' . $this->l('Remaining:') . '</strong> <span id="sync-remaining">0</span></div>
                    <div class="col-md-4"><strong>' . $this->l('Status:') . '</strong> <span id="sync-status">-</span></div>
                </div>
            </div>

            <div id="sync-log" class="sync-log" style="display:none;"></div>

            <hr>
            <button type="button" id="btn-reset-progress" class="btn btn-warning btn-sm">
                <i class="icon-refresh"></i> ' . $this->l('Reset Progress') . '
            </button>
            <button type="button" id="btn-refresh-stats" class="btn btn-default btn-sm">
                <i class="icon-refresh"></i> ' . $this->l('Refresh Stats') . '
            </button>
        </div>

        <div class="panel">
            <h3><i class="icon-link"></i> ' . $this->l('API Endpoints') . '</h3>
            <p>' . $this->l('Use these endpoints from your mobile app:') . '</p>
            <table class="table table-bordered">
                <tr>
                    <th>Action</th>
                    <th>URL</th>
                </tr>
                <tr>
                    <td>Get by IDs</td>
                    <td><code>' . $apiUrl . '?action=getByIds&ids=1|2|3&ws_key=YOUR_KEY</code></td>
                </tr>
                <tr>
                    <td>Get by Category</td>
                    <td><code>' . $apiUrl . '?action=getByCategory&category=123&limit=20&offset=0&ws_key=YOUR_KEY</code></td>
                </tr>
                <tr>
                    <td>Get by Reference</td>
                    <td><code>' . $apiUrl . '?action=getByReference&reference=ABC&ws_key=YOUR_KEY</code></td>
                </tr>
                <tr>
                    <td>Get by Barcode</td>
                    <td><code>' . $apiUrl . '?action=getByEan13&ean13=123456789&ws_key=YOUR_KEY</code></td>
                </tr>
            </table>
        </div>

        <script>
        (function() {
            var apiUrl = "' . $apiUrl . '";
            var wsKey = "' . $wsKey . '";
            var syncRunning = false;
            var syncStopped = false;

            function log(message, type) {
                var logDiv = document.getElementById("sync-log");
                logDiv.style.display = "block";
                var entry = document.createElement("div");
                entry.className = "log-entry log-" + (type || "info");
                entry.textContent = "[" + new Date().toLocaleTimeString() + "] " + message;
                logDiv.appendChild(entry);
                logDiv.scrollTop = logDiv.scrollHeight;
            }

            function updateProgress(data) {
                document.getElementById("sync-progress-bar").style.width = data.percentage + "%";
                document.getElementById("sync-progress-bar").textContent = data.percentage + "%";
                document.getElementById("sync-processed").textContent = data.processed;
                document.getElementById("sync-total").textContent = data.total;
                document.getElementById("sync-remaining").textContent = data.remaining;
                document.getElementById("sync-status").textContent = data.status;

                if (data.status === "complete") {
                    document.getElementById("sync-progress-bar").className = "progress-bar progress-bar-success";
                }
            }

            function refreshStats() {
                fetch(apiUrl + "?action=getStats&ws_key=" + wsKey)
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            document.getElementById("stat-total").textContent = data.data.stats.total_products;
                            document.getElementById("stat-synced").textContent = data.data.stats.synced_products;
                            document.getElementById("stat-pending").textContent = data.data.stats.pending_sync;
                            document.getElementById("stat-last").textContent = data.data.stats.last_sync;
                        }
                    });
            }

            function runBatchSync() {
                if (syncStopped) {
                    log("Sync stopped by user", "info");
                    syncRunning = false;
                    document.getElementById("btn-start-sync").style.display = "";
                    document.getElementById("btn-stop-sync").style.display = "none";
                    return;
                }

                var category = document.getElementById("sync-category").value;
                var batchSize = document.getElementById("sync-batch-size").value;

                var url = apiUrl + "?action=batchSync&batch_size=" + batchSize + "&ws_key=" + wsKey;
                if (category) {
                    url += "&category=" + category;
                }

                fetch(url)
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            updateProgress(data.data);
                            log(data.data.message, data.data.status === "complete" ? "success" : "info");

                            if (data.data.status === "complete") {
                                syncRunning = false;
                                document.getElementById("btn-start-sync").style.display = "";
                                document.getElementById("btn-stop-sync").style.display = "none";
                                refreshStats();
                            } else {
                                // Continue with next batch
                                setTimeout(runBatchSync, 500);
                            }
                        } else {
                            log("Error: " + data.error, "error");
                            syncRunning = false;
                        }
                    })
                    .catch(err => {
                        log("Network error: " + err.message, "error");
                        syncRunning = false;
                    });
            }

            document.getElementById("btn-start-sync").addEventListener("click", function() {
                if (syncRunning) return;

                syncRunning = true;
                syncStopped = false;
                document.getElementById("sync-log").innerHTML = "";
                document.querySelector(".sync-progress").style.display = "block";
                document.getElementById("sync-progress-bar").className = "progress-bar progress-bar-striped active";
                this.style.display = "none";
                document.getElementById("btn-stop-sync").style.display = "";

                log("Starting batch sync...", "info");
                runBatchSync();
            });

            document.getElementById("btn-stop-sync").addEventListener("click", function() {
                syncStopped = true;
                log("Stopping sync...", "info");
            });

            document.getElementById("btn-reset-progress").addEventListener("click", function() {
                var category = document.getElementById("sync-category").value;
                var url = apiUrl + "?action=resetSync&ws_key=" + wsKey;
                if (category) {
                    url += "&category=" + category;
                }

                fetch(url)
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            log("Progress reset", "success");
                            document.getElementById("sync-progress-bar").style.width = "0%";
                            document.getElementById("sync-progress-bar").textContent = "0%";
                            document.getElementById("sync-processed").textContent = "0";
                            document.getElementById("sync-remaining").textContent = "0";
                        }
                    });
            });

            document.getElementById("btn-refresh-stats").addEventListener("click", refreshStats);
        })();
        </script>';

        return $output;
    }

    /**
     * Get webservice key for API calls
     */
    private function getFirstActiveWsKey()
    {
        return 'Y262WZ22UPBRMJ6UNTHU24KDXT7T66RU';
    }
}
