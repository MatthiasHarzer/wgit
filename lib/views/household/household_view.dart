import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:wgit/views/household/manage_members_view.dart';

import '../../services/types.dart';
import '../../util/util.dart';
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
      if(mounted){
        setState(() {})
      }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        HouseHoldMembersSnippet(
          houseHold: houseHold,
          onManageTap: _openMemberManagement,
        ),
        const Divider(),
      ],
    );
  }
}
