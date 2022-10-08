import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/views/add_or_create_household/base.dart';

import '../../types/household.dart';
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


  /// Build all available households from the [firebaseService.availableHouseholds] stream
  Widget _buildHouseholds() {
    return StreamBuilder(
      stream: firebaseService.availableHouseholds,
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var household in snapshot.data ?? [])
              TextButton.icon(
                  onPressed: () => _switchTo(household),
                  label: Text(household.name),
                  icon: const Icon(Icons.home_outlined)),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHouseholds(),
          const Divider(height: 4, endIndent: 18),
          TextButton.icon(
              onPressed: _onNewTaped,
              label: Text(
                "Add New Household",
                style: TextStyle(color: Colors.grey[300]),
              ),
              icon: Icon(Icons.add, color: Colors.grey[300]),
          ),
        ],
      ),
    );
  }
}
