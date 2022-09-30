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
  HouseHoldMemberData get memberData => widget.houseHold.memberDataOf(member: member);
  bool get isActiveUser => widget.houseHold.isUserActive(member);

  bool working = false;


  final avatarSize = 35.0;

  @override
  void initState(){
    super.initState();

    widget.houseHold.onChange(() {
      if (mounted) setState(() {});
    });



  }


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

    final totalPaid = memberData.totalPaid;
    final totalShouldPay = memberData.totalShouldPay;
    final standing = totalPaid - totalShouldPay;

    final titleStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: isActiveUser ? 18 : 16,
      color: Colors.grey[400],
    );

    final subtitleStyle = TextStyle(
        fontSize: isActiveUser ? 15 : 12
    );


    const avatarSize = 35.0;

    return Opacity(
      opacity: isActiveUser ? 1.0 : 0.5,
      child: ListTile(
        leading: buildCircularAvatar(url: member.photoURL, dimension: avatarSize),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if(!isActiveUser)
              const Text("INACTIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500), textAlign: TextAlign.left,),
            Row(
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 180
                  ),
                  child: Text(
                    "${member.displayName}: ",
                    style: titleStyle,
                  ),
                ),
                _buildColoredValue(
                  standing,
                  style: titleStyle,
                ),
              ],
            ),
          ],
        ),
        subtitle: Text(
            "Paid: €${Util.formatAmount(totalPaid)} | Should Pay: €${Util.formatAmount(totalShouldPay)}", style: subtitleStyle,),
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

  Iterable<AppUser> get _orderedUsers{
    final members = [...houseHold.memberData.keys];
    members.sort(
          (a, b) => houseHold.isUserActive(b) ? 1 : houseHold.isUserActive(a) ? -1 : 0,
    );
    return members;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var member in _orderedUsers)
          _HouseHoldStandingsItem(
            member: member,
            houseHold: houseHold,
            onMoneySendTap: widget.onMoneySendTap,
          ),
      ],
    );
  }
}
