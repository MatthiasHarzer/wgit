import 'package:flutter/material.dart';

import '../../types/activity.dart';
import '../../types/household.dart';
import '../../util/util.dart';
import '../edit_or_new_activity.dart';
import '../../util/extensions.dart';

class HouseHoldActivitiesView extends StatefulWidget {
  final HouseHold houseHold;

  const HouseHoldActivitiesView({required this.houseHold, Key? key})
      : super(key: key);

  @override
  State<HouseHoldActivitiesView> createState() =>
      _HouseHoldActivitiesViewState();
}

class _HouseHoldActivitiesViewState extends State<HouseHoldActivitiesView> {
  HouseHold get houseHold => widget.houseHold;
  // Stream<List<Activity>> get stream => houseHold.getActivityStream();

  @override
  void initState() {
    super.initState();

    // stream = houseHold.getActivityStream();
  }

  @override
  void didUpdateWidget(oldState){
    super.didUpdateWidget(oldState);


  }

  @override
  void dispose() {
    super.dispose();
    // houseHold.unregisterStream(stream);
  }

  void _editActivityTaped(Activity activity) {
    Navigator.push(
      context,
      Util.createScaffoldRoute(
        view: EditOrNewActivity(houseHold: houseHold, existingActivity: activity),
      ),
    );
  }

  /// Builds the households activities
  Widget _buildActivities() {
    Widget buildActivity(Activity activity) {
      return ListTile(
        leading: ConstrainedBox(
          constraints:
              const BoxConstraints(minHeight: double.infinity, maxWidth: 70),
          child: Align(
            alignment: Alignment.center,
            child: Text(
              "€${Util.formatAmount(activity.total)}",
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ),
        ),
        title: Text(activity.label),
        subtitle: Text(activity.date?.formatted ?? ""),
        trailing: IconButton(
          onPressed: () => _editActivityTaped(activity),
          icon: const Icon(Icons.edit),
          splashRadius: 25,
          tooltip: "Edit",
        ),
      );
    }

    return StreamBuilder(
      stream: houseHold.activitiesStream,
      builder: (context, snapshot) => Column(
        children: [
          for (var activity in snapshot.data ?? []) buildActivity(activity)
        ],
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActivities(),
      ],
    );
  }
}
