# HOA06: Testing, Optimization, and Deployment

**Group:** Hamaza

## Required outputs

| Output | Status |
|---|---|
| QA Checklist | Done (section 1) |
| User Testing Results | Waiting for classmates to test (section 2) |
| APK File | Done: `ShopEase.apk` and `ShopEase-Admin.apk` |
| Deployed Dashboard | Done: <https://shopease-mcommerce.web.app> |

## 1. QA checklist

Every module below was tested by hand on a Xiaomi M2101K6G phone (Android 13) or in Chrome on Windows. "Phone (release)" means the final release build. Automated checks are also clean: `flutter analyze` reports no issues and all 5 unit tests pass.

### Customer app

| Module | Test | Working? | Tested on |
|---|---|---|---|
| Register | Create a new account | Yes | Phone (debug) |
| Login | Sign in with a correct password | Yes | Phone (release) |
| Login | Wrong password shows "Incorrect email or password" | Yes | Phone (release) |
| Forgot password | No email entered shows "Enter your email first" | Yes | Phone (release) |
| Forgot password | Entering an email shows that the reset link was sent | Yes | Phone (release) |
| Sign out | Returns to the login screen | Yes | Phone (release) |
| Browse | Product list and images load | Yes | Phone (release) |
| Search | A match shows the product; no match shows "No products found" | Yes | Chrome |
| Product details | Shows price, stock and description | Yes | Phone (release) |
| Cart | Add 2 items; total is ₱80,050 with ₱50 shipping | Yes | Phone (release) |
| Cart | The + and − buttons update the totals | Yes | Phone (release) |
| Cart | Remove button empties the cart | Yes | Phone (release) |
| Checkout | Cash on Delivery order; stock goes from 66 to 65 | Yes | Phone (debug) |
| Checkout | GCash order (simulated payment) | Yes | Phone (release) |
| Checkout | Credit/Debit Card order (simulated payment) | Yes | Phone (release) |
| Orders | Order history and status tracker | Yes | Phone (debug), Chrome |
| Profile | Edit the address and save | Yes | Phone (release) |

### Admin dashboard

| Module | Test | Working? | Tested on |
|---|---|---|---|
| Access control | A non-admin account gets "Access denied" | Yes | Live site, Phone |
| Dashboard | Sales, order, product and user totals are correct | Yes | Chrome, Phone |
| Products | Add, edit, hide and delete a product | Yes | Chrome |
| Products | An empty form is refused, with an error on each field | Yes | Chrome |
| Categories | Add, rename and delete a category | Yes | Chrome |
| Orders | New customer orders appear with the right payment method | Yes | Chrome |
| Orders | Status change reaches the customer's tracker without a refresh | Yes | Chrome |
| Orders | Cancelling returns stock (64 back to 66 after two cancels) | Yes | Chrome |
| Users | Lists accounts, search works, and a role can be changed | Yes | Chrome |
| Layout | Pages fit a phone screen; a swipe reaches the far columns | Yes | Phone |

### Security

| Module | Test | Working? | Tested on |
|---|---|---|---|
| Firestore rules | Reads without signing in are refused (403) on all four collections | Yes | API request |

Changing data from the Admin app on the phone was not tested. Those changes were tested in Chrome only.

### Bug found during this testing

| # | Type | Error | Cause | Fix |
|---|---|---|---|---|
| 13 | Wording | The cart showed "Subtotal (1 items)" | The label always used the plural | The label now reads "1 item" for one item |

Bugs 1 to 12 are listed in the HOA05 debugging report.

## 2. User testing

Classmates or students from other groups should test the app. This section stays incomplete until they have.

### Procedure

1. Send the tester `ShopEase.apk` and ask them to install it on an Android phone.
2. Ask them to register an account, browse products, add to cart, and check out.
3. Ask them to answer the Google Form.

### Google Form questions

Use a Yes/No answer for questions 1 to 7, and a paragraph answer for question 8.

1. Is the system easy to use?
2. Did errors occur?
3. Is the interface responsive?
4. Was Register working?
5. Was Login working?
6. Was Cart working?
7. Was Checkout working?
8. What should we improve?

### Results

| Question | Yes | No |
|---|---|---|
| Is the system easy to use? | | |
| Did errors occur? | | |
| Is the interface responsive? | | |
| Was Register working? | | |
| Was Login working? | | |
| Was Cart working? | | |
| Was Checkout working? | | |

**Number of testers:**

**Main suggestions:**

## 3. Optimization

A release build is about a third of the size of a debug build:

| Build | ShopEase Admin size |
|---|---|
| Debug | 151 MB |
| Release | 52.6 MB |

The ShopEase release build is 51.3 MB.

The build also removed unused icons, reducing the icon font by 99.6% (from 1,645,184 to 5,860 bytes).

## 4. APK generation

An APK (Android Package Kit) is the installation file for Android apps. A debug build is for testing during development, and a release build is the final optimized app.

Both apps come from one project, so each has its own command:

```
flutter build apk --release
flutter build apk --release -t lib/main_admin.dart
```

Both commands write to the same file, `build/app/outputs/flutter-apk/app-release.apk`. Each was copied to the `release/` folder right after building, as `ShopEase.apk` and `ShopEase-Admin.apk`.

Both release builds were installed on the test phone. ShopEase was signed in and used for full orders, and ShopEase Admin opened and showed live data while signed in. The APKs use Flutter's default debug signing key, which is fine for installing directly but would need replacing before publishing on Google Play.

## 5. Web deployment

The admin dashboard is on Firebase Hosting at <https://shopease-mcommerce.web.app>.

```
flutter build web -t lib/main_admin.dart -o build/web_admin
firebase deploy --only hosting
```

The live site was opened in Chrome. It loaded the login page, connected to Firebase, and refused a non-admin account with "Access denied".
