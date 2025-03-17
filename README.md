# Alkirtas - E-commerce Flutter App

This is a Flutter e-commerce application for Alkirtas. This documentation provides an overview of the project's structure, key features, and how to get started.

## Table of Contents

1.  [Project Overview](#project-overview)
2.  [Key Features](#key-features)
3.  [Project Structure](#project-structure)
4.  [Dependencies](#dependencies)
5.  [Getting Started](#getting-started)
6.  [Code Structure and Modules](#code-structure-and-modules)
    *   [Authentication (`authentication`)](#authentication-authentication)
    *   [Shop (`shop`)](#shop-shop)
    *   [Personalization (`personalization`)](#personalization-personalization)
    *   [Common Widgets (`common`)](#common-widgets-common)
    *   [Utils (`utils`)](#utils-utils)
    *   [Backend Data (`backendData`)](#backend-data-backenddata)
    *   [Pages (`Pages`)](#Pages-Pages)
7.  [State Management](#state-management)
8.  [Navigation](#navigation)
9.  [Theming and Styling](#theming-and-styling)
10. [Data Persistence](#data-persistence)
11. [Backend Connection](#backend-connection)
12. [Pagination](#pagination)
13. [How to Run the App](#how-to-run-the-app)
14. [Future Improvements](#future-improvements)
15. [Technologies Used](#technologies-used)


## Project Overview

The Alkirtas app is a Flutter-based mobile application designed for browsing and purchasing books and related products. It integrates a shopping cart, user profiles, product details, and a connection to a remote API for data. The app is designed to be efficient, user-friendly, and visually appealing, with a focus on providing a smooth shopping experience.

## Key Features

*   **Product Browsing:** Browse books and other items through categories and a search bar.
*   **Product Details:** View detailed information about products, including price, description, brand, and availability.
*   **Shopping Cart:** Add products to a cart and manage quantities.
*   **Checkout:** Proceed to checkout when the cart total is greater or equal than 20.000 TND.
*   **User Authentication:** Log in to access personalized features.
*   **Settings:** Manage user account settings and profile information.
*   **Theming:** Supports light and dark mode.
*   **Onboarding**: Show the user the onboarding screen, if he is using the app for the first time.
* **Cache**: Manage local cache with `hive`.
* **Pagination**: Manage the products with pagination.

## Project Structure

The project is organized into several modules to maintain a clean and scalable codebase:


## Dependencies

The project uses the following key dependencies:

*   **`flutter`**: The Flutter SDK.
*   **`get`**: For state management, dependency injection, and routing.
*   **`iconsax`**: For icons.
*   **`shared_preferences`**: For simple data persistence (like onboarding status).
*   **`hive`** : for the local cache.
*   **`http`**: For making HTTP requests to the backend API.
*   **`xml`**: for parsing the xml data.
* **`intl`**: for formatting the currency and date.
* **`provider`**: for managing pagination.
* **`bcrypt`**: For the password hashing.

## Getting Started


1.  **Navigate to the project directory:**
    ```
    cd <project-directory>
    ```
2.  **Install dependencies:**
    ```
    flutter pub get
    ```
3.  **Run the app:**
    ```
    flutter run
    ```

## Code Structure and Modules

### Authentication (`authentication`)

*   **`login_page.dart`:** Handles user login, including input validation and API communication.
* **`onboarding.dart`**: Handles the onboarding screen.
*   **`home_page.dart`**: Handles the home page when the user is logged in, it also contains the logout logic.

### Shop (`shop`)

*   **`store.dart`:** Displays the store screen, which includes categories, brands, and products.
*   **`cart.dart`:** Manages the shopping cart functionality, including adding/removing items and checkout.
*   **`product_details.dart`:** Shows detailed information about a product.
*   **`brand_controller.dart`**: Handles fetching the brands data from the backend.
*   **`pagination.dart`**: contains the logic for the pagination.
*   **`category_tab.dart`**: Handles the logic of the category tab.
* **`reference.dart`**: Handles the product reference.
* **`productAttributes.dart`**: Handles the product attributes.

### Personalization (`personalization`)

*   **`settings.dart`:** Provides user profile and account management settings.
* **`settings_menu_tile.dart`**: used to create a tile in the settings.
* **`userProfile_tile.dart`**: used to display the user information.

### Common Widgets (`common`)

*   **`appbar.dart`:** A custom app bar used throughout the app.
*   **`tabbar.dart`:** A custom tab bar.
*   **`cart_menu_icon.dart`:** The cart icon with the item count.
* **`product_provider.dart`**: contains the shopping cart logic.
* **`custom_shapes`**: contain the widget used to create custom shape.
* **`texts`**: contains the widgets used to create custom text.
* **`layout`**: contains the widgets used to create a layout.
* **`images`**: contains the widgets used to display images.

### Utils (`utils`)

*   **`constants`:** Contains constant values like colors, sizes, images, and text strings.
*   **`helpers`:** Provides helper functions (e.g., dark mode check, date formatting).
* **`backendData`**: Contains the data models that we will use to manage the data coming from the backend.
*   **`theme`:** Defines the app's light and dark themes.
*   **`formatters`**: contains the formatters that we use to format data.
* **`device`**: contains the device utilities.

### Backend Data (`backendData`)

*   **`userData.dart`:** Defines the model for user data.
* **`addressData.dart`**: Define the data model for the address.
* **`cartData.dart`**: Define the data model for the cart.
* **`categoryData.dart`**: Define the data model for the categories.
* **`productDetailData.dart`**: Define the data model for the product details.

### Pages (`Pages`)
* Contains the login/logout logic.

## State Management

*   **GetX:** The primary state management solution.
*   **ProductProvider:**  Manages the shopping cart and its items.

## Navigation

*   **GetX:** Used for routing and navigation between screens.
*   **`NavigationMenu`:** The main widget that controls bottom navigation.

## Theming and Styling

*   **`AlkColors`:** Custom color palette.
*   **`AlkSize`:** Standardized sizes and spacing.
* **`AlkShadowStyle`:** Defines the shadows used in the app.
* **`TAppTheme`**:  contains the light and dark theme.
* **`helper_functions`**: Contains helpful functions for the app.

## Data Persistence

*   **`shared_preferences`:** Used to persist simple data, such as whether the user has seen the onboarding screen.
* **`hive`**: Used to cache the data locally.

## Backend Connection

*   **`http`:** Used for sending and receiving data to the backend.
* **`xml`** Used to parse the xml data.

## Pagination
* **`provider`** Used to manage the logic for pagination.

## How to Run the App

1.  Ensure you have Flutter installed.
2.  Run `flutter clean`
3.  Run `flutter pub get`.
4.  Run `flutter run`.

## Future Improvements

*   Implement full user registration.
*   Add more detailed product filtering.
*   Integrate payment processing.
*   Improve offline support.
* Add the delivery logic.
* Add more unit tests.

## Technologies Used

*   **Flutter SDK:** flutter_windows_3.27.1-stable
*   **Java:** 17


