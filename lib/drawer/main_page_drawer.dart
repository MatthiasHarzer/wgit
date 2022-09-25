import 'package:flutter/material.dart';
import 'package:wgit/drawer/sign_in_widget.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import '../services/types.dart';

import '../theme.dart';
import 'households_widget.dart';

class MainPageDrawer extends StatefulWidget {
  final Function(HouseHold) onSwitchTo;

  const MainPageDrawer({required this.onSwitchTo, Key? key}) : super(key: key);

  @override
  State<MainPageDrawer> createState() => _MainPageDrawerState();
}

class _MainPageDrawerState extends State<MainPageDrawer> {
  final TextStyle headerTextStyle = TextStyle(
    color: Colors.grey[300],
    fontWeight: FontWeight.w500,
  );

  @override
  void initState() {
    super.initState();

    AuthService.stateChange.listen((event) {
      setState(() {});
    });
  }

  void _switchToHousehold(HouseHold houseHold) {
    Navigator.pop(context);
    widget.onSwitchTo(houseHold);
  }

  /// Builds a header widget for the drawer
  Widget _buildHeader(String title) {
    title = title.toUpperCase();
    return Container(
      margin: const EdgeInsets.only(left: 10, top: 5),
      child: Text(
        title,
        style: AppTheme.drawerText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.grey[900]),
      child: Drawer(
        child: ListView(
          primary: true,
          padding: EdgeInsets.zero,
          children: [
            Container(
              color: Colors.grey[850],
              height: 80,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(top: 25, left: 25),
                  child: const Text(
                    "WG IT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
            const SignInWidget(),
            const Divider(),
            Visibility(
              visible: AuthService.signedIn,
              child: HouseholdsWidget(
                header: _buildHeader("Households"),
                onSwitchTo: _switchToHousehold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
