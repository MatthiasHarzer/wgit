import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:wgit/drawer/current_household_actions.dart';
import 'package:wgit/drawer/sign_in_widget.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../services/types.dart';
import '../theme.dart';
import '../util/util.dart';
import 'households_widget.dart';

class MainPageDrawer extends StatefulWidget {
  final Function(HouseHold) onSwitchTo;
  final HouseHold? currentHouseHold;

  const MainPageDrawer(
      {required this.onSwitchTo, required this.currentHouseHold, Key? key})
      : super(key: key);

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
      margin: const EdgeInsets.only(left: 10),
      child: Text(
        title,
        style: AppTheme.drawerText,
      ),
    );
  }

  /// Builds an expandable drawer item
  Widget _buildExpandable({
    required String title,
    required Widget content,
  }) {
    return ExpandablePanel(
      theme: ExpandableThemeData(
        iconColor: Colors.grey[400],
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconPadding: const EdgeInsets.only(top: 13),
        iconRotationAngle: Util.degToRad(90),
        collapseIcon: Icons.keyboard_arrow_right,
        expandIcon: Icons.keyboard_arrow_right,
      ),
      header: SizedBox(
        height: 50,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title.toUpperCase(),
            style: AppTheme.drawerText,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      collapsed: Container(),
      expanded: content,
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
            Divider(
              color: Colors.grey[600],
              height: 5,
              thickness: 0.2,
            ),
            Visibility(
              visible: AuthService.signedIn,
              child: Column(children: [
                _buildExpandable(
                  title: "HOUSEHOLDS",
                  content: HouseholdsWidget(
                    onSwitchTo: _switchToHousehold,
                  ),
                ),
                Divider(
                  color: Colors.grey[600],
                  height: 1,
                  thickness: 0.2,
                ),
                if (widget.currentHouseHold != null)
                  _buildExpandable(
                    title: widget.currentHouseHold!.name,
                    content: DrawerCurrentHouseHoldActions(
                      houseHold: widget.currentHouseHold!,
                    ),
                  ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
