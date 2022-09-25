import 'package:flutter/material.dart';
import 'package:wgit/views/add_or_create_household/base.dart';

import '../theme.dart';
import '../util/util.dart';

class HouseholdsWidget extends StatefulWidget {
  final Widget header;
  const HouseholdsWidget({required this.header, Key? key}) : super(key: key);

  @override
  State<HouseholdsWidget> createState() => _HouseholdsWidgetState();
}

class _HouseholdsWidgetState extends State<HouseholdsWidget> {
  void _onNewTaped(){
    Navigator.push(
      context,
      Util.createScaffoldRoute(view: const AddOrCreateHouseholdView()),
    );
  }

  /// Builds the create new household button
  Widget _buildCreateNewButton(){

    return ListTile(
      leading: const Icon(Icons.add),
      title: Text("Add Household", style: AppTheme.drawerText.copyWith(fontSize: 17),),
      onTap: _onNewTaped,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header,
        _buildCreateNewButton()
      ],
    );
  }
}

