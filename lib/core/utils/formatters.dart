import 'package:intl/intl.dart';

class Formatters {
  const Formatters._();

  static final DateFormat _date = DateFormat('d MMM yyyy', 'id_ID');
  static final DateFormat _longDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID');

  static String date(DateTime value) => _date.format(value);

  static String longDate(DateTime value) => _longDate.format(value);

  static String initials(String value) {
    final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  static String relativeDue(DateTime dueDate) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final days = end.difference(start).inDays;

    if (days == 0) return 'Jatuh tempo hari ini';
    if (days == 1) return 'Jatuh tempo besok';
    if (days > 1) return '$days hari lagi';
    if (days == -1) return 'Terlambat 1 hari';
    return 'Terlambat ${days.abs()} hari';
  }
}
