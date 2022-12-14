import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/util/components.dart';

import '../services/firebase/firebase_service.dart';
import '../../types/household.dart';
import '../types/app_user.dart';
import '../util/util.dart';
import 'add_or_create_household/base.dart';

final getIt = GetIt.I;

class AddUserToHouseholdView extends StatefulWidget {
  final AppUser user;
  final HouseHold? initialHousehold;

  const AddUserToHouseholdView(
      {required this.user, this.initialHousehold, Key? key})
      : super(key: key);

  @override
  State<AddUserToHouseholdView> createState() => _AddUserToHouseholdViewState();
}

class _AddUserToHouseholdViewState extends State<AddUserToHouseholdView> {
  List<HouseHold> availableHouseholds = [];
  final firebaseService = getIt<FirebaseService>();
  late final StreamSubscription _sub;

  bool get isEligible => availableHouseholds.isNotEmpty;

  HouseHold? selectedHousehold;
  bool working = false;

  @override
  void initState() {
    super.initState();

    selectedHousehold = widget.initialHousehold;



    _sub = firebaseService.availableHouseholds.listen((houseHolds) {
      if (mounted) {
        // print("UPDATE AVAILABLE HOUSEHOLDS");
        setState(() {
          availableHouseholds =
              houseHolds.where((h) => h.thisUserIsAdmin).toList();
          // print("${houseHolds.length} -> ${availableHouseholds.length}");
        });
      }
    });
  }

  @override
  void dispose(){
    super.dispose();

    _sub.cancel();
  }

  void _add() async {
    if (selectedHousehold == null || working) return;
    setState(() {
      working = true;
    });

    await firebaseService.addMember(selectedHousehold!, widget.user);

    if (mounted) {
      setState(() {
        working = false;
      });
    }
    _discard();
  }

  void _discard() {
    Navigator.pop(context);
  }

  /// Opens the join/Create household view
  void _onCreateNewTapped() {
    Navigator.push(
      context,
      Util.createScaffoldRoute(
          view: JoinOrCreateHouseholdView(
        onFinished: (_) {},
      )),
    );
  }

  /// Builds a snippet, representing the user
  Widget _buildUserSnippet(AppUser user) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: buildCircularAvatar(url: user.photoURL, dimension: 45),
          ),
          // const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
              ),
              Text(user.uid, style: TextStyle(color: Colors.grey[500])),
            ],
          )
        ],
      ),
    );
  }

  /// Builds an info screen, that the user does not participate in a house hold where the user has admin privileges
  Widget _buildIneligibleInfo() {
    return Center(
      child: InfoActionWidget(
        label:
            "It looks like you don't have sufficient permissions in any of your households to add members. \n\n You can create a new household or get promoted in an existing one.",
        buttonText: "CREATE A NEW HOUSEHOLD",
        onTap: _onCreateNewTapped,
      ),
    );
  }

  /// Builds a dropdown select menu option
  Widget _buildSelect(
      {required HouseHold? value,
      required Function(HouseHold) onChanged,
      required List<HouseHold> options,
      String? placeHolder}) {
    List<DropdownMenuItem<String>> dropDownItems = options
        .map((household) => DropdownMenuItem<String>(
              value: household.id,
              child: Text(household.name),
            ))
        .toList();

    final GlobalKey dropDownKey = GlobalKey();

    String? valueId = value?.id;

    if (!options.map((h) => h.id).contains(value?.id)) {
      valueId = null;
    }
    return DropdownButton(
      key: dropDownKey,
      value: valueId,
      items: dropDownItems,
      hint: placeHolder != null ? Text(placeHolder) : null,
      onChanged: (String? newValue) {
        if (newValue == null) {
          return;
        }
        HouseHold? houseHOld = HouseHold.tryGetCached(newValue);
        if (houseHOld != null) {
          onChanged(houseHOld);
        }
      },
    );
  }

  Widget _buildBody() {
    TextStyle textStyle = TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 20,
      color: Colors.grey[350],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Do you want to add this user to one of your households?",
                    style: textStyle,
                    textAlign: TextAlign.center,
                  ),
                  _buildUserSnippet(widget.user),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Column(
                  children: [
                    Text(
                      "Please select a household to add the user to:",
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                    _buildSelect(
                      value: selectedHousehold,
                      onChanged: (h) {
                        setState(() {
                          selectedHousehold = h;
                        });
                      },
                      options: availableHouseholds,
                      placeHolder: "Select a household",
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _discard,
                  child: const Text("DISCARD"),
                ),
                TextButton(
                  onPressed: selectedHousehold == null ? null : _add,
                  child: Row(
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
                      const Text("ADD USER"),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add User To Household"),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 18.0),
        child: isEligible ? _buildBody() : _buildIneligibleInfo(),
      ),
    );
  }
}
