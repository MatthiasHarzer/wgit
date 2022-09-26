import 'dart:math';

import 'package:flutter/material.dart';

class Util {
  /// Hides the current snackbar
  static void hideSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  /// Shows a snackbar
  static void showSnackBar(BuildContext context,
      {required Widget content, SnackBarAction? action, int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        action: action,
        content: content,
        duration: Duration(seconds: seconds),
      ),
    );
  }

  /// Creates a scaffold route with transition to the given scaffold view
  static Route createScaffoldRoute({required Widget view}) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => view,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  static double degToRad(double degree){
    return degree * (pi / 180);
  }

  static runDelayed(VoidCallback cb, Duration delay) async{
    await Future.delayed(delay);
    cb();
  }

  static String formatAmount(double m){
    m = double.parse(m.toStringAsFixed(2));
    int l = m.toInt().toString().length + 3;
    return m.toString().padRight(l, "0");
  }


}
