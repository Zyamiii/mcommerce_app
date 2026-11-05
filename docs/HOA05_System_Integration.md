# HOA05: System Integration

## 1. How the parts connect

The mobile app and the admin dashboard never talk to each other directly. Both read and write the **same Firestore database**, and Firestore pushes every change to all connected apps in real time.

```
 Mobile app ──write──► Firestore ──push──► Admin dashboard
 Mobile app ◄──push─── Firestore ◄──write── Admin dashboard
```

Both apps also import the same `lib/models` and `lib/services`, so a product or order means exactly the same thing on both sides.

## 2. Real-time synchronization

| Flow | Admin side | Firestore | Mobile side |
|---|---|---|---|
| Add product | Admin adds a product | `products` document created | Product appears in the grid |
| Hide product | Admin turns Visible off | `isActive = false` | Product disappears |
| Place order | Order appears in Recent orders; Pending count rises | Transaction: `orders` + `stock` + `cart` | User checks out |
| Update status | Admin changes the status | `status` updated | Order tracker updates |
| Cancel order | Admin picks Cancelled | `status` + `stock` restored | Tracker shows Cancelled |
| Sell out | Low-stock panel lists it | `stock` reaches 0 | "Out of stock" overlay |

### Test procedure
Run both apps side by side: `flutter run` for the mobile app, and `flutter run -d chrome -t lib/main_admin.dart` for the dashboard.

1. **Product sync.** Add a product in the dashboard. It should appear in the mobile app without a refresh.
2. **Order sync.** Place an order in the mobile app. It should appear in the dashboard immediately.
3. **Status sync.** Change the order status in the dashboard. The mobile order tracker should update on its own.

## 3. Data validation

### Product data
| Check | In the form | In the security rules |
|---|---|---|
| Empty fields | All fields required | `productName`, `description` and `imageUrl` must not be empty |
| Negative price | Rejected; must be above 0 | `price > 0` |
| Invalid stock | Whole numbers only | `stock` must be an integer, 0 or more |

### Order data
| Check | How it is handled |
|---|---|
| Duplicate orders | The order ID is created once before saving, the Place Order button is disabled while saving, and the cart empties in the same transaction |
| Incorrect total | The app recalculates from current product prices, and the rules require `total == subtotal + shippingFee` |
| Missing products | Checkout stops if a product was deleted, hidden, or is short on stock; the rules reject an order with no items |

## 4. Debugging report

Tools used: the VS Code Debug Console, Flutter logs, `flutter analyze`, the Firebase console, and direct requests to the Firestore API.

### Errors encountered during development

| # | Type | Error | Cause | Fix |
|---|---|---|---|---|
| 1 | Firebase connection | `403: Cloud Firestore API has not been used in project` | A Realtime Database had been created instead of Firestore. They are different products. | Created a Firestore Database in the Firebase console |
| 2 | Authentication | `The given sign-in provider is disabled for this Firebase project` | Email/Password sign-in was not turned on | Enabled it under Authentication → Sign-in method, and added a clearer message in `AuthService` for this error |
| 3 | Setup | `users` collection missing in Firestore | No account had been registered yet; the app creates it at first sign-up | Registered an account, then set its role to `admin` |
| 4 | Tooling | VS Code: `Gradle task failed (exit 1)` | The Gradle Kotlin extension runs a check on the `android/` folder whenever the project opens | Turned off that automatic check in `.vscode/settings.json` |
| 5 | Compile | `The getter 'name' isn't defined for the type 'Product'` | Renaming the field to `productName` missed the sort in `ProductService` | Found by `flutter analyze`; updated the sort |
| 6 | Data | A product saved earlier used the old `name` field | The field was renamed after that product was created | The app still reads the old field, and saving the product in the dashboard replaces it with `productName` |
| 7 | Web images | Product images were blank in Chrome but fine on the phone | The image host blocks direct web requests (CORS) | Set `ProductImage` to fall back to a browser image element with `WebHtmlElementStrategy.fallback` |
| 8 | Firebase rules | `[cloud_firestore/permission-denied]` when cancelling an order | The product from error 6 failed `validProduct()` when its stock was returned | Saved the product in the dashboard, which moved it to `productName`; stock then returned from 65 to 66 |
| 9 | Dashboard layout | The order Status dropdown and user Role buttons sat past the right edge | The tables were wider than the screen, and a mouse wheel only scrolls up and down | Added a visible scrollbar to `TableCard` and tightened the column spacing |
| 10 | Dashboard data | The Users card showed 1 when 2 accounts existed | The card counted only non-admin accounts | The card now counts every account |
| 11 | Dashboard layout | The new scrollbar covered the bottom table row | The table had no space beneath it | Added 12 px of padding under the table |
| 12 | Dashboard wording | The cancel dialog showed "Cancel" beside "Cancel order" | The dialog used its default button label | Renamed the button to "Keep order" |
| 13 | App wording | The cart showed "Subtotal (1 items)" | The label always used the plural | The label now reads "1 item" for one item |
| 14 | New design | Turning the phone sideways hid the products behind the navigation bar | The layout is built for a phone held upright | Locked the customer app to portrait |
| 15 | New design | The back arrow was hard to see over the photo, and some screens had a grey status bar | Light icons sat on a bright image, and Android added its default status bar tint | Added a dark fade over the photo and made the status bar transparent |
| 16 | Hosting | A browser kept showing the old dashboard after a new deploy | Firebase Hosting let browsers keep app files for one hour | Added no-cache headers in `firebase.json` |

### Problems prevented in the code

| Type | Risk | Prevention |
|---|---|---|
| Null values | Right after sign-up, the user's profile may not exist yet | `UserGate` shows a loading screen until the profile arrives, and `Session` creates a missing profile |
| Null values | Missing Firestore fields could crash the models | Each `fromDoc` gives a safe default, such as `d['price'] ?? 0` |
| Navigation | Pushed screens could not reach data placed below `MaterialApp` | `Session` is provided above `MaterialApp` |
| Navigation | The Register screen could stay on top after sign-up | It closes itself after a successful registration |

## 5. Deployment commands

| Target | Command |
|---|---|
| Security rules | `firebase deploy --only firestore:rules` |
| Admin dashboard (web) | `flutter build web -t lib/main_admin.dart -o build/web_admin`, then `firebase deploy --only hosting` |
| Android APK | `flutter build apk` (output: `build/app/outputs/flutter-apk/app-release.apk`) |
