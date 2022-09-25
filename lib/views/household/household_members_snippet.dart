import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/types.dart';

import '../../theme.dart';
import '../../util/util.dart';

class HouseHoldMembersSnippet extends StatelessWidget {
  final HouseHold houseHold;
  final VoidCallback onManageTap;

  const HouseHoldMembersSnippet(
      {required this.houseHold, required this.onManageTap, Key? key})
      : super(key: key);

  List<HouseHoldMember> get members => houseHold.members;

  List mulitply(List m, int n) {
    List u = [];
    for (int i = 0; i < n; i++) {
      u.addAll([...m]);
    }
    return u;
  }

  ///
  Widget _buildUserSnippet(HouseHoldMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 55,
            child: CircleAvatar(
              backgroundColor: Colors.grey[800],
              radius: 45,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: ClipOval(
                    child: Image.network(
                  member.user.photoURL,
                )),
              ),
            ),
          ),
          Column(
            children: [Text(member.user.displayName)],
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
                  fontSize: 18,
                ),
              ),
              if (houseHold.thisUser.isAdmin)
                MaterialButton(
                  onPressed: onManageTap,
                  child: Text(
                    "MANAGE",
                    style: AppTheme.materialButtonLabelStyle,
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
