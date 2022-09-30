import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../services/firebase/firebase_service.dart';
import '../services/types.dart';
import '../util/components.dart';
import 'account_manage_dialog.dart';

class AccountWidget extends StatefulWidget {
  const AccountWidget({Key? key}) : super(key: key);

  @override
  State<AccountWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  bool working = false;
  bool oldSignedIn = false;

  @override
  void initState() {
    super.initState();
    working = false;

    AppUser.onUpdated(() {
      if(mounted){
        setState(() {

        });
      }
    });

    AuthService.onWorkingUpdate((w) {
      print("MOUNTED $mounted with working: $w");
      if (mounted) {
        setState(() {
          working = w;
        });
      }
    });

    AuthService.stateChange.listen((e) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _manageAccountTapped() {
    showDialog(
      context: context,
      builder: (context) => const AccountManageDialog(),
    );
  }

  /// Generates the leading widget for the list tile
  Widget _buildLeading() {
    double size = 43;
    Widget widget;
    if (working) {
      widget = const Padding(
          padding: EdgeInsets.all(5), child: CircularProgressIndicator());
    } else if (AuthService.signedIn) {
      widget = CircleAvatar(
        backgroundColor: Colors.grey[800],
        radius: 45,
        child: Padding(
          padding: const EdgeInsets.all(2.0),
          child: ClipOval(
              child: Image.network(
            FirebaseService.user!.photoURL,
          )),
        ),
      );
    } else {
      widget = Icon(
        Icons.account_circle_outlined,
        size: size,
      );
    }
    return SizedBox.square(
      dimension: size,
      child: widget,
    );
  }

  /// Generates the trailing widget (manage button if signed in)
  Widget _buildTrailing() {
    if (!AuthService.signedIn) {
      return const SizedBox.square(
        dimension: 1,
      );
    } else {
      return TextButton(
        onPressed: _manageAccountTapped,
        child: const Text("MANAGE"),
      );
    }
  }

  /// Generates the title for the list tile
  Widget _buildTitle() {
    String text;
    if (working) {
      text = "Working on it";
    } else if (AuthService.signedIn) {
      text = FirebaseService.user!.displayName;
    } else {
      text = "Not Signed In";
    }
    return Text(
      text,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 18),
    );
  }

  /// Generates the subtitle for the list tile
  Widget _buildSubtitle() {
    String text;
    if (working) {
      if (oldSignedIn) {
        text = "Signing you out...";
      } else {
        text = "Signing you in...";
      }
    } else if (AuthService.signedIn) {
      text = "Tap to manage account";
    } else {
      text = "Tap to sign in";
    }
    return Text(text);
  }

  /// Signes the user in or out, depending on current state
  void _handleTap() async {
    String snackBarText;
    oldSignedIn = AuthService.signedIn;
    if (AuthService.signedIn) {
      // var dialog = ConfirmDialog(
      //     context: context,
      //     title: "Are you sure you want to sign out?",
      //     confirm: "SIGN OUT")
      //   ..show();
      // bool confirm = await dialog.future;
      //
      // if (confirm) {
      //   await AuthService.signOut();
      //   snackBarText = "Successfully signed out";
      // }
      _manageAccountTapped();
    } else {
      bool success = await AuthService.signInWithGoogle();
    }

    if (!mounted) return;

    // Util.showSnackBar(context, content: Text(snackBarText));

    // Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: _buildTitle(),
      subtitle: _buildSubtitle(),
      leading: _buildLeading(),
      // trailing: _buildTrailing(),
      onTap: working ? null : _handleTap,
    );
  }
}
