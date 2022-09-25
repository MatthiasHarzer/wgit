import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:wgit/views/household/members_view.dart';

import '../../services/types.dart';
import '../../util/util.dart';
import 'household_members_snippet.dart';

class HouseHoldView extends StatefulWidget {
  final HouseHold? houseHold;

  const HouseHoldView({required this.houseHold, Key? key}) : super(key: key);

  @override
  State<HouseHoldView> createState() => _HouseHoldViewState();
}

class _HouseHoldViewState extends State<HouseHoldView> {
  HouseHold get houseHold => widget.houseHold!;

  /// An empty widget
  Widget _empty() {
    return Container();
  }

  void _openMemberManagement() {
    print("OPEN MEMBER MANAGEMENT");
    Navigator.push(
      context,
      Util.createScaffoldRoute(
        view: MembersView(
          houseHold: houseHold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.houseHold == null) return _empty();

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
