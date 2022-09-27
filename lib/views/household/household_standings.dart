import 'package:flutter/material.dart';
import 'package:wgit/util/components.dart';

import '../../services/types.dart';
import '../../util/util.dart';

class _HouseHoldStandingsItem extends StatefulWidget {
  final Function(AppUser) onMoneySendTap;
  final AppUser member;
  final HouseHold houseHold;

  const _HouseHoldStandingsItem(
      {required this.member,
      required this.houseHold,
      required this.onMoneySendTap,
      Key? key})
      : super(key: key);

  @override
  State<_HouseHoldStandingsItem> createState() =>
      _HouseHoldStandingsItemState();
}

class _HouseHoldStandingsItemState extends State<_HouseHoldStandingsItem> {
  AppUser get member => widget.member;
  bool working = false;

  void _onSendMoneyTaped(AppUser member) async {
    setState(() {
      working = true;
    });

    await widget.onMoneySendTap(member);
    if (!mounted) return;

    setState(() {
      working = false;
    });
  }

  @override
  void initState() {
    super.initState();

    widget.houseHold.onChange(() => setState(() {}));
  }

  /// Builds a colored text widget based on the value (value < 0 = red, >0 = grenn)
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
      "${Util.formatAmount(value)}€",
      style: style.copyWith(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    HouseHoldMemberData memberData =
        widget.houseHold.memberDataOf(member: member);

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
          Text(
            "${member.displayName}: ",
            style: titleStyle,
          ),
          _buildColoredValue(
            standing,
            style: titleStyle,
          ),
        ],
      ),
      subtitle: Text(
          "Paid: €${Util.formatAmount(totalPaid)} | Should Pay: €${Util.formatAmount(totalShouldPay)}"),
      trailing: IconButton(
        splashRadius: 25,
        tooltip: "Exchange Money",
        icon: working
            ? const CircularProgressIndicator()
            : const Icon(Icons.payments),
        onPressed: member.isSelf || working
            ? null
            : () {
                _onSendMoneyTaped(member);
              },
      ),
    );
  }
}

class HouseHoldStandings extends StatefulWidget {
  final HouseHold houseHold;
  final Function(AppUser) onMoneySendTap;

  const HouseHoldStandings(
      {required this.houseHold, required this.onMoneySendTap, Key? key})
      : super(key: key);

  @override
  State<HouseHoldStandings> createState() => _HouseHoldStandingsState();
}

class _HouseHoldStandingsState extends State<HouseHoldStandings> {
  HouseHold get houseHold => widget.houseHold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var member in houseHold.members)
          _HouseHoldStandingsItem(
            member: member,
            houseHold: houseHold,
            onMoneySendTap: widget.onMoneySendTap,
          ),
      ],
    );
  }
}
