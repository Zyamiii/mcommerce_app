# HOA04: Web-Based Admin Dashboard

Run it with: `flutter run -d chrome -t lib/main_admin.dart`
Build it with: `flutter build web -t lib/main_admin.dart -o build/web_admin`
Publish it with: `firebase deploy --only hosting`
Install it on an Android phone with: `flutter run -t lib/main_admin.dart`

On Android, the dashboard installs as a separate app called **ShopEase Admin** (`com.hoa.mcommerce_app.admin`), so it sits next to the ShopEase user app. `android/app/build.gradle.kts` picks the app ID and name from the entry point being built.

## 1. Access control

`AdminGate` lets a user in only when `users/{uid}.role == "admin"`. Anyone else sees **Access denied** and a sign-out button. The Firestore rules enforce the same check on the server.

## 2. Layout

The dashboard has a **sidebar** with Dashboard, Products, Categories, Orders and Users. On narrow screens the sidebar becomes a drawer menu. The account menu in the top-right corner holds **Sign out**.

## 3. Modules

| Module | File | Features |
|---|---|---|
| Dashboard | `lib/admin/screens/dashboard_screen.dart` | Summary cards (gross sales, delivered sales, total orders, pending orders, products, users); recent orders; orders by status; low-stock list (5 or fewer); **Load sample data** button when the store is empty |
| Products | `lib/admin/screens/products_screen.dart` | Add form (Product Name, Description, Price, Stock, Category, Image URL); product table with Edit and Delete; search; category filter; show/hide toggle |
| Categories | `lib/admin/screens/categories_screen.dart` | Add, rename (updates its products too), and delete (blocked while it still has products) |
| Orders | `lib/admin/screens/admin_orders_screen.dart` | Table of Customer Name, Products Ordered, Total Amount and Status; filter and search; tap a row for full details. **Cancelling returns the items to stock.** |
| Users | `lib/admin/screens/users_screen.dart` | All accounts with order count and total spent; grant or remove admin (you cannot demote yourself) |

**Product CRUD:** Create (Add product), Read (table), Update (Edit), Delete (Delete with confirmation).

**Order statuses:** the module's Pending, Processing and Delivered, plus two additions, Shipped and Cancelled.

## 4. Implementation notes

- All tables are live Firestore streams, so a new mobile order appears on the dashboard without a refresh.
- Order status changes run in a **transaction**. Cancelled orders cannot be reopened, and stock is restored with `FieldValue.increment`.
- Product changes record `updatedAt` with the server time.

## 5. Test scenarios

| # | Action | Expected |
|---|---|---|
| 1 | Log in with a `user` account | "Access denied" |
| 2 | Log in as admin and click Load sample data | 4 categories and 10 products appear |
| 3 | Save a product with an empty field or price 0 | Validation error; nothing saved |
| 4 | Edit a product | Change appears in the mobile app |
| 5 | Delete a product | Removed from the table and the mobile app |
| 6 | Turn Visible off | Product disappears from the mobile app |
| 7 | Change an order from Pending to Cancelled | Confirmation, then stock restored |
