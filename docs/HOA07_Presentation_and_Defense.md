# HOA07: Final System Presentation and Defense

**Group:** Coach Productions: Shopease

## 1. Presentation slides

The deck has 16 slides and follows the module's suggested contents: introduction, objectives, system features, technologies used, database structure, workflow, demonstration, challenges encountered, and conclusion. It also has screenshot slides for the apps, plus testing results and reflection slides.

## 2. Live demonstration

### Before presenting

1. Charge the phone and connect the phone and laptop to the internet.
2. Install `ShopEase.apk` on the phone and sign out of any account. The app stays upright even if the phone is turned.
3. Open <https://shopease-mcommerce.web.app> on the laptop and sign in as the admin.
4. Turn on Do Not Disturb and close chat bubbles on the phone.
5. Check that the iPhone product has stock.

### Demonstration flow

| Step | Do this | Show this |
|---|---|---|
| 1. Register User | Create a new account on the phone | The account opens in the shop |
| 2. Login User | Sign out, then sign in again | The shop greets the user by name |
| 3. Browse Products | Open the product | Price, stock and description |
| 4. Add to Cart | Add one item and open the cart | Total includes ₱50 shipping |
| 5. Checkout | Enter delivery details and place the order | "Order placed!" and an order number |
| 6. Admin Receives Order | Open Orders on the dashboard | The new order, with no refresh |
| 7. Admin Updates Status | Change the status to Processing | The confirmation message |
| 8. User Receives Update | Open the order on the phone | The tracker moves to Processing |

After the demo, cancel the order on the dashboard so the stock returns.

### Backup video

`release/ShopEase-Demo.mp4` is a 1 minute 51 second silent recording of all 8 steps on the phone, in case the internet fails during the live demo.

## 3. Reflection

### What did you learn?

We learned how to build one Flutter project that runs as both a phone app and a web dashboard. We learned how Firestore keeps two apps in sync, and why security must be enforced by database rules and not only by the app. We also learned that a clean `flutter analyze` does not prove a system works, because some bugs appeared only when we used the real apps. User testing taught us that other people notice things we stop seeing: a tester asked for a show-password button on the Create account screen, which we had added to Login but forgot on Register.

### What challenges did you encounter?

Setting up Firebase was the first challenge, because a Realtime Database was created by mistake instead of Firestore. Security rules were the hardest part: a product saved before we renamed a field blocked order cancelling with a permission error. The web version also behaved differently from the phone, with blank product images and a table too wide to reach the status control. The debugging report in HOA05 lists all 16 bugs.

### What improvements can still be added?

- Real GCash and card payments, since payment is simulated now
- Uploading product images, since products use an image link now
- Notifications when an order status changes
- A customer option to cancel their own order
- Testing on iPhone, since only Android was tested
- A proper signing key for publishing on Google Play

## 4. Practice questions

**Why did you use Firebase instead of building a server?**
Firebase provides accounts, a real-time database and hosting, so we did not need to write or run our own server.

**How does real-time sync work?**
Both apps listen to Firestore through `snapshots()` streams. When a document changes, Firestore sends the change to every listening app, so no one refreshes.

**What stops a normal user from becoming an admin?**
The security rules. Registration can only create the role `user`, and a user can only edit their own name, phone and address. The rules run on Firebase's servers, so changing the app cannot bypass them.

**What happens if two customers buy the last item at once?**
Checkout runs in a Firestore transaction. It rechecks the stock inside the transaction, so the second order fails instead of selling more than the stock. This case was not tested with two real phones at the same time.

**Why does cancelling return stock?**
The order and the stock change run in one transaction. If either part fails, neither is saved, which is what happened during our cancel bug.

**What is the difference between a debug and a release build?**
A debug build is for testing during development. A release build is the final optimized app. Our Admin release build was 52.6 MB, compared with 151 MB for debug.

**Why are the customer and admin apps separate?**
They have different users and jobs, but they share the same models and services. Each has its own entry point: `lib/main.dart` and `lib/main_admin.dart`.

**How do the animations work?**
They use Flutter's built-in animation widgets, such as `AnimatedContainer`, `AnimatedSwitcher` and `Hero`, plus a small shared file, `lib/widgets/motion.dart`, so the timing stays consistent. They are skipped when a phone's "remove animations" setting is on.

**Is the payment real?**
No. GCash and card are simulated for this project, and the app says so at checkout. No real money moves.

## 5. Final project submission

| Requirement | Status |
|---|---|
| Mobile Application | Done |
| Web Admin Dashboard | Done: <https://shopease-mcommerce.web.app> |
| User Testing | Done: 2 testers, all Yes on the main flows (HOA06) |
| Firebase Integration | Done |
| GitHub Repository | Done: <https://github.com/Zyamiii/mcommerce_app> |
| Documentation | Done: HOA01 to HOA07 in `docs/` |
| Presentation Slides | Done |
| APK File | Done: `release/ShopEase.apk` and `release/ShopEase-Admin.apk` |
