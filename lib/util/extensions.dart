

import 'package:intl/intl.dart';

var _formatter = DateFormat('d LLL yyyy kk:mm');
extension DateTimeFormatter on DateTime{
  String get formatted{
    return  _formatter.format(this);
  }
}