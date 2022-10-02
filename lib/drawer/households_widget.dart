import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/views/add_or_create_household/base.dart';

import '../theme.dart';
import '../util/util.dart';

final getIt = GetIt.I;

class HouseholdsWidget extends StatefulWidget {
  final Function(HouseHold) onSwitchTo;

  const HouseholdsWidget({required this.onSwitchTo, Key? key})
      : super(key: key);

  @override
  State<HouseholdsWidget> createState() => _HouseholdsWidgetState();
}

class _HouseholdsWidgetState extends State<HouseholdsWidget> {
  final firebaseService = getIt<FirebaseService>();
  final TextStyle itemTextStyle = AppTheme.drawerText.copyWith(fontSize: 17);

  /// Closes the drawer and calls the callback for switching households
  void _switchTo(HouseHold houseHold) {
    // Navigator.pop(context);
    widget.onSwitchTo(houseHold);
  }

  /// Opens the join or create view
  void _onNewTaped() {
    Navigator.push(
      context,
      Util.createScaffoldRoute(
          view: JoinOrCreateHouseholdView(
        onFinished: _switchTo,
      )),
    );
  }

  /// Builds an item containing an icon and a text
  Widget _buildItem(
      {required IconData icon, required String text, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: itemTextStyle.color,
        size: (itemTextStyle.fontSize! * 1.5),
      ),
      onTap: onTap,
      title: Text(
        text,
        style: itemTextStyle,
      ),
    );
  }

  /// Build all available households from the [firebaseService.availableHouseholds] stream
  Widget _buildHouseholds() {
    return StreamBuilder(
      stream: firebaseService.availableHouseholds,
      builder: (context, snapshot) {
        return Column(
          children: [
            for (var household in snapshot.data ?? [])
              _buildItem(
                icon: Icons.home_outlined,
                text: household.name,
                onTap: () => _switchTo(household),
              )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHouseholds(),
        const Divider(height: 4),
        _buildItem(
            icon: Icons.add, text: "Add New Household", onTap: _onNewTaped),
      ],
    );
  }
}
