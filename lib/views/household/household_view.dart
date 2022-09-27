import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:wgit/util/components.dart';
import 'package:wgit/views/household/household_standings.dart';
import 'package:wgit/views/household/manage_members_view.dart';

import '../../services/types.dart';
import '../../util/util.dart';
import 'household_activities_view.dart';
import 'household_members_snippet.dart';

class HouseHoldView extends StatefulWidget {
  final HouseHold houseHold;

  const HouseHoldView({required this.houseHold, Key? key}) : super(key: key);

  @override
  State<HouseHoldView> createState() => _HouseHoldViewState();
}

class _HouseHoldViewState extends State<HouseHoldView> {
  HouseHold get houseHold => widget.houseHold;

  @override
  void initState() {
    super.initState();

    houseHold.onChange(() =>
    {
      if (mounted) {setState(() {})}
    });
  }

  Future _sendMoneyToMemberTapped(AppUser member) async {

    var dialog = UserInputDialog(
        context: context,
        title: "How much money did you exchange with ${member.displayName}?",
        inputType: TextInputType.number,
        placeHolder: "Amount",
      submit: "EXCHANGE",
    )..show();
    String retval = await dialog.future ?? "";
    double asDouble = double.tryParse(retval) ?? 0;

    print("SENDING $asDouble to ${member.displayName}");

    if(asDouble <= 0) return;

    await houseHold.exchangeMoney(from: houseHold.thisUser, to: member, amount: asDouble);
  }

  void _openMemberManagement() {
    print("OPEN MEMBER MANAGEMENT");
    Navigator.push(
      context,
      Util.createScaffoldRoute(
        view: ManageMembersView(
          houseHold: houseHold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ExpandableListItem(
          title: "MEMBERS",
          content: HouseHoldMembersSnippet(
            houseHold: houseHold,
          ),
          action: houseHold.isUserAdmin(houseHold.thisUser)
              ? TextButton(
            onPressed: _openMemberManagement,
            child: const Text(
              "MANAGE",
            ),
          )
              : null,
        ),
        const Divider(),
        ExpandableListItem(
          title: "STANDINGS",
          content: HouseHoldStandings(
            houseHold: houseHold,
            onMoneySendTap: _sendMoneyToMemberTapped,
          ),
          initialExpanded: true,
        ),
        const Divider(),
        ExpandableListItem(
          title: "ACTIVITIES",
          content: HouseHoldActivitiesView(
            houseHold: houseHold,
          ),
          initialExpanded: true,
        ),

        const SizedBox(
          height: 60,
        )
      ],
    );
  }
}
