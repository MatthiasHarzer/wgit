import 'package:flutter/material.dart';
import 'package:wgit/services/types.dart';

import '../../util/components.dart';

class HouseHoldMembersSnippet extends StatelessWidget {
  final HouseHold houseHold;

  const HouseHoldMembersSnippet({required this.houseHold, Key? key})
      : super(key: key);

  List<AppUser> get members => houseHold.members;


  ///
  Widget _buildUserSnippet(AppUser member) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 150
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildCircularAvatar(url: member.photoURL, dimension: 55),
            Column(
              children: [Text(member.displayName, textAlign: TextAlign.center,)],
            )
          ],
        ),
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
            for (var user in members) _buildUserSnippet(user)
          ],
        ),
      ),
    );
  }
}
