
import 'package:flutter/material.dart';
import 'package:wgit/services/app_management_service.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../util/util.dart';

class SignInWidget extends StatefulWidget {
  const SignInWidget({Key? key}) : super(key: key);

  @override
  State<SignInWidget> createState() => _SignInWidgetState();
}

class _SignInWidgetState extends State<SignInWidget> {
  bool working = false;

  /// Generates the leading widget for the list tile
  Widget _getLeading() {
    double size = 43;
    Widget widget;
    if (working) {
      widget = const Padding(
            padding: EdgeInsets.all(5),
          child: CircularProgressIndicator());
    } else if (AuthService.signedIn) {
      widget = CircleAvatar(
        backgroundColor: Colors.grey[800],
        radius: 45,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: ClipOval(
              child: Image.network(
                AuthService.user!.photoURL!,
              )),
        ),
      );
    } else {
      widget = Icon(Icons.account_circle_outlined, size: size,);
    }
    return SizedBox.square(
      dimension: size,
      child: widget,
    );
  }

  /// Generates the title for the list tile
  Widget _getTitle() {
    String text;
    if (working) {
      text = "Working on it";
    } else if (AuthService.signedIn) {
      text = AppManager.currentUser!.displayName;
    } else {
      text = "Not Signed In";
    }
    return Text(text, softWrap: true,
      overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize:  18),);
  }

  /// Generates the subtitle for the list tile
  Widget _getSubtitle() {
    String text;
    if (working) {
      text = "Signing you in...";
    } else if (AuthService.signedIn) {
      text = "Tap to sign out";
    } else {
      text = "Tap to sign in";
    }
    return Text(text);
  }

  /// Signes the user in or out, depending on current state
  void _handleTap() async {
    setState(() {
      working = true;
    });



    String snackBarText;
    if (AuthService.signedIn) {
      await AuthService.signOut();
      snackBarText = "Successfully signed out";
    } else {
      bool success = await AuthService.signInWithGoogle();
      snackBarText = success
          ? "Signed in as ${AuthService.user!.displayName}"
          : "Failed to sign int";
    }

    if(!mounted) return;

    // Util.showSnackBar(context, content: Text(snackBarText));

    setState(() {
      working = false;
    });

    // Navigator.pop(context);
  }


  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _getTitle(),
      subtitle: _getSubtitle(),
      leading: _getLeading(),
      onTap: working ? null : _handleTap,
    );
  }
}
