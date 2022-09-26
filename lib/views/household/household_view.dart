import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
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

    houseHold.onChange(() => {
          if (mounted) {setState(() {})}
        });
  }

  /// An empty widget
  Widget _empty() {
    return Container();
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

  Widget _buildItem(
      {required String title,
      required Widget content,
      Widget? action,
      bool initialExpanded = false}) {
    ExpandableThemeData theme;

    /// Not ideal but with a custom expandable controller the icon wouldn't be reactive, so /shrug
    if (initialExpanded) {
      theme = ExpandableThemeData(
        iconColor: Colors.grey[300],
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconRotationAngle: Util.degToRad(-90),
        collapseIcon: Icons.keyboard_arrow_down,
        expandIcon: Icons.keyboard_arrow_down,
      );
    } else {
      theme = ExpandableThemeData(
        iconColor: Colors.grey[300],
        iconPlacement: ExpandablePanelIconPlacement.left,
        iconRotationAngle: Util.degToRad(90),
        collapseIcon: Icons.keyboard_arrow_right,
        expandIcon: Icons.keyboard_arrow_right,
      );
    }

    return ExpandablePanel(
      collapsed: initialExpanded ? content : Container(),
      theme: theme,
      header: SizedBox(
        height: 40,
        child: Align(
          // alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              if (action != null) action
            ],
          ),
        ),
      ),
      expanded: initialExpanded ? Container() : content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _buildItem(
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
        _buildItem(
            title: "ACTIVITIES",
            content: HouseHoldActivitiesView(
              houseHold: houseHold,
            ),
            initialExpanded: true,
        ),

        SizedBox(
          height: 60,
        )
      ],
    );
  }
}
