// Web admin dashboard entry point.
//   flutter run -d chrome -t lib/main_admin.dart
//   flutter build web -t lib/main_admin.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'admin/admin_gate.dart';
import 'utils/theme.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'providers/session_provider.dart';
import 'services/user_service.dart';
import 'widgets/common_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent));
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    runApp(FirebaseSetupError(e));
    return;
  }
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => UserService()),
        Provider(create: (_) => ProductService()),
        Provider(create: (_) => OrderService()),
        ChangeNotifierProvider(
          create: (c) => Session(auth: c.read<AuthService>(), users: c.read<UserService>()),
        ),
      ],
      child: MaterialApp(
        title: 'ShopEase Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const AdminGate(),
      ),
    );
  }
}
