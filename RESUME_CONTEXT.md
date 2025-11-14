# Flutter Cart Sync - Resume Context

## 📋 Project Overview

This Flutter app (Alkirtas e-commerce) integrates with Odoo POS to automatically sync cart changes when a cashier verifies products. The system uses a polling mechanism where the Flutter app checks an Odoo API endpoint every 3 seconds to detect when verification is complete.

**Project Location:** `D:\flutter\test`

---

## ✅ What Has Been Implemented

### **1. Odoo POS Module (Backend)**
Location: `e:\odoo16\server\odoo\addons\pos_mobile_cart_scanner\`

#### Files Created:
- `models/verified_cart_session.py` - Database table to store verified carts temporarily
- `models/pos_config.py` - Extends POS config with cart scanner field
- `controllers/verified_cart_api.py` - API endpoints for polling
- `security/ir.model.access.csv` - Permissions

#### Files Modified:
- `static/src/js/CartVerificationPopup.js` - Saves verified cart to database with session_id
- `static/src/js/pos_cart_scanner.js` - Extracts session_id from QR and passes to popup
- `static/src/xml/pos_cart_scanner.xml` - Added inline +/- quantity controls (no popup)

#### API Endpoints Created:
- `GET /pos/api/verified_cart/<session_id>` - Flutter polls this to get verified cart
- `DELETE /pos/api/verified_cart/<session_id>` - Cleanup after sync

### **2. Flutter App (Frontend)**

#### Files Created:
- `lib/features/shop/screens/cart/cart_qr_dialog.dart` - QR dialog with automatic polling logic

#### Files Modified:
- `pubspec.yaml` - Added `uuid: ^4.5.1` package
- `lib/features/shop/screens/cart/cart.dart` - Added session_id generation and new QR dialog

#### Key Changes:
- QR data now includes unique `session_id` field
- New dialog polls Odoo every 3 seconds
- Auto-updates cart when verified data arrives
- Shows real-time sync status

---

## 🔧 Current State

### ✅ Working:
- Odoo module installed and upgraded
- API endpoints tested and responding
- Verification popup with inline +/- controls
- Database model created
- Session saving to database confirmed

### ⚠️ Needs Configuration:
- **Flutter app Odoo URL** needs to be set to local IP for testing
- Not yet tested end-to-end with Flutter polling

### 📍 URLs to Update:

1. **File:** `lib/features/shop/screens/cart/cart.dart` (line ~139)
   ```dart
   odooBaseUrl: 'http://192.168.1.100:8069', // Change to YOUR IP!
   ```

2. **File:** `lib/features/shop/screens/cart/cart_qr_dialog.dart` (line ~26)
   ```dart
   this.odooBaseUrl = 'http://192.168.1.100:8069', // Change to YOUR IP!
   ```

**How to find your local IP:**
- Windows: `ipconfig` → Look for IPv4 Address
- Mac/Linux: `ifconfig` → Look for inet

---

## 🎯 How The System Works

### Complete Flow:

```
1. User opens cart in Flutter app → Clicks QR icon
   ↓
2. Flutter generates unique session_id (UUID)
   ↓
3. Flutter adds session_id to QR data JSON
   ↓
4. Flutter shows QR dialog + starts polling Odoo API every 3 seconds
   ↓
5. Cashier scans QR in Odoo POS
   ↓
6. Odoo parses QR, extracts session_id, shows verification popup
   ↓
7. Cashier adjusts quantities using +/- buttons
   ↓
8. Cashier clicks "Add to Cart"
   ↓
9. Odoo saves verified cart to database with session_id
   ↓
10. Flutter polling detects the verified cart
    ↓
11. Flutter updates local cart automatically
    ↓
