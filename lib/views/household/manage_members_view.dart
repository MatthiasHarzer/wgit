import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/theme.dart';

import '../../util/components.dart';

class ManageMembersView extends StatefulWidget {
  final HouseHold houseHold;

  const ManageMembersView({required this.houseHold, Key? key}) : super(key: key);

  @override
  State<ManageMembersView> createState() => _ManageMembersViewState();
}

class _ManageMembersViewState extends State<ManageMembersView> {
  HouseHold get houseHold => widget.houseHold;

  @override
  void initState(){
    super.initState();

    houseHold.onChange(() => {
      if(mounted){
        setState(() {})
      }
    });
  }

  /// Prompts the user to confirm the promotion and executes it
  void _promoteMemberTaped(AppUser member) async {
    var dialog = ConfirmDialog(
        context: context,
        title: "Promot ${member.displayName} to admin?",
        confirm: "PROMOTE")
      ..show();

    bool confirm = await dialog.future;

    if (confirm) {
      await FirebaseService.promoteMember(houseHold, member);
    }
  }

  /// Prompts the user to confirm the removal and runs it
  void _removeMemberTaped(AppUser member) async {
    var dialog = ConfirmDialog(
        context: context,
        title: "Remove ${member.displayName} to admin?",
        confirm: "REMOVE")
      ..show();

    bool confirm = await dialog.future;

    if (confirm) {
      await FirebaseService.removeMember(houseHold, member);
    }
  }

  /// Build a member item to promote / remove users in household
  Widget _buildMemberItem(AppUser member) {
    bool amIAdmin = houseHold.isUserAdmin(houseHold.thisUser);
    // print("Is user admin");
    bool isPromotable = !houseHold.isUserAdmin(member) && amIAdmin;
    bool isRemovable = member.uid != houseHold.thisUser.uid && amIAdmin;
    // isPromotable = true;
    return ListTile(
      leading: buildCircularAvatar(url: member.photoURL, dimension: 40),
      title: Text(member.displayName,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      subtitle: Text(houseHold.getUserRoleName(member)),
      trailing: Wrap(
        children: [
          MaterialButton(
            onPressed: isPromotable ? () => _promoteMemberTaped(member) : null,
            disabledTextColor: Colors.grey,
            child: const Text("PROMOTE"),
          ),
          IconButton(
            onPressed: isRemovable ? () => _removeMemberTaped(member) : null,
            icon: const Icon(Icons.remove_circle),
          )
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
          for (var member in houseHold.members) _buildMemberItem(member),
        ],
      ),
    );
  }
}
