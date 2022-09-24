import 'dart:async';

import 'package:flutter/material.dart';

class ConfirmDialog {
  final BuildContext context;
  final String title;
  final String confirm;
  final String cancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  ThemeData get _theme => Theme.of(context);
  final double _buttonSize = 18;
  final Completer<bool> _completer = Completer();

  Future<bool> get future => _completer.future;

  ConfirmDialog(
      {required this.context,
      required this.title,
      this.cancel = "CANCEL",
      this.confirm = "CONFIRM",
      this.onCancel,
      this.onConfirm,
      Key? key});

  void _onConfirm() {
    if (onConfirm != null) onConfirm!();
    _completer.complete(true);
    Navigator.pop(context);
  }

  void _onCancel() {
    if (onCancel != null) onCancel!();
    _completer.complete(false);
    Navigator.pop(context);
  }

  Widget get widget => AlertDialog(
        title: Text(
          title,
          textAlign: TextAlign.left,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.grey[300]),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MaterialButton(
                  onPressed: _onCancel,
                  child: Text(cancel,
                      style: TextStyle(
                          color: _theme.colorScheme.primary,
                          fontSize: _buttonSize))),
              MaterialButton(
                  onPressed: _onConfirm,
                  child: Text(
                    confirm,
                    style: TextStyle(
                        color: _theme.colorScheme.primary,
                        fontSize: _buttonSize),
                  )),
            ],
          ),
        ],
      );

  void show() {
    showDialog(context: context, builder: (ctx) => widget);
  }
}