12. Flutter shows success message and closes dialog
```

---

## 📂 Key File Locations

### Flutter Files:
```
D:\flutter\test\
├── lib/
│   └── features/
│       └── shop/
│           └── screens/
│               └── cart/
│                   ├── cart.dart (main cart screen)
│                   └── cart_qr_dialog.dart (NEW: polling dialog)
├── pubspec.yaml (added uuid package)
├── CART_SYNC_SETUP.md (detailed setup guide)
└── RESUME_CONTEXT.md (this file)
```

### Odoo Files:
```
e:\odoo16\server\odoo\addons\pos_mobile_cart_scanner\
├── models/
│   ├── __init__.py
│   ├── pos_config.py
│   └── verified_cart_session.py (NEW: database table)
├── controllers/
│   ├── __init__.py
│   ├── main.py (existing cart scanner)
│   └── verified_cart_api.py (NEW: polling endpoints)
├── security/
│   └── ir.model.access.csv
└── static/src/
    ├── js/
    │   ├── CartVerificationPopup.js (saves to database)
    │   └── pos_cart_scanner.js (extracts session_id)
    └── xml/
        └── pos_cart_scanner.xml (inline qty controls)
```

---

## 🧪 Testing Steps

### Prerequisites:
1. Odoo running on localhost or accessible URL
2. Flutter app configured with correct Odoo URL
3. Test product exists in Odoo (note its reference code)

### Step-by-Step Test:

1. **Start Flutter App:**
   ```bash
   cd D:\flutter\test
   flutter run
   ```

2. **Add Product to Cart:**
   - Navigate to product
   - Add to cart

3. **Generate QR:**
   - Open cart screen
   - Click QR icon
   - You should see: "En attente de vérification..."
   - Check console logs for session_id

4. **Scan in Odoo POS:**
   - Open http://localhost:8069/pos
   - Click "Scan Cart" button
   - Copy QR JSON from Flutter console
   - Paste into Odoo popup

5. **Verify Products:**
   - Use +/- buttons to adjust quantities
   - Click "Add to Cart"

6. **Check Flutter:**
   - Should automatically show: "✓ Panier synchronisé avec succès!"
   - Cart should update with new quantities
   - Dialog should close

---

## 🔍 Debugging

### Check if Polling is Working:

**Flutter Console:**
```
📡 Polling: http://192.168.1.100:8069/pos/api/verified_cart/abc-123... (Attempt 1)
⏳ Cart not verified yet...
📡 Polling: http://192.168.1.100:8069/pos/api/verified_cart/abc-123... (Attempt 2)
✅ Cart verified! Data: {session_id: abc-123, items: [...]}
```

### Test API Directly:

**Before verification:**
```bash
curl http://localhost:8069/pos/api/verified_cart/test-123
# Should return: {"status": "not_found", "message": "Cart verification not complete yet"}
```

**After verification (in Odoo):**
```bash
curl http://localhost:8069/pos/api/verified_cart/SESSION_ID
# Should return: {session_id: ..., items: [...], total: ...}
```

### Common Issues:

1. **"Failed to process cart: Error"**
   - Check if product reference exists in Odoo
   - Verify `/pos/scan_mobile_cart` route is working

2. **Polling never finds cart**
   - Session ID mismatch - check console logs
   - Odoo didn't save to database - check Odoo logs
   - Network issue - verify Odoo URL is accessible

3. **App can't reach Odoo**
   - Firewall blocking port 8069
   - Wrong IP address
   - Odoo not running

---

## 💡 Important Code Snippets

### QR Data Structure (Flutter):
```dart
{
  "session_id": "abc-123-uuid-here",
  "cartItems": [
    {
      "productReference": "077302",
      "productPrice": "38.50",
      "productQuantity": "1",
      "productDiscount": "0"
    }
  ],
  "totalPrice": 38.50
}
```

### Polling Logic (Flutter):
```dart
Timer.periodic(Duration(seconds: 3), (timer) async {
  final url = '$odooBaseUrl/pos/api/verified_cart/$sessionId';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    // Cart verified!
    final verifiedData = jsonDecode(response.body);
    await _updateCartFromVerified(verifiedData);
    timer.cancel();
  }
});
```

### Odoo Save Logic (JavaScript):
```javascript
async _saveVerifiedCart() {
    const sessionId = this.props.sessionId;
    const verifiedCartData = {
        session_id: sessionId,
        items: this.state.products.map(p => ({
            product_reference: p.product_reference,
            verified_quantity: p.scannedCount,
            // ... more fields
        }))
    };

    await this.rpc({
        model: 'pos.verified.cart.session',
        method: 'create',
        args: [{
            name: sessionId,
            verified_cart_data: JSON.stringify(verifiedCartData)
        }]
    });
}
```

---

## 🚀 Next Steps

1. **Update Odoo URLs in Flutter** (use local IP for testing)
2. **Run Flutter app and test complete flow**
3. **Verify polling works** (check console logs)
4. **Test edge cases:**
   - Network disconnection
   - Odoo offline
   - Multiple carts simultaneously
   - Timeout after 5 minutes

---

## 📝 Configuration Checklist

- [ ] Find computer's local IP address
- [ ] Update `cart.dart` line ~139 with correct IP
- [ ] Update `cart_qr_dialog.dart` line ~26 with correct IP
- [ ] Run `flutter pub get` to ensure uuid is installed
- [ ] Test Odoo API endpoint in browser
- [ ] Run Flutter app and test QR generation
- [ ] Test complete flow with Odoo POS
- [ ] Verify cart updates automatically
- [ ] For production: Change URLs to `https://www.odoo.alkirtas.com`

