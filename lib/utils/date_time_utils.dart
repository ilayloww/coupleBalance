import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  static String formatTime(BuildContext context, DateTime dateTime) {
    final is24Hour = MediaQuery.of(context).alwaysUse24HourFormat;
    return is24Hour
        ? DateFormat('HH:mm').format(dateTime)
        : DateFormat('h:mm a').format(dateTime);
  }
}
