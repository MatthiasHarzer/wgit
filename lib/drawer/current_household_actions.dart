import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

import '../../types/household.dart';
import '../util/components.dart';
import '../util/util.dart';
import '../views/household/manage_members_view.dart';

final getIt = GetIt.I;

class DrawerCurrentHouseHoldActions extends StatefulWidget {
  final HouseHold houseHold;
  final VoidCallback onAddActivityTapped;

  const DrawerCurrentHouseHoldActions(
      {required this.houseHold, required this.onAddActivityTapped, Key? key})
      : super(key: key);

  @override
  State<DrawerCurrentHouseHoldActions> createState() =>
      _DrawerCurrentHouseHoldActionsState();
}

class _DrawerCurrentHouseHoldActionsState
    extends State<DrawerCurrentHouseHoldActions> {
  HouseHold get houseHold => widget.houseHold;
  final firebaseService = getIt<FirebaseService>();
  bool working = false;

  void _leaveHouseholdTapped() async {
    if(working) return;
    bool alone = houseHold.membersSnapshot.length == 1;
    bool isOnlyAdmin = houseHold.thisUserIsTheOnlyAdmin;

    setState(() {
      working = true;
    });

    if(!alone){
      if(isOnlyAdmin){
        /// Can't leave when user is the only admin
        var dialog = ConfirmDialog(
            context: context,
            title: "You can't leave a household where you are the only admin. You can promote a member from the members list.",
            confirm: "OPEN MEMBERS",
          cancel: "NEVER MIND",

        )..show();
        bool shouldOpenMembersList = await dialog.future;
        if(shouldOpenMembersList && mounted){
          Navigator.push(
            context,
            Util.createScaffoldRoute(
              view: ManageMembersView(
                houseHold: houseHold,
              ),
            ),
          );
        }
      }else{
        /// Leave
        var dialog = ConfirmDialog(
          context: context,
          title: "Do you want to leave \"${houseHold.name}\"?",
          confirm: "LEAVE",
        )..show();
        bool confirm = await dialog.future;

        if(confirm){
          await firebaseService.leaveHousehold(houseHold);
        }
      }
    }else{
      /// delete
      var dialog = ConfirmDialog(
                context: context,
                title: "You are the only member. This will delete the household \"${houseHold.name}\"!",
                confirm: "DELETE",
              )..show();
              bool confirm = await dialog.future;

              if(confirm){
                await firebaseService.deleteHouseHold(houseHold);
              }
      // return;
    }

    if(mounted){
      setState(() {
        working = false;
      });
    }

  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: TextButton(
            onPressed: _leaveHouseholdTapped,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Visibility(
                  visible: working,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.0),
                    child: SizedBox.square(
                      dimension: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ),
                Text("LEAVE THIS HOUSEHOLD", style: TextStyle(
                  color: Colors.red[700]
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