---

## 🛠️ Tech Stack

- **Flutter:** v3.6.0+
- **Odoo:** v16
- **Packages Used:**
  - `uuid: ^4.5.1` - Generate unique session IDs
  - `http: ^0.13.3` - API polling
  - `provider: ^6.0.5` - Cart state management
  - `qr_flutter: ^4.1.0` - QR code generation
  - `hive: ^2.2.3` - Local storage

---

## 📞 Support Context

**Last Tested:** 2025-11-13
**Odoo Test:** ✅ Session saved successfully
**Flutter Test:** ⏳ Pending (needs IP configuration)
**API Test:** ✅ Responding correctly

**Database Record Example:**
```json
{
  "session_id": "ABC123-TEST-2025",
  "verified_at": "2025-11-13T13:53:15.420Z",
  "items": [{
    "product_reference": "077302",
    "product_name": "البشر",
    "verified_quantity": 1,
    "price": 38.5
  }],
  "total": 38.5
}
```

---

## 🎯 Resume Prompt for New Conversation

Use this prompt when starting a new conversation:

```
I'm working on a Flutter e-commerce app (D:\flutter\test) that integrates with Odoo POS for cart verification. The system is already implemented but needs testing.

CURRENT STATE:
- Odoo module (pos_mobile_cart_scanner) has polling API endpoints working
- Flutter app has cart_qr_dialog.dart with polling logic
- QR data includes session_id for tracking
- API tested and responding correctly (GET /pos/api/verified_cart/<session_id>)

WHAT NEEDS TO BE DONE:
- Configure Odoo URL in Flutter (currently placeholder IP)
- Test end-to-end flow with real devices
- Debug any polling issues

FILES TO CHECK:
- lib/features/shop/screens/cart/cart.dart (line ~139 - odooBaseUrl)
- lib/features/shop/screens/cart/cart_qr_dialog.dart (line ~26 - odooBaseUrl)

CONTEXT FILES:
- D:\flutter\test\CART_SYNC_SETUP.md (detailed setup)
- D:\flutter\test\RESUME_CONTEXT.md (full context - this file)

Please help me [describe your specific issue or next step].
```

---

**Created:** 2025-11-13
**Last Updated:** 2025-11-13
**Author:** Claude (Anthropic)
**Project:** Alkirtas E-commerce App - Cart Sync Feature
