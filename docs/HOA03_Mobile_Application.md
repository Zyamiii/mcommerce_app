# HOA03: Mobile Application Development

Run it with: `flutter run` (choose an Android emulator or a USB-connected phone in the VS Code status bar).

## 1. Screen flow

```
Splash → Login ──(Create one)──► Register
           │
           ▼
   ┌──────── Bottom navigation ─────────┐
   │ Shop │ Cart (badge) │ Orders │ Profile │
   └──┬──────┬──────────────┬────────┬─────┘
      ▼      ▼              ▼        ▼
 Product   Checkout ──► Order    Order detail   Edit profile
 details                placed   (live status)  / Sign out
```

## 2. Screens and features

| Screen | File | Features |
|---|---|---|
| Login | `lib/screens/login_screen.dart` | Email/password validation, show/hide password, forgot-password email |
| Register | `lib/screens/register_screen.dart` | Creates the Auth account and the `users/{uid}` profile |
| Home (Shop) | `lib/screens/home_screen.dart` | AppBar, live product grid, search box, category chips, bottom navigation |
| Product card | `lib/widgets/product_card.dart` | Reusable widget: image, name, price, out-of-stock overlay |
| Product details | `lib/screens/product_details_screen.dart` | Image, name, description, price, live stock, quantity stepper, Add to Cart |
| Cart | `lib/screens/cart_screen.dart` | View items, increase quantity, remove item, computed total with ₱50 shipping |
| Checkout | `lib/screens/checkout_screen.dart` | Delivery form, payment choice, order summary, save details to profile |
| Orders | `lib/screens/orders_screen.dart` | Order history; detail view with a live status tracker |
| Profile | `lib/screens/profile_screen.dart` | Edit name, phone and default address; sign out |

The bottom navigation is in `lib/user/main_shell.dart`. Payment is simulated; no real money is processed.

## 3. Key implementation points

- **CRUD (Read).** The home screen reads the `products` collection through `ProductService`, which turns each document into a `Product` model for the UI. This follows the module's flow: Firestore → Service → Model → UI Widget.
- **State management.** `Session` (`lib/providers/session_provider.dart`) sits above `MaterialApp`, so every screen can read the user's profile and cart through `context.watch<Session>()`. The cart badge updates automatically.
- **Real-time UI.** Lists use Firestore `snapshots()` streams inside a `StreamBuilder`, so stock and order status update without a refresh.
- **Login gate.** `lib/user/user_gate.dart` listens for sign-in changes and shows either the login screen or the main app.
- **Atomic checkout** (`OrderService.placeOrder`). One Firestore **transaction**:
  1. re-reads each product to get the current price, stock and active flag,
  2. stops with a clear message if anything is unavailable,
  3. lowers stock, saves the order and empties the cart.

  Either everything succeeds or nothing changes, so two users cannot both buy the last item.
- **Input validation.** Required fields, email format, a 6-character minimum password, a 10-digit phone number and a full address are checked before submission.

## 4. Test scenarios

| # | Action | Expected |
|---|---|---|
| 1 | Register a new account | Lands on Shop; `users/{uid}` created with role `user` |
| 2 | Tap a category chip / type in search | Grid filters instantly |
| 3 | Add 2 of a product | Cart badge shows 2 |
| 4 | Check out | "Order placed" screen; stock drops by 2; cart empties |
| 5 | Order more than the stock left | Checkout blocked with "Only N left" |
| 6 | Admin changes the order status | Order tracker updates on its own |
