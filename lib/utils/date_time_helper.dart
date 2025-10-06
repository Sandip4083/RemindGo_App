import 'package:intl/intl.dart';

String formatDateTime(DateTime dt) {
  return DateFormat.yMMMd().add_jm().format(dt);
}
