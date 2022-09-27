import 'dart:async';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wgit/util/util.dart';

class ConfirmDialog {
  final BuildContext context;
  final String title;
  final String confirm;
  final String cancel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

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

class UserInputDialog {
  final BuildContext context;
  final String title;
  final String placeHolder;
  final String submit;
  final String cancel;
  final Function(String)? onSubmit;
  final VoidCallback? onCancel;

  final Completer<String?> _completer = Completer();
  String _inputText = "";
  TextInputType inputType;

  Future<String?> get future => _completer.future;

  UserInputDialog(
      {required this.context,
      required this.title,
      required this.placeHolder,
      this.cancel = "CANCEL",
      this.submit = "SUBMIT",
      this.onCancel,
      this.onSubmit,
      this.inputType = TextInputType.text,
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
          keyboardType: inputType,
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

/// An expandable list item with a title and an optional action
class ExpandableListItem extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? action;
  final bool initialExpanded;
  final bool toUpperCase;

  const ExpandableListItem({
    required this.title,
    required this.content,
    this.action,
    this.initialExpanded = false,
    this.toUpperCase = true,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ExpandableThemeData theme;

    /// Not ideal but with a custom expandable controller the icon wouldn't be reactive, so /shrug
    if (initialExpanded) {
      theme = ExpandableThemeData(
        iconColor: Colors.grey[300],
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconRotationAngle: Util.degToRad(-90),
        collapseIcon: Icons.keyboard_arrow_down,
        expandIcon: Icons.keyboard_arrow_down,
      );
    } else {
      theme = ExpandableThemeData(
        iconColor: Colors.grey[300],
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconRotationAngle: Util.degToRad(90),
        collapseIcon: Icons.keyboard_arrow_right,
        expandIcon: Icons.keyboard_arrow_right,
      );
    }

    Widget header = Text(
      toUpperCase ? title.toUpperCase() : title,
      style: TextStyle(
        color: Colors.grey[400],
        fontWeight: FontWeight.w500,
        fontSize: 16,
      ),
      overflow: TextOverflow.ellipsis,
      softWrap: true,
    );

    if (action != null) {
      header = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [header, action!],
      );
    }

    return ExpandablePanel(
      collapsed: initialExpanded ? content : Container(),
      theme: theme,
      header: SizedBox(
        height: 40,
        child: Align(
          alignment: Alignment.centerLeft,
          child: header,
        ),
      ),
      expanded: initialExpanded ? Container() : content,
    );
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

class AsyncQrImageLoader extends StatefulWidget {
  final Future<String> Function() contentLoader;
  final double qrCodeSize;
  final double spinnerSize;

  const AsyncQrImageLoader({
    required this.contentLoader,
    this.qrCodeSize = 220,
    this.spinnerSize = 45,
    Key? key,
  }) : super(key: key);

  @override
  State<AsyncQrImageLoader> createState() => _AsyncQrImageLoaderState();
}

class _AsyncQrImageLoaderState extends State<AsyncQrImageLoader> {
  String? _content;

  @override
  void initState() {
    super.initState();

    _loadAsync();
  }

  void _loadAsync() async {
    _content = await widget.contentLoader();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_content != null) {
      return Container(
        color: Colors.grey[200],
        child: Padding(
          padding: const EdgeInsets.all(1.0),
          child: SizedBox.square(
            dimension: widget.qrCodeSize,
            child: QrImage(data: _content!),
          ),
        ),
      );
    } else {
      return SizedBox.square(
        dimension: widget.spinnerSize,
        child: const CircularProgressIndicator(),
      );
    }
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
