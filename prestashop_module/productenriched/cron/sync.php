<?php
/**
 * Product Enriched Cron Sync Script
 *
 * Run this script every 10 minutes to sync modified products:
 * */10 * * * * php /var/www/html/modules/productenriched/cron/sync.php
 *
 * Options:
 *   --all     : Sync all products (initial sync)
 *   --force   : Force sync even if recently synced
 *   --debug   : Show detailed output
 */

// Get PrestaShop root directory (3 levels up from cron folder)
$psRoot = dirname(dirname(dirname(dirname(dirname(__FILE__)))));

// Check if we're in the correct location
if (!file_exists($psRoot . '/config/config.inc.php')) {
    die("Error: Cannot find PrestaShop config. Make sure the module is in the correct location.\n");
}

// Load PrestaShop
require_once $psRoot . '/config/config.inc.php';
require_once $psRoot . '/init.php';
require_once dirname(dirname(__FILE__)) . '/classes/ProductEnrichedManager.php';

// Parse command line arguments
$syncAll = in_array('--all', $argv ?? array());
$force = in_array('--force', $argv ?? array());
$debug = in_array('--debug', $argv ?? array());

// Check if we should skip (recently synced)
$lastSync = Configuration::get('PRODUCT_ENRICHED_LAST_SYNC');
if (!$force && $lastSync) {
    $lastSyncTime = strtotime($lastSync);
    $minInterval = 5 * 60; // 5 minutes minimum between syncs

    if ((time() - $lastSyncTime) < $minInterval) {
        if ($debug) {
            echo "Skipping: Last sync was " . (time() - $lastSyncTime) . " seconds ago (minimum: {$minInterval}s)\n";
        }
        exit(0);
    }
}

// Initialize context
$context = Context::getContext();
if (!$context->shop || !$context->shop->id) {
    $context->shop = new Shop((int)Configuration::get('PS_SHOP_DEFAULT'));
}

// Log start time
$startTime = microtime(true);
$date = date('Y-m-d H:i:s');

if ($debug) {
    echo "[$date] Starting product enriched sync...\n";
}

try {
    if ($syncAll) {
        // Full sync of all products
        if ($debug) {
            echo "Mode: Full sync (all products)\n";
        }
        $count = ProductEnrichedManager::syncAllProducts();
    } else {
        // Incremental sync (only modified products)
        if ($debug) {
            echo "Mode: Incremental sync (modified since last sync)\n";
        }
        $count = ProductEnrichedManager::syncModifiedProducts();
    }

    $duration = round(microtime(true) - $startTime, 2);

    if ($debug) {
        echo "Synced $count products in {$duration}s\n";
        echo "Last sync updated to: " . date('Y-m-d H:i:s') . "\n";
    }

    // Log to PrestaShop logger for monitoring
    PrestaShopLogger::addLog(
        "Product Enriched Sync completed: $count products in {$duration}s",
        1, // Severity: Informational
        null,
        'ProductEnriched',
        null,
        true
    );

} catch (Exception $e) {
    $errorMsg = "Product Enriched Sync Error: " . $e->getMessage();

    if ($debug) {
        echo "ERROR: $errorMsg\n";
        echo "Stack trace:\n" . $e->getTraceAsString() . "\n";
    }

    PrestaShopLogger::addLog(
        $errorMsg,
        3, // Severity: Error
        null,
        'ProductEnriched',
        null,
        true
    );

    exit(1);
}

exit(0);
