# Alkirtas - E-commerce Flutter App

A comprehensive Flutter-based mobile e-commerce application for Alkirtas, a Tunisian office and school supplies retailer. This app features seamless integration with PrestaShop backend and innovative Odoo POS synchronization.

## Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Project Structure](#project-structure)
4. [Dependencies](#dependencies)
5. [Getting Started](#getting-started)
6. [Architecture](#architecture)
7. [Features in Detail](#features-in-detail)
   - [Authentication & Onboarding](#authentication--onboarding)
   - [Shopping & Browsing](#shopping--browsing)
   - [Cart Management](#cart-management)
   - [QR Code Cart Sync with Odoo](#qr-code-cart-sync-with-odoo)
   - [Checkout & Orders](#checkout--orders)
   - [Discount & Promotion System](#discount--promotion-system)
   - [User Profile & Settings](#user-profile--settings)
8. [Backend Integration](#backend-integration)
9. [State Management](#state-management)
10. [Data Persistence](#data-persistence)
11. [Navigation](#navigation)
12. [Theming and Styling](#theming-and-styling)
13. [How to Run the App](#how-to-run-the-app)
14. [Technologies Used](#technologies-used)
15. [Security Features](#security-features)
16. [Future Improvements](#future-improvements)

---

## Project Overview

**App Name**: Alkirtas
**Platform**: Flutter (Android/iOS/Web)
**Version**: 1.0.0+2
**SDK**: Dart 3.6.0+
**Language**: French UI
**Backend**: PrestaShop REST API + Odoo POS Integration
**Git Branch**: cypher

Alkirtas is a production-quality mobile application designed for browsing and purchasing books, stationery, and office supplies. The app provides a seamless shopping experience with innovative features like QR-code based cart synchronization with physical POS terminals, comprehensive cart history, and real-time product updates.

---

## Key Features

### Shopping Experience
- Browse products across 9 main categories
- Advanced search with autocomplete
- Infinite pagination with lazy loading
- Product sorting and filtering
- QR code scanner for quick product lookup
- Brand/manufacturer showcase
- Detailed product pages with image galleries
- Stock availability tracking

### Cart & Checkout
- Persistent shopping cart with Hive storage
- Cart quantity management
- **Innovative QR-based cart sync with Odoo POS**
- Cart history with saved snapshots
- Multiple delivery options with shipping cost calculation
- Tax calculation and discount application
- Cash-on-delivery payment

### User Features
- Email/password authentication with BCrypt encryption
- User profile management
- Multiple delivery address support
- Coupon/discount code system
- Order placement and tracking
- Settings and preferences

### Technical Features
- Offline support with multi-level caching
- Firebase push notifications
- Light and dark theme support
- Animated onboarding for first-time users
- Shimmer loading effects
- French language support
- Real-time data synchronization

---

## Project Structure

```
lib/
├── main.dart                     # App entry point with Firebase & Hive initialization
├── app.dart                      # Root Material app with theme configuration
├── navigation_menu.dart          # Bottom navigation (Home/Shop/Cart/Settings)
│
├── features/                     # Feature-based architecture
│   ├── authentication/           # Login, sign-up, onboarding
│   │   ├── screens/
│   │   │   ├── login/           # Login with BCrypt password verification
│   │   │   ├── signUp/          # User registration
│   │   │   ├── onBoarding/      # First-time user onboarding
│   │   │   └── home/            # Main home dashboard
│   │   └── controllers/         # Authentication logic
│   │
│   ├── shop/                    # E-commerce features
│   │   ├── models/              # Cart models (Hive)
│   │   ├── controllers/         # Business logic
│   │   └── screens/
│   │       ├── store/           # Product browsing with 9 categories
│   │       ├── cart/            # Shopping cart & cart history
│   │       ├── product_details/ # Detailed product view
│   │       └── checkout/        # Order checkout
│   │
│   └── personalization/         # User profile & settings
│       └── screens/
│           ├── settings/        # Settings menu
│           └── address/         # Address management
│
├── common/                      # Reusable UI components
│   ├── widgets/
│   │   ├── appbar/             # Custom app bars
│   │   ├── custom_shapes/      # Curved containers
│   │   ├── products/           # Product cards
│   │   ├── shimmer/            # Loading skeletons
│   │   └── qr_scanner/         # QR code scanner widget
│   └── providers/              # Global providers
│
├── data/                        # Data layer
│   └── controllers/            # API controllers for PrestaShop
│       ├── cart_controller.dart
│       ├── order_controller.dart
│       ├── discount_controller.dart
│       └── ...
│
├── api/                        # External API integrations
│   ├── firebase_api.dart       # Firebase Cloud Messaging
│   ├── banner_api.dart         # Promotional banners
│   └── category_api.dart       # Category data
│
└── utils/                      # Utilities and helpers
    ├── backendData/            # Global data stores
    ├── constants/              # Colors, sizes, text strings
    ├── theme/                  # Light & dark themes
    ├── helpers/                # Utility functions
    └── formatters/             # Date/number formatting
```

### Project Statistics
- **Total Dart Files**: 153
- **Source Code Size**: 9.1MB
- **Main Categories**: 3 (authentication, shop, personalization)
- **Total Screens**: 15+
- **Reusable Components**: 40+

---

## Dependencies

### Core Framework
- **flutter**: Latest stable
- **get**: ^4.6.6 - GetX for state management, DI, and routing
- **provider**: ^6.0.5 - ChangeNotifier-based state management

### Local Storage
- **hive**: ^2.2.3 - NoSQL database for local persistence
- **hive_flutter**: ^1.1.0 - Hive Flutter integration
- **shared_preferences**: ^2.0.0 - Simple key-value storage
- **get_storage**: ^2.1.1 - GetX persistent storage

### Networking
- **http**: ^0.13.3 - HTTP client for REST API
- **webview_flutter**: ^4.10.0 - WebView for password recovery

### Firebase
- **firebase_core**: ^2.27.1
- **cloud_firestore**: ^4.15.9
- **firebase_analytics**: ^10.8.10
- **firebase_messaging**: ^14.7.10
- **flutter_local_notifications**: ^18.0.1

### QR Code
- **qr_flutter**: ^4.1.0 - QR code generation
- **mobile_scanner**: ^3.5.6 - QR code scanning
- **uuid**: ^4.5.1 - Session ID generation

### UI Components
- **iconsax**: ^0.0.8 - Iconsax icon library
- **cupertino_icons**: ^1.0.8
- **smooth_page_indicator**: ^1.2.0+3 - Carousel indicators
- **carousel_slider**: ^5.0.0 - Image carousels
- **shimmer**: ^3.0.0 - Loading effects
- **readmore**: ^3.0.0 - Expandable text
- **cached_network_image**: ^3.3.1 - Image caching

### Utilities
- **intl**: ^0.19.0 - Internationalization
- **logger**: ^2.5.0 - Logging
- **url_launcher**: ^6.3.1 - Deep linking
- **bcrypt**: 1.1.3 - Password hashing
- **permission_handler**: ^11.3.1 - Runtime permissions
- **flutter_native_splash**: ^2.4.4 - Splash screen

---

## Getting Started

### Prerequisites
1. Flutter SDK (3.27.1-stable or higher)
2. Dart 3.6.0+
3. Java 17 (for Android builds)
4. Android Studio / Xcode (for platform development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd test
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Clean build (if needed)**
   ```bash
   flutter clean
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### First Run
On first launch, the app will:
1. Show animated onboarding screens
2. Request terms & conditions acceptance
3. Initialize Hive database
4. Setup Firebase Cloud Messaging
5. Cache initial data (banners, categories)

---

## Architecture

### Design Patterns
- **Feature-Based Architecture**: Organized by business features
- **MVC Pattern**: Controllers handle business logic
- **Provider Pattern**: Reactive state management with ChangeNotifier
- **Repository Pattern**: Data controllers abstract API calls
- **Singleton Pattern**: Global data stores (UserData, CartData, AddressData)

### Data Flow
```
UI Layer (Screens & Widgets)
    ↓
Controllers/Providers (CartProvider, StoreController)
    ↓
API Controllers (CartController, ProductControllerStore)
    ↓
Backend Services (PrestaShop REST API, Odoo API)
    ↓
Local Storage (Hive, SharedPreferences)
```

### Performance Optimizations
1. **Lazy Loading**: Infinite pagination for product lists
2. **Multi-Level Caching**: API → Hive → Memory
3. **Image Caching**: Automatic network image caching
4. **Shimmer Loading**: Better UX during data fetches
5. **Debounced Search**: Reduced API calls on search input

---

## Features in Detail

### Authentication & Onboarding

#### Onboarding
- Animated first-time user experience
- Terms & conditions acceptance (required)
- Stored in SharedPreferences to prevent re-display

#### Login
- Email/password authentication
- **BCrypt password verification** for security
- API integration with PrestaShop customer database
- Session persistence across app restarts

#### Sign-up
- User registration form with validation
- Email validation
- Password requirements
- Automatic terms acceptance

**Files**: [lib/features/authentication/](lib/features/authentication/)

---

### Shopping & Browsing

#### Home Screen
- **Promotional banner carousel** with smooth transitions
- **Category showcase** with icons
- **Dynamic home sections** (configurable via JSON)
- **Top-selling products** grid (Category ID: 763)
- **Special sections**: "Alkirtas Books" & "Alkirtas Office"

#### Store/Shop Screen
**9 Main Product Categories**:
1. Livres (Books)
2. Papetrie (Stationery)
3. Bagagerie (Luggage)
4. Parascolaires (School Supplies)
5. Fournitures (Supplies)
6. Cadeaux et Fêtes (Gifts & Celebrations)
7. Bureautique (Office)
8. Jeux et Jouets (Games & Toys)
9. Art et Loisir (Arts & Crafts)

**Features**:
- Tabbed navigation for categories
- Drawer-based subcategory navigation
- Search bar with autocomplete
- QR code scanner integration
- Brand showcase carousel
- Infinite scroll pagination
- Product sorting (Name, Price, Relevance)
- Active product filtering

#### Product Details
- Image gallery slider
- Product metadata (brand, price, discount)
- Feature/specification list
- Stock availability indicator
- Product reference/SKU
- Expandable description (ReadMore)
- Quantity selector
- Add to cart button

**Files**:
- [lib/features/shop/screens/store/](lib/features/shop/screens/store/)
- [lib/features/shop/screens/product_details/](lib/features/shop/screens/product_details/)

---

### Cart Management

#### Shopping Cart
- **Add/Remove products** with instant UI updates
- **Adjust quantities** with increment/decrement buttons
- **Real-time total calculation**
- **Persistent storage** with Hive database
- **Cart badge** showing item count in navigation
- **Empty cart state** with friendly messaging

#### Cart Data Model
```dart
{
  productId: String,
  productName: String,
  productBrand: String,
  productPrice: String,
  productQuantity: String,
  productDiscount: String,
  productImage: String,
  productReference: String,
  productStock: String,
  productDescription: String,
  productBrandId: String,
  productImageList: String (comma-separated),
  productFeatures: String (comma-separated)
}
```

#### Cart Operations
1. **Add to Cart**: Check if exists → increment quantity or add new
2. **Remove**: Delete by product ID
3. **Clear**: Remove all items
4. **Calculate Total**: Sum (price × quantity) for all items

**Files**: [lib/features/shop/screens/cart/](lib/features/shop/screens/cart/)

---

### QR Code Cart Sync with Odoo

**Unique Feature**: Synchronize mobile cart with physical POS terminal via QR code scanning.

#### How It Works

1. **Generate QR Code**
   - User taps "Sync with POS" in cart
   - App generates unique session ID (UUID)
   - Creates QR code with cart data:
     ```json
     {
       "session_id": "unique-uuid",
       "cartItems": [
         {
           "productReference": "REF001",
           "productPrice": "15.99",
           "productQuantity": "2",
           "productDiscount": "0"
         }
       ],
       "totalPrice": 31.98
     }
     ```

2. **Scan at POS Terminal**
   - Customer scans QR code on Odoo POS terminal
   - Odoo validates product references
   - Creates verified cart with full product details
   - Stores verification result with session ID

3. **Automatic Sync**
   - Mobile app polls Odoo every 3 seconds
   - Endpoint: `GET /pos/api/verified_cart/{sessionId}`
   - Timeout: 5 minutes (100 polls)
   - On success (HTTP 200):
     - Updates local cart with Odoo data
     - Closes sync dialog
     - Saves to cart history

4. **Data Persistence**
   - Odoo marks session as 'synced'
   - Auto-deleted after 30 days by scheduled job
   - Cart history retains QR for reference

#### Benefits
- **Seamless checkout**: Browse on mobile, pay in-store
- **No manual entry**: POS automatically loads cart
- **Data validation**: Odoo verifies all products
- **History tracking**: QR codes saved for repeat purchases

**Files**:
- [lib/features/shop/screens/cart/cart_qr_dialog.dart](lib/features/shop/screens/cart/cart_qr_dialog.dart)
- [lib/common/widgets/qr_scanner/](lib/common/widgets/qr_scanner/)

---

### Cart History

#### Saved Cart Model
```dart
@HiveType(typeId: 1)
class SavedCart {
  final String id;              // Timestamp-based
  final DateTime savedDate;
  final List<Map> items;
  final double totalAmount;
  final String qrData;          // Encoded QR for later scanning
}
```

#### Features
- Save cart snapshots with timestamp
- View all saved carts with total amounts
- Load previous cart to current cart
- Delete saved carts
- Display QR code for each saved cart
- Persistence with Hive database

**Use Cases**:
- Recurring purchases (e.g., monthly office supplies)
- Wishlist functionality
- Share cart via QR with colleagues

**Files**: [lib/features/shop/screens/cart/cart_history.dart](lib/features/shop/screens/cart/cart_history.dart)

---

### Checkout & Orders

#### Checkout Flow

1. **Address Selection**
   - Choose existing delivery address
   - Create new address with form validation

2. **Delivery Method**
   - **"First Delivery"**: 9 TND shipping fee (Carrier ID: 6)
   - **"Alkirtas corniche"**: Free shipping (Carrier ID: 4)

3. **Price Breakdown**
   - Product subtotal (with discounts)
   - Tax calculation (VAT from PrestaShop)
   - Shipping cost
   - Coupon discount
   - **Final Total**

4. **Payment Method**
   - Cash on Delivery (default)
   - Module: ps_cashondelivery

5. **Order Creation**
   - POST to PrestaShop `/api/orders`
   - Include cart ID, address, carrier
   - Order state: 13 (awaiting payment)

6. **Confirmation**
   - Display order ID
   - Clear shopping cart
   - Navigate to home

#### Address Validation
- **Phone**: 8-digit validation
- **Postal code**: 4-digit validation
- **Required fields**: Name, street, city, governorate

**Files**: [lib/features/shop/screens/checkout/](lib/features/shop/screens/checkout/)

---

### Discount & Promotion System

#### Coupon Management
- **Add coupon codes** via input field
- **Validation**: Check expiry date via API
- **Types**: Percentage discount or fixed amount
- **Display**: Selected coupon shown in checkout
- **Persistence**: Hive storage for coupon history
- **Expiry tracking**: Display expiration dates

#### Product Discounts
- **Fetch specific prices** from PrestaShop
- **Priority**: Permanent > Time-limited
- **Date validation**: Check from/to dates
- **Calculation**: Percentage-based reductions
- **Display**: Show original and discounted prices

**API Endpoints**:
- `GET /api/specific_prices?filter[id_product]=$productId`
- `GET /api/cart_rules?filter[code]=$code`

**Files**:
- [lib/data/controllers/discount_controller.dart](lib/data/controllers/discount_controller.dart)
- [lib/providers/coupon_provider.dart](lib/providers/coupon_provider.dart)

---

### User Profile & Settings

#### Profile Management
- View user information (name, email)
- Stored in UserData singleton
- API-based persistence with PrestaShop

#### Address Management
- **Create** new delivery addresses
- **Update** existing addresses
- **Form validation** for all fields
- **Fields**: First/last name, street, governorate, city, postal code, phone

#### Settings Menu
- Current cart access
- Cart history
- Address management
- Terms & conditions
- About/FAQ
- **Logout** (clears all local data)

**Files**: [lib/features/personalization/](lib/features/personalization/)

---

## Backend Integration

### PrestaShop REST API

**Base URL**: `https://www.alkirtas.com/api/`
**Format**: JSON & XML
**Authentication**: API key-based

#### Key Endpoints

**Authentication**
```
GET /api/customers?filter[email]=$email
Returns: id, firstname, lastname, email, passwd (bcrypt hash)
```

**Products**
```
GET /api/products
GET /api/products?filter[id_category]=$categoryId
GET /api/products?filter[name]=%query%
GET /api/products/$productId
```

**Cart**
```
GET /api/carts?filter[id_customer]=$customerId
POST /api/carts (XML body)
GET /api/carts/$cartId
```

**Orders**
```
POST /api/orders (XML body)
Fields: total_paid, products, shipping, carrier, payment method
```

**Addresses**
```
GET /api/addresses?filter[id_customer]=$customerId
POST /api/addresses (XML body)
PUT /api/addresses/$addressId
```

**Discounts**
```
GET /api/specific_prices?filter[id_product]=$productId
GET /api/cart_rules?filter[code]=$code
```

**Stock**
```
GET /api/stock_availables?filter[id_product]=$productId
```

**Manufacturers/Brands**
```
GET /api/manufacturers?filter[id]=$brandId
Image URL: https://www.alkirtas.com/img/m/$brandId.jpg
```

#### External JSON Files
- **Banners**: `https://alkirtas.com/banners/banners.json`
- **Categories**: `https://alkirtas.com/banners/categories.json`
- **Home Sections**: `https://alkirtas.com/banners/sections.json`

### Odoo POS API

**Base URL**: `https://www.odoo.alkirtas.com` (production)
**Local Testing**: `http://192.168.1.X:8069`

#### Verified Cart Endpoint
```
GET /pos/api/verified_cart/{sessionId}
Polling: Every 3 seconds
Timeout: 5 minutes
Returns: verified_data with items (HTTP 200) or not ready (HTTP 404)
```

**Files**: [lib/data/controllers/](lib/data/controllers/)

---

## State Management

### GetX (Primary)
- **NavigationController**: Bottom navigation tabs
- **OnboardingController**: Onboarding state
- **Category Management**: Category selection
- **Routing**: Named routes with GetX

### Provider (Secondary)
- **CartProvider**: Cart items and operations
- **CouponProvider**: Coupon state
- **StoreController**: Product listing and filtering

### ChangeNotifier
- Reactive updates with `notifyListeners()`
- Used in CartProvider and StoreController

---

## Data Persistence

### Hive Database
**Boxes**:
- `cartBox`: Current shopping cart
- `savedCartsBox`: Cart history
- `couponBox`: Saved coupons
- `bannersBox`: Promotional banners
- `categoriesBox`: Category data
- `sectionsBox`: Home sections
- `productsBox`: Cached products

### SharedPreferences
- `hasSeenOnboarding`: Boolean
- `hasSeenTerms`: Boolean
- `isLoggedIn`: Boolean
- User session data

### Caching Strategy
1. **Products**: Cached by category + offset
2. **Banners**: Singleton cache with external JSON fallback
3. **Categories**: Persistent cache
4. **Search**: Real-time (no cache)
5. **Cart**: Persistent across app restarts

---

## Navigation

### Bottom Navigation (4 Tabs)
1. **Home**: Dashboard with banners and featured products
2. **Shop**: Product browsing with categories
3. **Cart**: Shopping cart and checkout
4. **Settings**: User profile and preferences

### Navigation Flow
```
Splash Screen
    ↓
Onboarding (first time) / Login
    ↓
Home (NavigationMenu)
    ├── Shop → Product Details → Cart
    ├── Cart → Checkout → Order Confirmation
    └── Settings → Address Management / Cart History
```

**Controller**: [lib/navigation_menu.dart](lib/navigation_menu.dart)

---

## Theming and Styling

### Color Palette
- **Primary**: Purple theme (#6200EA variants)
- **Light Mode**: White backgrounds, dark text
- **Dark Mode**: Dark backgrounds, light text

### Typography
- **Fonts**: Poppins (primary), Cairo (Arabic support)
- **Styles**: Defined in text_theme.dart

### Custom Styles
- **AlkColors**: Custom color constants
- **AlkSize**: Standardized spacing and sizes
- **AlkShadowStyle**: Shadow definitions

### UI Components
- **Curved Headers**: Custom container shapes
- **Shimmer Effects**: Loading skeletons
- **Animated Transitions**: Fade + slide animations
- **Product Cards**: Multiple card styles
- **Custom AppBar**: With search and QR scanner

**Files**: [lib/utils/theme/](lib/utils/theme/)

---

## How to Run the App

### Development
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run with specific flavor (if configured)
flutter run --flavor dev
```

### Build for Production

**Android (APK)**
```bash
flutter build apk --release
```

**Android (App Bundle)**
```bash
flutter build appbundle --release
```

**iOS**
```bash
flutter build ios --release
```

---

## Technologies Used

### Framework & Language
- **Flutter SDK**: 3.27.1-stable
- **Dart**: 3.6.0+
- **Java**: 17 (Android builds)

### Backend
- **PrestaShop**: REST API for e-commerce
- **Odoo**: POS integration for cart sync
- **Firebase**: Cloud Messaging, Analytics, Firestore

### State Management
- GetX 4.6.6
- Provider 6.0.5

### Database
- Hive 2.2.3 (NoSQL)
- SharedPreferences 2.0.0

### UI/UX
- Iconsax icons
- Shimmer loading effects
- Carousel sliders
- Cached network images

---

## Security Features

### Authentication
- **BCrypt password hashing**: Secure password verification
- **Session management**: Persistent login with SharedPreferences
- **API key authentication**: PrestaShop REST API

### Data Protection
- **HTTPS**: All API calls use SSL/TLS
- **Local storage**: Hive encrypted storage support
- **Permission handling**: Runtime permissions for camera
- **Input validation**: Form validation on all user inputs

### Best Practices
- No sensitive data in logs
- API key management (consider environment variables)
- Secure password recovery via WebView
- Terms & conditions acceptance tracking

---

## Future Improvements

### Planned Features
- Full user registration flow enhancement
- Advanced product filtering (price range, ratings)
- Payment gateway integration (credit card, mobile money)
- Wishlist functionality
- Product reviews and ratings
- Order history and tracking
- Push notification preferences
- Multi-language support (Arabic, English)

### Technical Enhancements
- Unit and widget test coverage
- Integration tests for critical flows
- CI/CD pipeline setup
- Environment-based configuration
- API key security improvements
- Code splitting for better performance
- Accessibility improvements
- Analytics dashboard

### UX Improvements
- Voice search
- Product recommendations
- Recently viewed products
- Share products on social media
- Offline mode enhancements
- In-app chat support

---

## Contributors

For contributions, bug reports, or feature requests, please contact the development team.

## License

Copyright © 2024 Alkirtas. All rights reserved.

---

**Last Updated**: November 2025
**Version**: 1.0.0+2
**Git Branch**: cypher
