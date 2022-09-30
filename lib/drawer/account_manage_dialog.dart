import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

import '../services/firebase/auth_service.dart';
import '../util/components.dart';

class AccountManageDialog extends StatefulWidget {
  const AccountManageDialog({Key? key}) : super(key: key);

  @override
  State<AccountManageDialog> createState() => _AccountManageDialogState();
}

class _AccountManageDialogState extends State<AccountManageDialog> {
  bool working = false;
  String _displayName = "";

  void _signOutPressed() async {
    if (working) return;

    setState(() {
      working = true;
    });

    var dialog = ConfirmDialog(
        context: context,
        title: "Are you sure you want to sign out?",
        confirm: "SIGN OUT")
      ..show();
    bool confirm = await dialog.future;

    if (confirm) {
      _close();
      await AuthService.signOut();
      // snackBarText = "Successfully signed out";
    }

    setState(() {
      working = false;
    });

  }

  void _savePressed() async {
    if (working) return;

    setState(() {
      working = true;
    });

    if(_displayName.isNotEmpty){
      await FirebaseService.modifyUser(uid: AuthService.appUser!.uid, displayName: _displayName);
    }

    setState(() {
      working = false;
    });
    _close();
  }

  void _close() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("You Account"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            initialValue: AuthService.appUser?.displayName,
            onChanged: (text) => _displayName = text,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: "Display Name",
            ),
          )
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _signOutPressed,
              child: Text(
                "SIGN OUT",
                style: TextStyle(
                    color: Colors.red[500], fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: _savePressed,
              child: Row(
                children: [
                  Visibility(
                    visible: working,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    "SAVE",
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }
}
