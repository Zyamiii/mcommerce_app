// User mobile app entry point.
//   flutter run                       (Android emulator / phone)
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
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
        home: const UserGate(),
      ),
    );
  }
}
