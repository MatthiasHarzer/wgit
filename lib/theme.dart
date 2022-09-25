import 'package:flutter/material.dart';

late ThemeData theme;

class AppTheme {
  static TextStyle drawerText =
      TextStyle(color: Colors.grey[350], fontWeight: FontWeight.w500);

  static TextStyle materialButtonLabelStyle = TextStyle(
    color: theme.colorScheme.primary,
    fontSize: 18,
  );
}
