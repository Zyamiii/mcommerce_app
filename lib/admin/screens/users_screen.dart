import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/formatters.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../providers/session_provider.dart';
import '../../services/user_service.dart';
import '../../widgets/common_widgets.dart';
import '../widgets/admin_widgets.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late final Stream<List<AppUser>> _users;
  late final Stream<List<AppOrder>> _orders;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _users = context.read<UserService>().watchAllUsers();
    _orders = context.read<OrderService>().watchAllOrders();
  }

  Future<void> _toggleRole(AppUser u) async {
    final makeAdmin = !u.isAdmin;
    final ok = await confirm(
      context,
      makeAdmin ? 'Grant admin access?' : 'Remove admin access?',
      makeAdmin
          ? '${u.email} will be able to sign in to this dashboard and manage the store.'
          : '${u.email} will become a regular user.',
      action: makeAdmin ? 'Make admin' : 'Remove admin',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<UserService>().setRole(u.uid, makeAdmin ? 'admin' : 'user');
      if (mounted) showSnack(context, 'Updated ${u.email}');
    } catch (e) {
      if (mounted) showSnack(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<Session>().uid;
    return StreamBuilder<List<AppOrder>>(
      stream: _orders,
      builder: (context, oSnap) => StreamBuilder<List<AppUser>>(
        stream: _users,
        builder: (context, snap) {
          if (snap.hasError) return ErrorView(snap.error!);
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final orders = oSnap.data ?? const <AppOrder>[];
          final users = snap.data!.where((u) =>
              _query.isEmpty || u.name.toLowerCase().contains(_query) || u.email.toLowerCase().contains(_query)).toList();

          return ListView(children: [
            PageHeader(
              title: 'Users',
              subtitle: '${snap.data!.length} registered accounts',
              actions: [
                SizedBox(
                  width: 260,
                  child: TextField(
                    decoration: const InputDecoration(hintText: 'Search name or email', prefixIcon: Icon(Icons.search), isDense: true),
                    onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
            TableCard(
              table: DataTable(
                headingRowColor: WidgetStatePropertyAll(Colors.grey.shade50),
                columns: const [
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Phone')),
                  DataColumn(label: Text('Joined')),
                  DataColumn(label: Text('Orders'), numeric: true),
                  DataColumn(label: Text('Total spent'), numeric: true),
                  DataColumn(label: Text('Role')),
                ],
                rows: [
                  for (final u in users)
                    () {
                      final mine = orders.where((o) => o.userId == u.uid && o.status != OrderStatus.cancelled);
                      final spent = mine.fold<double>(0, (s, o) => s + o.total);
                      return DataRow(cells: [
                        DataCell(Text(u.name.isEmpty ? '—' : u.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(Text(u.email)),
                        DataCell(Text(u.phone.isEmpty ? '—' : u.phone)),
                        DataCell(Text(dateTime(u.createdAt))),
                        DataCell(Text('${mine.length}')),
                        DataCell(Text(money(spent))),
                        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                          Chip(
                            label: Text(u.isAdmin ? 'Admin' : 'User'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: u.isAdmin ? Colors.purple.shade50 : null,
                          ),
                          if (u.uid != myUid)
                            IconButton(
                              tooltip: u.isAdmin ? 'Remove admin' : 'Make admin',
                              icon: Icon(u.isAdmin ? Icons.remove_moderator_outlined : Icons.add_moderator_outlined),
                              onPressed: () => _toggleRole(u),
                            ),
                        ])),
                      ]);
                    }(),
                ],
              ),
            ),
          ]);
        },
      ),
    );
  }
}
