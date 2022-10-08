import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/drawer/current_household_actions.dart';
import 'package:wgit/drawer/account.dart';
import 'package:wgit/services/config_service.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../../types/household.dart';
import '../util/components.dart';
import 'households_widget.dart';

final getIt = GetIt.I;

class MainPageDrawer extends StatefulWidget {
  final Function(HouseHold) onSwitchTo;
  final HouseHold? currentHouseHold;

  const MainPageDrawer(
      {required this.onSwitchTo, required this.currentHouseHold, Key? key})
      : super(key: key);

  @override
  State<MainPageDrawer> createState() => _MainPageDrawerState();
}

class _MainPageDrawerState extends State<MainPageDrawer> {
  final authService = getIt<AuthService>();
  final TextStyle headerTextStyle = TextStyle(
    color: Colors.grey[300],
    fontWeight: FontWeight.w500,
  );

  @override
  void initState() {
    super.initState();
  }

  void _switchToHousehold(HouseHold houseHold) {
    Navigator.pop(context);
    widget.onSwitchTo(houseHold);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.grey[900]),
      child: Drawer(
        child: StreamBuilder(
          stream: authService.signedInStream,
          builder:(context, signedIn)=>ListView(
            primary: true,
            padding: EdgeInsets.zero,
            children: [
              Container(
                color: Colors.grey[850],
                height: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(top: 25, left: 25),
                    child: const Text(
                      "WG IT",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const AccountWidget(),
              Divider(
                color: Colors.grey[600],
                height: 5,
                thickness: 0.2,
              ),
              Visibility(
                visible: signedIn.data ?? false,
                child: Column(children: [
                  ExpandableListItem(
                    crossSessionConfig: ExpandableCrossSessionConfig(
                        "drawer_households",
                        defaultExpanded: true),
                    title: "HOUSEHOLDS",
                    content: HouseholdsWidget(
                      onSwitchTo: _switchToHousehold,
                    ),
                  ),
                  Divider(
                    color: Colors.grey[600],
                    height: 1,
                    thickness: 0.2,
                  ),
                  if (widget.currentHouseHold != null)
                    ExpandableListItem(
                      title: widget.currentHouseHold!.name,
                      content: DrawerCurrentHouseHoldActions(
                        houseHold: widget.currentHouseHold!,
                        onAddActivityTapped: () {},
                      ),
                      crossSessionConfig: ExpandableCrossSessionConfig(
                          "drawer_current_household",
                          defaultExpanded: false),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
