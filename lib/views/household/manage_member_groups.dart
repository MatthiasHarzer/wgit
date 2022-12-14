import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/util/components.dart';

import '../../types/app_user.dart';
import '../../types/group.dart';
import '../../types/household.dart';

final getIt = GetIt.I;

class _CreateOrEditGroupDialog extends StatefulWidget {
  final bool isEdit;
  final Group group;

  const _CreateOrEditGroupDialog(
      {Key? key, required this.group, required this.isEdit})
      : super(key: key);

  @override
  State<_CreateOrEditGroupDialog> createState() =>
      _CreateOrEditGroupDialogState();
}

class _CreateOrEditGroupDialogState extends State<_CreateOrEditGroupDialog> {
  final firebaseService = getIt<FirebaseService>();
  late Group group;

  ThemeData get theme => Theme.of(context);

  bool working = false;
  bool deleteWorking = false;

  bool get isDefaultGroup => group.isDefault;

  HouseHold get houseHold => group.houseHold;

  @override
  void initState() {
    super.initState();

    group = widget.group.copy();
  }

  void _close() {
    Navigator.pop(context);
  }

  void _submit() async {
    if (working) return;
    setState(() {
      working = true;
    });

    var name = group.name;

    if (name.isEmpty) {
      name = "(Unnamed)";
    }

    String? id = group.id.isEmpty ? null : group.id;

    await firebaseService.createGroup(
        houseHoldId: houseHold.id,
        name: name,
        members: group.members,
        groupId: id);

    if (mounted) {
      setState(() {
        working = false;
      });
    }
    _close();
  }

  void _deletePressed() async {
    if (deleteWorking) return;
    setState(() {
      deleteWorking = true;
    });
    var dialog = ConfirmDialog(
        context: context,
        title: "Delete group \"${group.name}\"?",
        confirm: "DELETE")
      ..show();

    final confirm = await dialog.future;

    if (confirm) {
      await firebaseService.deleteGroup(
          houseHoldId: houseHold.id, group: group);
      _close();
    }

    setState(() {
      deleteWorking = false;
    });
  }

  Widget _buildUserSelect(AppUser user) {
    bool isActive = group.members.contains(user);

    return CheckboxListTile(
      title: Text(user.displayName),
      onChanged: group.isDefault
          ? null
          : (v) {
              setState(() {
                isActive = v ?? isActive;

                if (isActive) {
                  if (!group.members.contains(user)) {
                    group.members.add(user);
                  }
                } else {
                  if (group.members.contains(user)) {
                    group.members.remove(user);
                  }
                }
              });
            },
      value: isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: widget.isEdit
          ? Text("Edit Group \"${group.name}\"")
          : const Text("Create new group"),
      children: [
        Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                autofocus: !widget.isEdit,
                initialValue: group.name,
                onChanged: (c) {
                  group.name = c;
                },
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: "Group Name",
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "MEMBERS",
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Visibility(
                      visible: isDefaultGroup,
                      child: Text(
                        "This is the default group of this household containing all members.",
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      width: 400,
                      child: StreamBuilder(
                          stream: houseHold.membersStream,
                          builder: (context, snapshot) {
                            final members = snapshot.data ?? [];
                            return ListView(
                              children: [
                                for (var member in members)
                                  _buildUserSelect(member),
                              ],
                            );
                          }),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: widget.isEdit && !isDefaultGroup,
                child: TextButton(
                  onPressed: _deletePressed,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Visibility(
                        visible: deleteWorking,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox.square(
                            dimension: 15,
                            child: CircularProgressIndicator(
                              color: Theme.of(context).errorColor,
                              strokeWidth: 3,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "DELETE GROUP",
                        style: TextStyle(color: Theme.of(context).errorColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: _close,
              child: const Text("DISCARD"),
            ),
            TextButton(
                onPressed: _submit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: working,
                      child: const Padding(
                        padding: EdgeInsets.only(right: 8.0),
                        child: SizedBox.square(
                          dimension: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                    const Text("SAVE")
                  ],
                ))
          ],
        )
      ],
    );
  }
}

class ManageMemberGroupsView extends StatefulWidget {
  final HouseHold houseHold;

  const ManageMemberGroupsView({Key? key, required this.houseHold})
      : super(key: key);

  @override
  State<ManageMemberGroupsView> createState() => _ManageMemberGroupsViewState();
}

class _ManageMemberGroupsViewState extends State<ManageMemberGroupsView> {
  HouseHold get houseHold => widget.houseHold;

  @override
  void initState() {
    super.initState();

    // houseHold.onChange(() {
    //   if (mounted) {
    //     setState(() {});
    //   }
    // });
  }

  /// Opens the edit dialog for the given [group]. If it is null, a new group will be created
  void _editOrNewGroupTapped({Group? group}) {
    bool isEdit = group != null;
    group ??= Group.temp(houseHold);

    showDialog(
      context: context,
      builder: (ctx) => _CreateOrEditGroupDialog(
        group: group!,
        isEdit: isEdit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Groups of ${houseHold.name}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            StreamBuilder(
                stream: houseHold.groupsStream,
                builder: (context, snapshot) {
                  final groups = snapshot.data ?? [];
                  return Column(
                    children: [
                      for (var group in groups)
                        buildGroupListTile(
                          group: group,
                          action: IconButton(
                            onPressed: () =>
                                _editOrNewGroupTapped(group: group),
                            icon: const Icon(Icons.edit),
                          ),
                        ),
                    ],
                  );
                }),
            TextButton(
                onPressed: () => _editOrNewGroupTapped(),
                child: const Text("ADD GROUP"))
          ],
        ),
      ),
    );
  }
}
