import 'package:flutter/material.dart';
import 'package:wgit/services/types.dart';

import '../../util/components.dart';

class HouseHoldMembersSnippet extends StatelessWidget {
  final HouseHold houseHold;

  const HouseHoldMembersSnippet({required this.houseHold, Key? key})
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Row(
          children: [
            for (var user in mulitply(members, 10)) _buildUserSnippet(user)
          ],
        ),
      ),
    );
  }
}
