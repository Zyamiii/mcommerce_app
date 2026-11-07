# ShopEase: M-Commerce System

ITE 7 project by Group Hamaza: a mobile shopping app and a web admin dashboard that share one Firebase backend, built with Flutter.

## Documentation

| Activity | Document |
|---|---|
| HOA01: System and Architecture Setup | [docs/HOA01_System_and_Architecture.md](docs/HOA01_System_and_Architecture.md) |
| HOA02: Database and Firebase Configuration | [docs/HOA02_Database_and_Firebase.md](docs/HOA02_Database_and_Firebase.md) |
| HOA03: Mobile Application | [docs/HOA03_Mobile_Application.md](docs/HOA03_Mobile_Application.md) |
| HOA04: Web Admin Dashboard | [docs/HOA04_Web_Admin_Dashboard.md](docs/HOA04_Web_Admin_Dashboard.md) |
| HOA05: System Integration and Debugging Report | [docs/HOA05_System_Integration.md](docs/HOA05_System_Integration.md) |

## Run the project

The project is already connected to Firebase, so no extra configuration is needed.

```bash
flutter pub get
flutter run                                   # mobile app
flutter run -d chrome -t lib/main_admin.dart  # admin dashboard
flutter run -t lib/main_admin.dart            # admin dashboard as a separate Android app
```

To give an account admin access, open **Firestore → users**, select the account, and change its `role` from `user` to `admin`.

## Deploy

The admin dashboard is live at <https://shopease-mcommerce.web.app>.

The customer shop is live at <https://shopease-shop.web.app>.

```bash
firebase deploy --only firestore:rules                       # security rules
flutter build web -t lib/main_admin.dart -o build/web_admin  # admin dashboard
flutter build web -o build/web                               # customer shop
firebase deploy --only hosting                               # both sites
flutter build apk                                            # Android APK
```
