

import 'package:flutter/material.dart';
import 'package:wgit/theme.dart';
import 'package:wgit/util/components.dart';

import '../../services/types.dart';

class MemberGroupsSnippet extends StatefulWidget {
  final HouseHold houseHold;
  const MemberGroupsSnippet({Key? key, required this.houseHold}) : super(key: key);

  @override
  State<MemberGroupsSnippet> createState() => _MemberGroupsSnippetState();
}

class _MemberGroupsSnippetState extends State<MemberGroupsSnippet> {
  HouseHold get houseHold => widget.houseHold;

  @override
  void initState(){
    super.initState();

    houseHold.onChange(() => {
      if (mounted) {setState(() {})}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for(var group in houseHold.groups)
          buildGroupListTile(group: group),
      ],
    );
  }
}
