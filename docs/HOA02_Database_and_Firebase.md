# HOA02: Database Structuring and Firebase Configuration

## 1. Firebase services used

| Service | Purpose |
|---|---|
| Authentication (Email/Password) | Customer and admin accounts |
| Cloud Firestore | All application data, with real-time sync |
| Security Rules | Server-side access control by role |
| Hosting (optional) | Publishing the admin dashboard on the web |

## 2. Firestore data model

Firestore is a document database: **collections** hold **documents**, and documents can contain **subcollections**.

```
users/{uid}
   └─ cart/{productId}
categories/{categoryId}
products/{productId}
orders/{orderId}
```

### users/{uid}
The document ID is the Firebase Auth UID.
| Field | Type | Example |
|---|---|---|
| name | string | "Juan Dela Cruz" |
| email | string | "juan@email.com" |
| phone | string | "09171234567" |
| address | string | "123 Rizal St, Manila" |
| role | string | "user" or "admin" |
| createdAt | timestamp | server time |

The `role` field applies **Role-Based Access Control (RBAC)**: `user` accounts use the mobile app and `admin` accounts use the admin dashboard.

### users/{uid}/cart/{productId}
| Field | Type |
|---|---|
| name, imageUrl | string |
| price | number |
| quantity | number |
| addedAt | timestamp |

Storing the cart in Firestore means it syncs across devices and survives a reinstall.

### categories/{categoryId}
| Field | Type |
|---|---|
| name | string |
| createdAt | timestamp |

### products/{productId}
| Field | Type | Notes |
|---|---|---|
| productName, description | string | required |
| price | number | in pesos, must be above 0 |
| stock | number (int) | decreased at checkout |
| categoryId | string | reference to `categories` |
| categoryName | string | *denormalized* so lists need no join |
| imageUrl | string | public image link |
| isActive | boolean | hides the product from the app |
| createdAt, updatedAt | timestamp | |

### orders/{orderId}
| Field | Type | Notes |
|---|---|---|
| userId | string | owner (Auth UID) |
| customerName, customerEmail, phone, shippingAddress | string | snapshot at checkout |
| paymentMethod | string | COD / GCash / Card (simulated) |
| items | array of maps | `{productId, name, price, quantity, imageUrl}` |
| subtotal, shippingFee, total | number | |
| status | string | pending → processing → shipped → delivered, or cancelled |
| timestamp | timestamp | when the order was placed |
| updatedAt | timestamp | last status change |

The module's required fields (`userId`, `total`, `status`, `timestamp`) are all present. The others support delivery details and the order screens.

**Design decisions**
- **Embedded order items.** Each order keeps a copy of the item names and prices, so a later price change or product deletion never alters a past order.
- **Denormalized `categoryName`.** This avoids extra reads. Renaming a category updates its products in one batch.
- **No composite indexes needed.** Filtering and sorting by category and search are done in the app.

## 3. Security rules summary (`firestore.rules`)

| Collection | Read | Write |
|---|---|---|
| users | the owner or an admin | Owner creates with `role = user` only. Owner edits name, phone and address. An admin can change roles. |
| users/…/cart | owner | owner |
| categories | signed-in users | admin |
| products | signed-in users | Admin only, and the data must be valid. **One exception:** checkout may lower `stock`, and nothing else, never below 0. |
| orders | the owner or an admin | Owner creates with `status = pending`, at least one item and a correct total. Only an admin updates. |

This meets the module's objective: **only authenticated users can access data, and only admin can modify products**. Without signing in, every collection returns HTTP 403 (tested on the live database).

The stock exception exists because placing an order must reduce stock. Doing that purely on the server would need Cloud Functions, which require Firebase's paid plan. The rule limits a user to lowering that one field. Its known limit: a modified app could lower stock without placing an order, and a real store would move this step to a server function.

The rules check the admin role server-side by reading `users/{uid}.role`, so a modified app cannot gain admin access.

## 4. Firebase configuration steps

1. Go to <https://console.firebase.google.com>, choose **Create a project**, and enter a name (for example `shopease-mcommerce`).
2. Open **Build → Authentication → Get started** and enable **Email/Password**.
3. Open **Build → Firestore Database → Create database**, choose a location (`asia-southeast1` is Singapore, closest to PH), and select **production mode**.
4. In the VS Code terminal, inside the project folder:
   ```
   firebase login
   flutterfire configure --project=<your-project-id> --platforms=android,ios,web
   ```
   This registers the Android, iOS and Web apps and generates `lib/firebase_options.dart` and `android/app/google-services.json`.
5. Deploy the security rules:
   ```
   firebase use <your-project-id>
   firebase deploy --only firestore:rules
   ```
6. Create the first admin. Register an account in the app, then in **Firestore → users → (that user)** change `role` to `admin`.
7. Sign in to the admin dashboard and click **Load sample data** to seed 4 categories and 10 products.
