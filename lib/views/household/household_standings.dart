import 'package:flutter/material.dart';
import 'package:wgit/util/components.dart';

import '../../services/types.dart';
import '../../util/util.dart';

class HouseHoldStandings extends StatefulWidget {
  final HouseHold houseHold;

  const HouseHoldStandings({ required this.houseHold, Key? key})
      : super(key: key);

  @override
  State<HouseHoldStandings> createState() => _HouseHoldStandingsState();
}

class _HouseHoldStandingsState extends State<HouseHoldStandings> {
  HouseHold get houseHold => widget.houseHold;

  Widget _buildColoredValue(double value, {TextStyle? style}) {
    style ??= const TextStyle();
    Color? color;
    if (value < 0) {
      color = Colors.red[700];
    } else if (value > 0) {
      color = Colors.green[400];
    } else {
      color = Colors.grey[400];
    }

    return Text(
      "${Util.formatAmount(value)}€", style: style.copyWith(color: color),);
  }

  Widget _buildStandingItem({required AppUser member}) {
    HouseHoldMemberData memberData = houseHold.memberDataOf(member: member);

    var totalPaid = memberData.totalPaid;
    var totalShouldPay = memberData.totalShouldPay;
    var standing = totalPaid - totalShouldPay;

    var titleStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 18,
        color: Colors.grey[400],
    );

    return ListTile(
      leading: buildCircularAvatar(url: member.photoURL, dimension: 35),
      title: Row(
        children: [
          Text("${member.displayName}: ", style: titleStyle,),
          _buildColoredValue(standing, style: titleStyle,),
        ],
      ),
      subtitle: Text(
        "Paid: €${Util.formatAmount(totalPaid)} | Should Pay: €${Util.formatAmount(totalShouldPay)}"
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for(var member in houseHold.members)
          _buildStandingItem(member: member),
      ],
    );
  }
}
