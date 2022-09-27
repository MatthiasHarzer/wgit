import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/views/qr_code_scan_view.dart';

import '../../services/firebase/auth_service.dart';
import '../../util/components.dart';
import '../../util/util.dart';
import '../add_user_to_household_view.dart';

class ManageMembersView extends StatefulWidget {
  final HouseHold houseHold;

  const ManageMembersView({required this.houseHold, Key? key})
      : super(key: key);

  @override
  State<ManageMembersView> createState() => _ManageMembersViewState();
}

class _ManageMembersViewState extends State<ManageMembersView> {
  HouseHold get houseHold => widget.houseHold;

  @override
  void initState() {
    super.initState();

    houseHold.onChange(() => {
          if (mounted) {setState(() {})}
        });
  }

  void _openAddUserToHouseholdDialog(AppUser user) {
    Navigator.push(
      context,
      Util.createScaffoldRoute(
        view: AddUserToHouseholdView(
          user: user,
        ),
      ),
    );
  }

  void _resolveScannedUri(String uri)async{

    Future<bool> resolve(String uri) async{
      final PendingDynamicLinkData? dynLink =
      await FirebaseDynamicLinks.instance.getDynamicLink(Uri.parse(uri));
      if(dynLink == null) return false;
      AppUser? dynUser = await FirebaseService.resolveDynLinkUser(dynLink);
      if (dynUser == null) return false;
      if(dynUser.uid == AuthService.appUser?.uid) return false;
      _openAddUserToHouseholdDialog(dynUser);
      return true;
    }
    bool success = await resolve(uri);

    if(!success && mounted){
      Util.showSnackBar(context, content: const Text("Invalid QR code provided"));
    }

  }


  void _openQrCodeScanner() {
    Navigator.push(
      context,
      Util.createScaffoldRoute(view: QrCodeScanView(onRead: _resolveScannedUri, title: "Scan a users QR code"))
    );
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
        title: "Remove ${member.displayName} from ${houseHold.name}?",
        confirm: "REMOVE")
      ..show();

    bool confirm = await dialog.future;

    if (confirm) {
      await FirebaseService.removeMember(houseHold, member);
    }
  }

  /// Build a member item to promote / remove users in household
  Widget _buildMemberItem(AppUser member) {
    bool amIAdmin = houseHold.thisUserIsAdmin;
    // print("Is user admin");
    bool isMe = member.uid == houseHold.thisUser.uid;
    bool isAdmin = houseHold.isUserAdmin(member);
    bool isPromotable = !isAdmin && amIAdmin;
    bool isRemovable = amIAdmin && !isMe;
    // bool isDemotable = amIAdmin && !isMe && isAdmin;
    // isPromotable = true;
    return ListTile(
      leading: buildCircularAvatar(url: member.photoURL, dimension: 40),
      title: Text(member.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      subtitle: Text(houseHold.getUserRoleName(member)),
      trailing: Wrap(
        children: [
          TextButton(
            onPressed: isPromotable ? () => _promoteMemberTaped(member) : null,
            child: const Text("PROMOTE"),
          ),
          IconButton(
            onPressed: isRemovable ? () => _removeMemberTaped(member) : null,
            icon: const Icon(Icons.remove_circle),
            tooltip: "Remove User",
            splashRadius: 25,
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
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: _openQrCodeScanner,
                child: const Text("ADD MEMBER"),
              ),
            ),
          )
        ],
      ),
    );
  }
}
