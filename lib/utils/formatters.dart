import 'package:intl/intl.dart';

final _peso = NumberFormat.currency(locale: 'en_PH', symbol: '₱', decimalDigits: 2);
final _date = DateFormat('MMM d, yyyy • h:mm a');

String money(num value) => _peso.format(value);

String dateTime(DateTime? value) => value == null ? '—' : _date.format(value);

String shortId(String id) => id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
