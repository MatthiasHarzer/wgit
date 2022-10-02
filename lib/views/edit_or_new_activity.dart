import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

import '../services/types.dart';
import '../util/components.dart';
import '../util/util.dart';

final getIt = GetIt.I;

class EditOrNewActivity extends StatefulWidget {
  final HouseHold houseHold;
  final Activity? existingActivity;

  const EditOrNewActivity(
      {required this.houseHold, this.existingActivity, Key? key})
      : super(key: key);

  @override
  State<EditOrNewActivity> createState() => _EditOrNewActivityState();
}

class _EditOrNewActivityState extends State<EditOrNewActivity> {
  HouseHold get houseHold => widget.houseHold;
  final firebaseService = getIt<FirebaseService>();

  List<AppUser> get availableUsers => <AppUser>{
        ...selectedGroup.members.where((m) => houseHold.isUserActive(m)),
        ...tempActivity.contributions.keys
      }.toList();

  double get total => _contributions.values.fold(0, (p, c) => p + c);

  late Group selectedGroup;

  late Activity tempActivity;
  bool isEditMode = false;

  bool working = false;

  Map<AppUser, double> get _contributions => tempActivity.contributions;

  @override
  void initState() {
    super.initState();

    tempActivity = Activity.empty();

    houseHold.onChange(() {
      if (mounted) {
        setState(() {});
      }
    });

    if (widget.existingActivity != null) {
      isEditMode = true;
      tempActivity = widget.existingActivity!.copy();

      // for (var entry in tempActivity.contributions.entries) {
      //   print("${entry.key} : ${entry.value}");
      // }
    } else {}
    selectedGroup = houseHold.defaultGroup!;
    // print(tempActivity.groupId);
    if (tempActivity.groupId != null) {
      selectedGroup =
          houseHold.findGroup(tempActivity.groupId) ?? selectedGroup;
    }
  }

  void _close() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.pop(context);
  }

  void _submit() async {
    if (working) return;
    setState(() {
      working = true;
    });
    tempActivity.label =
        tempActivity.label.isEmpty ? "(Unnamed)" : tempActivity.label;
    tempActivity.groupId = selectedGroup.id;

    for (var user in availableUsers) {
      if (!tempActivity.contributions.containsKey(user)) {
        tempActivity.contributions[user] = 0;
      }
    }

    await firebaseService.submitActivity(
        houseHold: houseHold, activity: tempActivity);

    if (mounted) {
      setState(() {
        working = false;
      });

      _close();
    }
  }

  void _setUserContribution(AppUser user, double contribution) {
    setState(() {
      _contributions[user] = contribution;
    });
  }

  double _getUserContribution(AppUser user) {
    return _contributions[user] ?? 0;
  }

  /// Builds a dropdown select menu option
  Widget _buildGroupsSelect(
      {required Group? value,
      required Function(Group) onChanged,
      required List<Group> options,
      String? placeHolder}) {
    List<DropdownMenuItem<String>> dropDownItems = options
        .map((group) => DropdownMenuItem<String>(
              value: group.id,
              child: Text(group.name),
            ))
        .toList();

    final GlobalKey dropDownKey = GlobalKey();

    String? valueId = value?.id;

    if (!options.map((h) => h.id).contains(value?.id)) {
      valueId = null;
    }
    return DropdownButton(
      style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontWeight: FontWeight.w500),
      key: dropDownKey,
      value: valueId,
      items: dropDownItems,
      hint: placeHolder != null ? Text(placeHolder) : null,
      onChanged: (String? newValue) {
        if (newValue == null) {
          return;
        }
        Group? group =
            houseHold.groups.firstWhereOrNull((g) => g.id == newValue);
        if (group != null) {
          onChanged(group);
        }
      },
    );
  }

  /// Builds formfield to enter the users contributoins
  Widget _buildUsersContributionInputFields() {
    Widget buildField(AppUser user) {
      double contribution = _getUserContribution(user);
      double perc = contribution * 100 / total;
      final isActiveUser = houseHold.isUserActive(user);
      String percent;
      if (total == 0) {
        percent = "";
      } else {
        percent = "${perc.round()}%";
      }

      return Opacity(
        opacity: isActiveUser ? 1 : 0.6,
        child: ListTile(
          leading: buildCircularAvatar(url: user.photoURL, dimension: 40),
          trailing: Text(
            percent,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          title: SizedBox(
            height: 60,
            child: Focus(
              onFocusChange: (focus) {
                // print(
                //     "FOCUS to $focus on ${user.displayName} with $contribution");
                _setUserContribution(user, contribution);
              },
              child: TextFormField(
                initialValue: contribution == 0 ? null : contribution.toString(),
                onChanged: (c) {
                  contribution = double.tryParse(c) ?? 0;
                  _setUserContribution(user, contribution);
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  labelText: "${user.displayName}'s contribution",
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var user in availableUsers) buildField(user),
      ],
    );
  }

  /// Builds the total display widget
  Widget _buildTotal() {
    TextStyle style = TextStyle(
        fontSize: 20, fontWeight: FontWeight.w500, color: Colors.grey[400]);
    String text = "Total: €${Util.formatAmount(total)}";
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(text, style: style),
      ],
    );
  }

  /// Builds submit / cancel actions
  Widget _buildActions() {
    return Container(
      color: Colors.grey[800]?.withAlpha(200),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _close,
              child: const Text("DISCARD"),
            ),
            ElevatedButton(
              onPressed: _submit,
              child: Row(
                children: [
                  Visibility(
                    visible: working,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox.square(
                        dimension: 15,
                        child: CircularProgressIndicator(
                          color: Colors.grey[200],
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),
                  const Text("SUBMIT")
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(isEditMode ? "Edit Activity" : "Add Activity"),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: tempActivity.label,
                      autofocus: !isEditMode,
                      onChanged: (text) => tempActivity.label = text,
                      decoration: const InputDecoration(
                        border: UnderlineInputBorder(),
                        labelText: "Label or reason",
                      ),
                    ),
                    Row(
                      children: [
                        const Spacer(),
                        Text(
                          "GROUP:",
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        _buildGroupsSelect(
                            value: selectedGroup,
                            options: houseHold.groups,
                            onChanged: (g) => setState(() {
                                  selectedGroup = g;
                                }),
                            placeHolder: "GORUP"),
                        const Spacer(),
                      ],
                    ),
                    _buildUsersContributionInputFields(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18.0),
                      child: Divider(
                        color: Colors.grey[600],
                      ),
                    ),
                    _buildTotal(),
                  ],
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildActions(),
          )
        ],
      ),
      // bottomNavigationBar: _buildActions(),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // floatingActionButton: _buildActions(),
    );
  }
}
