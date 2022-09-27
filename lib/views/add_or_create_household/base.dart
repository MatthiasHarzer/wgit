import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';

import '../../util/components.dart';

class JoinOrCreateHouseholdView extends StatefulWidget {
  final Function(HouseHold) onFinished;

  const JoinOrCreateHouseholdView({required this.onFinished, Key? key})
      : super(key: key);

  @override
  State<JoinOrCreateHouseholdView> createState() =>
      _JoinOrCreateHouseholdViewState();
}

class _JoinOrCreateHouseholdViewState extends State<JoinOrCreateHouseholdView> {
  ThemeData get theme => Theme.of(context);

  TextStyle get buttonStyle => TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 18,
      );

  void _onCreateConfirm(String name) async {
    if (name.isEmpty) return;
    HouseHold? household = await FirebaseService.createHousehold(name);
    if (household != null) {
      if (mounted) {
        Navigator.pop(context);
      }
      widget.onFinished(household);
    } else {
      print("An error occurred creating household $name");
    }
  }

  void _onCreate() {
    var dialog = UserInputDialog(
        context: context,
        title: "Please enter a name for the household",
        placeHolder: "Household Name",
        onSubmit: _onCreateConfirm)
      ..show();
  }

  Widget _buildQrCodeJoinDialog(BuildContext ctx) {
    return AlertDialog(
      title: Text(
        "An admin of a household can scan this QR code to add you to it.",
        textAlign: TextAlign.left,
        style: TextStyle(
            fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey[300]),
      ),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AsyncQrImageLoader(
            contentLoader: AuthService.appUser!.getDynLink,
          )
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(ctx);
          },
          child: const Text("CLOSE"),
        ),
      ],
    );
  }

  void _onJoin() {
    showDialog(context: context, builder: (ctx) => _buildQrCodeJoinDialog(ctx));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: const Text("Join Or Create Household"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Do you want to join or create a new household?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(onPressed: _onCreate, child: const Text("CREATE")),
                TextButton(onPressed: _onJoin, child: const Text("JOIN")),
              ],
            )
          ],
        ),
      ),
    );
  }
}
