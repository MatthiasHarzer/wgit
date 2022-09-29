import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

final oCcy = NumberFormat("0.00", "en_US");

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

  static double degToRad(double degree) {
    return degree * (pi / 180);
  }

  static runDelayed(VoidCallback cb, Duration delay) async {
    await Future.delayed(delay);
    cb();
  }

  static String formatAmount(double m) {
    // return m.toString();
    return oCcy.format(m);
    m = double.parse(m.toStringAsFixed(2));
    int l = m.toInt().toString().length + 3;
    return m.toString().padRight(l, "0");
  }

  static List mulitply(List m, int n) {
    List u = [];
    for (int i = 0; i < n; i++) {
      u.addAll([...m]);
    }
    return u;
  }

  /// Makes a request to the give [url] and returns the body as json
  static Future<Map<String, dynamic>> makeRequest({required String url}) async {
    final res = await http.get(Uri.parse(url));

    if(res.statusCode == 200){
      return jsonDecode(res.body);
    }else{
      throw Exception('Failed to request $url');
    }
  }
}
