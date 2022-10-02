import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../services/types.dart';
import 'account_manage_dialog.dart';

final getIt = GetIt.I;

class AccountWidget extends StatefulWidget {
  const AccountWidget({Key? key}) : super(key: key);

  @override
  State<AccountWidget> createState() => _AccountWidgetState();
}

class _AccountWidgetState extends State<AccountWidget> {
  final authService = getIt<NewAuthService>();

  @override
  void initState() {
    super.initState();

    AppUser.onUpdated(() {
      if (mounted) {
        setState(() {});
      }
    });

    // AuthService.onWorkingUpdate((w) {
    //   print("MOUNTED $mounted with working: $w");
    //   if (mounted) {
    //     setState(() {
    //       working = w;
    //     });
    //   }
    // });
    //
    // AuthService.stateChange.listen((e) {
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });
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
    return SizedBox.square(
      dimension: size,
      child: StreamBuilder(
        stream: authService.authStateStream,
        builder: (context, snapshot) {
          final state = snapshot.data ?? AuthState.signedOut;
          final user = authService.currentUser;
          switch (state) {
            case AuthState.signedIn:
            case AuthState.signedOut:
              return user == null
                  ? Icon(
                Icons.account_circle_outlined,
                size: size,
              )
                  : CircleAvatar(
                backgroundColor: Colors.grey[800],
                radius: 45,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: ClipOval(
                    child: Image.network(
                      user.photoURL,
                    ),
                  ),
                ),
              );
            case AuthState.signingIn:
            case AuthState.signingOut:
              return const Padding(
                  padding: EdgeInsets.all(5), child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  /// Generates the trailing widget (manage button if signed in)
  // Widget _buildTrailing() {
  //   if (!AuthService.signedIn) {
  //     return const SizedBox.square(
  //       dimension: 1,
  //     );
  //   } else {
  //     return TextButton(
  //       onPressed: _manageAccountTapped,
  //       child: const Text("MANAGE"),
  //     );
  //   }
  // }

  /// Generates the title for the list tile
  Widget _buildTitle() {
    return StreamBuilder(
      stream: authService.authStateStream,
      builder: (context, snapshot) {
        String text;
        switch (snapshot.data) {
          case AuthState.signedIn:
            text = authService.currentUser?.displayName ?? "";
            break;
          case AuthState.signedOut:
            text = "Not Signed Im";
            break;
          case AuthState.signingIn:
          case AuthState.signingOut:
            text = "Working on it";
            break;
          default:
            text = "An unexpected error occurred";
        }

        return Text(
          text,
          softWrap: true,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18),
        );
      },
    );
  }

  /// Generates the subtitle for the list tile
  Widget _buildSubtitle() {
    return StreamBuilder(
      stream: authService.authStateStream,
      builder: (context, snapshot) {
        String text;
        switch (snapshot.data) {
          case AuthState.signedIn:
            text = "Tap to manage account";
            break;
          case AuthState.signedOut:
            text = "Tap to sign in";
            break;
          case AuthState.signingIn:
            text = "Signing you in...";
            break;
          case AuthState.signingOut:
            text = "Signing you out...";
            break;
          default:
            text = "Unexpected Auth State";
        }
        return Text(text);
      },
    );
  }

  /// Signes the user in or out, depending on current state
  void _handleTap() async {
    String snackBarText;
    if (authService.signedIn) {
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
      bool success = await authService.signInWithGoogle();
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
      onTap: _handleTap,
    );
  }
}
