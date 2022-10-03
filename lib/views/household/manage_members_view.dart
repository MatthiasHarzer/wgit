import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/views/qr_code_scan_view.dart';

import '../../util/components.dart';
import '../../util/util.dart';
import '../add_user_to_household_view.dart';

final getIt = GetIt.I;

class ManageMembersView extends StatefulWidget {
  final HouseHold houseHold;

  const ManageMembersView({required this.houseHold, Key? key})
      : super(key: key);

  @override
  State<ManageMembersView> createState() => _ManageMembersViewState();
}

class _ManageMembersViewState extends State<ManageMembersView> {
  HouseHold get houseHold => widget.houseHold;
  final authService = getIt<NewAuthService>();
  final firebaseService = getIt<FirebaseService>();

  @override
  void initState() {
    super.initState();

    // houseHold.onChange(() =>
    // {
    //   if (mounted) {setState(() {})}
    // });

    // getIt.get<NewAuthService>().authStream.listen((event) {
    //   print("AUTHSTREAM EVENT 3");
    //   print(event);
    //   print("----");
    // });
  }


  /// Tries
  void _resolveScannedUri(String uri) async {
    // if(kIsWeb) return
    Future<AppUser?> resolve2(String uri) async {
      try {
        AppUser? dynUser = await firebaseService.resolveShortDynLinkUser(uri);
        if (dynUser == null) return null;
        // if (dynUser.uid == AuthService.appUser?.uid) return null;
        return dynUser;
      } catch (e) {
        print(e);
        return null;
      }
    }


    AppUser? user = await resolve2(uri);
    bool success = user != null;

    if (!mounted) return;

    if (!success) {
      Util.showSnackBar(context,
          content: const Text("Invalid QR code provided"));
    } else if (user == authService.currentUser){
      Util.showSnackBar(context,
          content: const Text("You can't add yourself to a household!"));
    }

    if(!success) return;

    Navigator.push(
      context,
      Util.createScaffoldRoute(
        view: AddUserToHouseholdView(
          user: user,
          initialHousehold: houseHold,
        ),
      ),
    );
  }

  void _openQrCodeScanner() async {
    if (kIsWeb && false) {
      var dialog = UserInfoDialog(
        context: context,
        title: "This operation is currently not supported on the web version!",
        subtitle: "You can use the mobile app to add members.",
      )
        ..show();
      await dialog.future;
    } else {
      Navigator.push(
        context,
        Util.createScaffoldRoute(
          view: QrCodeScanView(
              onRead: _resolveScannedUri, title: "Scan a users QR code"),
        ),
      );
    }
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
      await firebaseService.promoteMember(houseHold, member);
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
      await firebaseService.removeMember(houseHold, member);
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
      body: StreamBuilder(
        stream: houseHold.membersStream,
        builder: (context, snapshot) {
          final members = snapshot.data ?? [];
          return ListView(
            children: [
              for (var member in members) _buildMemberItem(member),
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
          );
        }
      ),
    );
  }
}
