import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/types.dart';

import '../../theme.dart';
import '../../util/components.dart';
import '../../util/util.dart';

class HouseHoldMembersSnippet extends StatelessWidget {
  final HouseHold houseHold;
  final VoidCallback onManageTap;

  const HouseHoldMembersSnippet(
      {required this.houseHold, required this.onManageTap, Key? key})
      : super(key: key);

  List<AppUser> get members => houseHold.members;

  List mulitply(List m, int n) {
    List u = [];
    for (int i = 0; i < n; i++) {
      u.addAll([...m]);
    }
    return u;
  }

  ///
  Widget _buildUserSnippet(AppUser member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildCircularAvatar(url: member.photoURL, dimension: 55),
          Column(
            children: [Text(member.displayName)],
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // print(houseHold.thisUser.isAdmin)
    return ExpandablePanel(
      collapsed: Container(),
      theme: ExpandableThemeData(
        iconColor: Colors.white,
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconRotationAngle: Util.degToRad(90),
        collapseIcon: Icons.keyboard_arrow_right,
        expandIcon: Icons.keyboard_arrow_right,
      ),
      header: SizedBox(
        height: 40,
        child: Align(
          // alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "MEMBERS",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              if (houseHold.isUserAdmin(houseHold.thisUser))
                TextButton(
                  onPressed: onManageTap,
                  child: const Text(
                    "MANAGE",
                  ),
                ),
            ],
          ),
        ),
      ),
      expanded: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          child: Row(
            children: [
              for (var user in mulitply(members, 10)) _buildUserSnippet(user)
            ],
          ),
        ),
      ),
    );
  }
}
