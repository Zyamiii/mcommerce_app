import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/cart_item.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/user_service.dart';

/// App-wide session state: who is signed in, their live Firestore profile,
/// and (customer app only) their live cart. Sits above MaterialApp so every
/// route can read it with `context.watch<Session>()`.
class Session extends ChangeNotifier {
  final AuthService auth;
  final UserService users;
  final CartService? carts;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _profileSub;
  StreamSubscription<List<CartItem>>? _cartSub;

  bool initializing = true;
  User? authUser;
  AppUser? profile;
  bool profileLoaded = false;
  Object? profileError;
  List<CartItem> cart = const [];

  Session({required this.auth, required this.users, this.carts}) {
    _authSub = auth.authStateChanges().listen(_onAuthChanged);
  }

  bool get signedIn => authUser != null;
  String get uid => authUser!.uid;
  int get cartCount => cart.fold(0, (s, c) => s + c.quantity);
  double get cartSubtotal => cart.fold(0.0, (s, c) => s + c.lineTotal);
  int quantityInCart(String productId) =>
      cart.where((c) => c.productId == productId).fold(0, (s, c) => s + c.quantity);

  void _onAuthChanged(User? user) {
    _profileSub?.cancel();
    _cartSub?.cancel();
    authUser = user;
    profile = null;
    profileLoaded = false;
    profileError = null;
    cart = const [];
    initializing = false;

    if (user != null) {
      _profileSub = users.watchUser(user.uid).listen((p) {
        profile = p;
        profileLoaded = true;
        if (p == null && carts != null) {
          // Customer signed in but has no profile doc yet (e.g. account made
          // in the Firebase console). Create a default one.
          users.ensureProfile(user);
        }
        notifyListeners();
      }, onError: (Object e) {
        profileError = e;
        profileLoaded = true;
        notifyListeners();
      });
      _cartSub = carts?.watchCart(user.uid).listen((c) {
        cart = c;
        notifyListeners();
      }, onError: (_) {});
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _cartSub?.cancel();
    super.dispose();
  }
}
