import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/util/components.dart';

import '../../services/types.dart';

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
  late Group group;

  ThemeData get theme => Theme.of(context);

  bool working = false;

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

    await FirebaseService.createGroup(
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

  Widget _buildUserSelect(AppUser user) {
    bool isActive = group.members.contains(user);

    return CheckboxListTile(
      title: Text(user.displayName),
      onChanged: (v) {
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
                keyboardType: TextInputType.number,
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
                    Text(
                      "MEMBERS",
                      style: TextStyle(
                          fontWeight: FontWeight.w500, color: Colors.grey[400]),
                    ),
                    SizedBox(
                      height: 300,
                      width: 400,
                      child: ListView(
                        children: [
                          for (var member in houseHold.members)
                            _buildUserSelect(member),
                        ],
                      ),
                    )
                  ],
                ),
              )
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

    houseHold.onChange(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

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
            Column(
              children: [
                for (var group in houseHold.groups)
                  buildGroupListTile(
                    group: group,
                    action: IconButton(
                      onPressed: group.isDefault
                          ? null
                          : () => _editOrNewGroupTapped(group: group),
                      icon: const Icon(Icons.edit),
                    ),
                  ),
              ],
            ),
            TextButton(
                onPressed: () => _editOrNewGroupTapped(),
                child: const Text("ADD GROUP"))
          ],
        ),
      ),
    );
  }
}
