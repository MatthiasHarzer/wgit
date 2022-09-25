import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/theme.dart';

import '../../util/components.dart';

class MembersView extends StatefulWidget {
  final HouseHold houseHold;

  const MembersView({required this.houseHold, Key? key}) : super(key: key);

  @override
  State<MembersView> createState() => _MembersViewState();
}

class _MembersViewState extends State<MembersView> {
  HouseHold get houseHold => widget.houseHold;

  /// Prompts the user to confirm the promotion and executes it
  void _promoteMemberTaped(HouseHoldMember member) async{
    var dialog =
    ConfirmDialog(context: context, title: "Promot ${member.user.displayName} to admin?", confirm: "PROMOTE")..show();

    bool confirm = await dialog.future;

    if(confirm){
      await FirebaseService.promoteMember(houseHold, member);
    }
  }

  /// Prompts the user to confirm the removal and runs it
  void _removeMemberTaped(HouseHoldMember member) async{
    var dialog =
    ConfirmDialog(context: context, title: "Remove ${member.user.displayName} to admin?", confirm: "REMOVE")..show();

    bool confirm = await dialog.future;

    if(confirm){
      await FirebaseService.removeMember(houseHold, member);
    }
  }

  /// Build a member item to promote / remove users in household
  Widget _buildMemberItem(HouseHoldMember member) {
    bool isPromotable = !member.isAdmin && houseHold.thisUser.isAdmin;
    bool isRemovable = member.user.uid != houseHold.thisUser.user.uid &&
        houseHold.thisUser.isAdmin;
    // isPromotable = true;
    return ListTile(
      leading: buildCircularAvatar(url: member.user.photoURL, dimension: 40),
      title: Text(member.user.displayName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      subtitle: Text(member.role.toUpperCase()),
      trailing: Wrap(
        children: [
          MaterialButton(
            onPressed: isPromotable ? () => _promoteMemberTaped(member) : null,
            disabledTextColor: Colors.grey,
            child: const Text("PROMOTE"),

          ),
          IconButton(
            onPressed: isRemovable ? () => _removeMemberTaped(member) : null,
            icon: const Icon(Icons.remove_circle),)
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Members of \"${houseHold.name}\""),
      ),
      body: ListView(
        children: [
          for(var member in houseHold.members)
            _buildMemberItem(member),
        ],
      ),
    );
  }
}
