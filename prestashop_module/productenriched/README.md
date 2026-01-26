# Product Enriched Module for PrestaShop

Pre-calculates and caches product enrichment data (quantity, tax, discount) to optimize mobile app API calls.

## Installation

1. **Upload Module**
   - Copy the entire `productenriched` folder to `/modules/` directory on your PrestaShop server
   - The path should be: `/modules/productenriched/`

2. **Install via Back Office**
   - Go to **Modules > Module Manager**
   - Search for "Product Enriched"
   - Click **Install**

3. **Initial Sync (No Cron Required)**
   - Go to module configuration page
   - Select a category to test (optional) or sync all
   - Click **"Start Sync"** - progress is shown in real-time
   - For 80k products, use batch size 500 (recommended)

4. **Optional: Cron Job for Incremental Updates**
   If you prefer automatic background sync:
   ```bash
   */10 * * * * php /var/www/html/modules/productenriched/cron/sync.php
   ```

## API Endpoints

Base URL: `https://www.alkirtas.com/module/productenriched/api`

### Get Products by IDs
```
GET ?action=getByIds&ids=1|2|3|4|5&ws_key=YOUR_API_KEY
```

### Get Products by Category
```
GET ?action=getByCategory&category=123&limit=20&offset=0&ws_key=YOUR_API_KEY
```

### Get Product by Reference
```
GET ?action=getByReference&reference=ABC123&ws_key=YOUR_API_KEY
```

### Get Product by EAN13 (Barcode)
```
GET ?action=getByEan13&ean13=1234567890123&ws_key=YOUR_API_KEY
```

### Get Sync Statistics
```
GET ?action=getStats&ws_key=YOUR_API_KEY
```

## Batch Sync API Endpoints (No Cron Required)

### Run Batch Sync
Call repeatedly until `status` is `complete`:
```
GET ?action=batchSync&batch_size=500&ws_key=YOUR_API_KEY
GET ?action=batchSync&batch_size=500&category=123&ws_key=YOUR_API_KEY  # Specific category
```

Response:
```json
{
  "success": true,
  "data": {
    "status": "in_progress",  // or "complete"
    "total": 80000,
    "processed": 5000,
    "remaining": 75000,
    "percentage": 6.3,
    "batch_synced": 500,
    "message": "Synced 500 products. Progress: 6.3%"
  }
}
```

### Check Sync Progress
```
GET ?action=syncProgress&ws_key=YOUR_API_KEY
GET ?action=syncProgress&category=123&ws_key=YOUR_API_KEY
```

### Reset Sync Progress
```
GET ?action=resetSync&ws_key=YOUR_API_KEY
GET ?action=resetSync&category=123&ws_key=YOUR_API_KEY
```

### Get Categories List
```
GET ?action=getCategories&ws_key=YOUR_API_KEY
```

### Sync Single Product
```
GET ?action=syncProduct&id=12345&ws_key=YOUR_API_KEY
```

## Response Format

### Success Response
```json
{
  "success": true,
  "data": {
    "products": [
      {
        "id_product": "123",
        "quantity": 50,
        "price_ht": "100.000000",
        "price_ttc": "120.000000",
        "tax_rate": "20.00",
        "has_discount": 1,
        "discount_type": "percentage",
        "discount_value": "10.000000",
        "final_price_ttc": "108.000000",
        "is_active": 1,
        "reference": "ABC123",
        "ean13": "1234567890123",
        "manufacturer_name": "Brand Name"
      }
    ],
    "count": 1
  }
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message here"
}
```

## Database Table

The module creates a table `ps_product_enriched` with these fields:

| Field | Type | Description |
|-------|------|-------------|
| id_product | INT | Product ID |
| id_product_attribute | INT | Variant ID (0 for main product) |
| quantity | INT | Stock quantity |
| price_ht | DECIMAL | Price without tax |
| price_ttc | DECIMAL | Price with tax |
| tax_rate | DECIMAL | Tax percentage |
| has_discount | TINYINT | 1 if discount active |
| discount_type | VARCHAR | "percentage" or "amount" |
| discount_value | DECIMAL | Discount value |
| final_price_ttc | DECIMAL | Final price after discount + tax |
| is_active | TINYINT | 1 if product is active |
| reference | VARCHAR | Product reference/SKU |
| ean13 | VARCHAR | Barcode |
| manufacturer_name | VARCHAR | Brand/manufacturer name |
| updated_at | DATETIME | Last update timestamp |

## Hooks

The module automatically syncs data via these PrestaShop hooks:

- `actionProductUpdate` - Product saved
- `actionProductAdd` - New product added
- `actionProductDelete` - Product deleted
- `actionUpdateQuantity` - Stock changed
- `actionObjectSpecificPriceAddAfter` - Discount added
- `actionObjectSpecificPriceUpdateAfter` - Discount updated
- `actionObjectSpecificPriceDeleteAfter` - Discount deleted
- `actionObjectTaxRulesGroupUpdateAfter` - Tax rules changed

## Flutter App Integration

After installing this module, update your Flutter app to call the enriched API instead of multiple separate APIs.

See the companion documentation for Flutter implementation details.

## Troubleshooting

### Products not syncing
- Check cron job is running: `crontab -l`
- Run manual sync from module configuration
- Check PrestaShop logs for errors

### API returns 401
- Verify your webservice API key is correct and active
- Check the key has permissions in PrestaShop webservice settings

### Stale data
- The cron job handles expired discounts automatically
- For immediate sync, use the "Sync All Products" button in module config
