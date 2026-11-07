// User mobile app entry point.
//   flutter run                       (Android emulator / phone)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'utils/theme.dart';
import 'firebase_options.dart';
import 'user/user_gate.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'providers/session_provider.dart';
import 'services/user_service.dart';
import 'widgets/common_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
  // The shop is designed for a phone held upright.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(FirebaseSetupError(e));
    return;
  }
  runApp(const CustomerApp());
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => ProductService()),
        Provider(create: (_) => CartService()),
        Provider(create: (_) => OrderService()),
        ChangeNotifierProvider(
          create: (c) => Session(
            auth: c.read<AuthService>(),
            users: c.read<UserService>(),
            carts: c.read<CartService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'ShopEase',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        builder: (context, child) => _PhoneWidth(child: child!),
        home: const UserGate(),
      ),
    );
  }
}

/// On a wide screen (the shop in a desktop browser) the app keeps a phone-sized
/// column in the middle instead of stretching. Phones are not affected.
class _PhoneWidth extends StatelessWidget {
  final Widget child;
  const _PhoneWidth({required this.child});

  static const _maxWidth = 460.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    if (media.size.width <= 600) return child;
    final height = media.size.height;
    return ColoredBox(
      color: Palette.ink,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: height > 800 ? 24 : 0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height > 800 ? 32 : 0),
            child: SizedBox(
              width: _maxWidth,
              child: MediaQuery(
                data: media.copyWith(size: Size(_maxWidth, height - (height > 800 ? 48 : 0))),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
