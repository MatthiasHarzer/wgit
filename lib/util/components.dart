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
              fontSize: 20,
              color: Colors.grey[300]),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _onCancel,
                child: Text(
                  cancel,
                ),
              ),
              TextButton(
                onPressed: _onConfirm,
                child: Text(
                  confirm,
                ),
              ),
            ],
          ),
        ],
      );

  void show() {
    showDialog(context: context, builder: (ctx) => widget);
  }
}

class UserTextInputDialog {
  final BuildContext context;
  final String title;
  final String placeHolder;
  final String submit;
  final String cancel;
  final Function(String)? onSubmit;
  final VoidCallback? onCancel;

  ThemeData get _theme => Theme.of(context);
  final double _buttonSize = 18;
  final Completer<String?> _completer = Completer();
  String _inputText = "";

  Future<String?> get future => _completer.future;

  UserTextInputDialog(
      {required this.context,
      required this.title,
      required this.placeHolder,
      this.cancel = "CANCEL",
      this.submit = "SUBMIT",
      this.onCancel,
      this.onSubmit,
      Key? key});

  void _onSubmit() {
    if (onSubmit != null) onSubmit!(_inputText);
    _completer.complete(_inputText);
    Navigator.pop(context);
  }

  void _onCancel() {
    if (onCancel != null) onCancel!();
    _completer.complete(null);
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
        content: TextFormField(
          onChanged: (text) => _inputText = text,
          decoration: InputDecoration(
            border: const UnderlineInputBorder(),
            labelText: placeHolder,
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: _onCancel,
                child: Text(
                  cancel,
                ),
              ),
              TextButton(
                onPressed: _onSubmit,
                child: Text(
                  submit,
                ),
              ),
            ],
          ),
        ],
      );

  void show() {
    showDialog(context: context, builder: (ctx) => widget);
  }
}

/// Displays a given text with an aciton button
class InfoActionWidget extends StatelessWidget {
  final String label;
  final String buttonText;
  final VoidCallback onTap;

  const InfoActionWidget(
      {required this.label,
      required this.buttonText,
      required this.onTap,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            buttonText,
          ),
        ),
      ],
    );
  }
}

Widget buildCircularAvatar({required String url, required double dimension}) {
  return SizedBox.square(
    dimension: dimension,
    child: CircleAvatar(
      backgroundColor: Colors.grey[800],
      radius: 45,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: ClipOval(
            child: Image.network(
          url,
        )),
      ),
    ),
  );
}
