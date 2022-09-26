import 'package:flutter/material.dart';

import '../services/types.dart';

class DrawerCurrentHouseHoldActions extends StatefulWidget {
  final HouseHold houseHold;
  const DrawerCurrentHouseHoldActions({ required this.houseHold,Key? key}) : super(key: key);

  @override
  State<DrawerCurrentHouseHoldActions> createState() => _DrawerCurrentHouseHoldActionsState();
}

class _DrawerCurrentHouseHoldActionsState extends State<DrawerCurrentHouseHoldActions> {
  HouseHold get houseHold => widget.houseHold;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
