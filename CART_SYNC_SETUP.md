# Cart Sync with Odoo POS - Setup Guide

## ✅ What Was Implemented

Your Flutter app now automatically syncs cart changes from Odoo POS!

When a cashier scans the QR code and adjusts quantities in Odoo, the Flutter app automatically updates without the user having to do anything.

---

## 🔧 How It Works

### Flow:
1. **Customer** opens cart and clicks QR icon
2. **Flutter app** generates QR with unique `session_id`
3. **Flutter app** starts polling Odoo API every 3 seconds
4. **Cashier** scans QR in Odoo POS
5. **Cashier** verifies products and adjusts quantities using +/- buttons
6. **Cashier** clicks "Add to Cart"
7. **Odoo** saves verified cart to database with `session_id`
8. **Flutter app** detects the verified cart via polling
9. **Flutter app** automatically updates local cart
10. **Customer** sees success message: "✓ Panier synchronisé avec succès!"

---

## ⚙️ Configuration

### For Local Testing:

1. Find your computer's local IP address:
   - Windows: `ipconfig` → Look for IPv4 Address (e.g., 192.168.1.100)
   - Mac/Linux: `ifconfig` → Look for inet (e.g., 192.168.1.100)

2. Open `lib/features/shop/screens/cart/cart.dart`

3. Find line 148 and change the IP:
   ```dart
   odooBaseUrl: 'http://192.168.1.100:8069', // Change to YOUR computer's IP!
   ```

4. Also update in `lib/features/shop/screens/cart/cart_qr_dialog.dart` line 26:
   ```dart
   this.odooBaseUrl = 'http://192.168.1.100:8069',
   ```

### For Production:

1. Change both URLs to:
   ```dart
   odooBaseUrl: 'https://www.odoo.alkirtas.com',
   ```

---

## 📱 Testing Steps

### 1. Start Flutter App
```bash
cd D:\flutter\test
flutter run
```

### 2. Open Odoo POS
- Go to http://localhost:8069 (or your Odoo URL)
- Open a POS session

### 3. Test the Flow
1. **In Flutter app:**
   - Add products to cart
   - Click QR code icon
   - See message: "En attente de vérification..."

2. **In Odoo POS:**
   - Click "Scan Cart" button
   - Paste the QR data (copy from Flutter console logs)
   - Adjust quantities using +/- buttons
   - Click "Add to Cart"

3. **Back in Flutter app:**
   - Should automatically show: "✓ Panier synchronisé avec succès!"
   - Cart quantities updated automatically
   - Dialog closes automatically

---

## 🐛 Troubleshooting

### "Cart verification not complete yet" forever

**Problem:** Flutter can't reach Odoo server

**Solutions:**
1. Check if Odoo is running: http://192.168.1.X:8069
2. Make sure both devices are on the same network
3. Check firewall isn't blocking port 8069
4. Verify the IP address is correct

### "Failed to process cart: Error"

**Problem:** QR data format issue

**Solutions:**
1. Make sure QR has `session_id` field
2. Check product references exist in Odoo
3. Look at Odoo logs for detailed error

### Cart doesn't update

**Problem:** Polling not working or session mismatch

**Solutions:**
1. Check console logs for session_id
2. Verify same session_id in Odoo database
3. Check Odoo API endpoint: http://your-odoo/pos/api/verified_cart/SESSION_ID

---

## 📂 Files Modified/Created

### New Files:
- `lib/features/shop/screens/cart/cart_qr_dialog.dart` - QR dialog with polling logic

### Modified Files:
- `pubspec.yaml` - Added uuid package
- `lib/features/shop/screens/cart/cart.dart` - Added session_id generation

---

## 🔑 Key Features

- ✅ Automatic polling every 3 seconds
- ✅ Stops after 5 minutes (timeout)
- ✅ Real-time sync status indicator
- ✅ Auto-closes dialog on success
- ✅ Handles network errors gracefully
- ✅ Cleans up session from Odoo after sync

---

## 🚀 Next Steps

1. Test on local network
2. Adjust polling interval if needed (currently 3 seconds)
3. Change URLs for production deployment
4. Consider adding offline mode handling

---

## 📞 Support

If you have issues:
1. Check Flutter console logs
2. Check Odoo server logs
3. Test API endpoint in browser
4. Verify network connectivity

---

**Created:** 2025-11-13
**Odoo Module:** pos_mobile_cart_scanner
**Flutter App:** alkirtas (D:\flutter\test)
