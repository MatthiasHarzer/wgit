import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../types.dart';
import 'auth_service.dart';
import 'firebase_ref_service.dart';

/// Dart interface to communicate with the firebase platform
class FirebaseService {
  static bool _initialized = false;

  static AppUser? get user => AuthService.appUser;

  static bool get signedIn => user != null;

  /// Returns a list of all households the current user is a member of
  static Future<List<HouseHold>> getAvailableHouseHolds() async {
    if (!signedIn) return [];

    var snapshot = await RefService.householdsRef
        .where("members", arrayContains: user!.uid)
        .get();

    return await Future.wait([
      for (var doc in snapshot.docs)
        HouseHold.getCachedAndUpdateFromDocOrCreateNew(doc)
    ]);
  }

  static Stream<List<HouseHold>> get availableHouseholds {
    StreamController<List<HouseHold>> controller = StreamController();

    AuthService.stateChange.listen((user) {
      if (user == null) {
        controller.add([]);
      } else {
        RefService.householdsRef
            .where("members", arrayContains: user.uid)
            .snapshots()
            .asyncMap((event) => Future.wait([
                  for (var doc in event.docs)
                    HouseHold.getCachedAndUpdateFromDocOrCreateNew(doc)
                ]))
            .listen((households) {
          controller.add(households);
        });
      }
    });
    return controller.stream;
  }

  /// Promotes the given [member] int the given [houseHold]
  static Future promoteMember(HouseHold houseHold, AppUser member) async {
    if (!houseHold.members.contains(member)) return;

    var admins = [...houseHold.admins];
    admins.add(member);

    await RefService.refOf(houseHoldId: houseHold.id)
        .update({"admins": admins.map((a) => a.uid).toList()});
  }

  /// Removes the given [member] from the given [houseHold]
  static Future removeMember(HouseHold houseHold, AppUser member) async {
    if (!houseHold.members.contains(member)) return;

    var members = [...houseHold.members];
    members.remove(member);

    await RefService.refOf(houseHoldId: houseHold.id)
        .update({"members": members.map((a) => a.uid).toList()});
  }

  /// Adds a household with the current user as an admin
  static Future<HouseHold?> createHousehold(String name) async {
    if (!signedIn) return null;

    var docRef = await RefService.householdsRef.add({
      "name": name,
      "members": [user!.uid],
      "admins": [user!.uid],
    });
    var doc = await docRef
        .get(); // Just to make sure the household was really created

    return HouseHold.getCachedAndUpdateFromDocOrCreateNew(doc);
  }

  static Future updateMemberData(
      {required HouseHold houseHold,
      required HouseHoldMemberData memberData}) async {
    var ref = RefService.memberDataRefOf(
        houseHoldId: houseHold.id, uid: memberData.id);

    await ref.set(memberData.toJson());
  }

  static Future _addActivity({required HouseHold houseHold, required Activity activity})async{
    var ref = RefService.refOfActivities(houseHoldId: houseHold.id);
    var map = activity.toJson();
    map["timestamp"] = FieldValue.serverTimestamp();
    await ref.add(map);


    Future updateMB(AppUser member, double contribution) async {
      var memberData = await houseHold.memberDataOf(member: member);
      memberData.totalPaid += contribution;
      await updateMemberData(houseHold: houseHold, memberData: memberData);
    }

    List<Future> futures = [];
    for (var entry in activity.contributions.entries) {
      var member = entry.key;
      var contribution = entry.value;
      futures.add(updateMB(member, contribution));
    }

    await Future.wait(futures);
  }


  static Future _editActivity({required HouseHold houseHold, required Activity activity})async{
    var ref = RefService.refOfActivity(houseHoldId: houseHold.id, activityId: activity.id!);

    var existingDoc = await ref.get();
    var existingActivity = await Activity.fromDoc(existingDoc);

    var map = activity.toJson();
    await ref.update(map);


    Future updateMB(AppUser member, double contribution) async {
      var memberData = await houseHold.memberDataOf(member: member);
      memberData.totalPaid += contribution;
      await updateMemberData(houseHold: houseHold, memberData: memberData);
    }

    List<Future> futures = [];
    for (var entry in activity.contributions.entries) {
      var member = entry.key;
      var existingContribution = existingActivity.getContributionOf(member);
      var contribution = entry.value;
      futures.add(updateMB(member, contribution - existingContribution)); // Only take delta in account
    }

    await Future.wait(futures);
  }

  /// Creates a new activity, or if the activity has an id, edits the existing one
  static Future submitActivity(
      {required HouseHold houseHold, required Activity activity}) async {

    print("ID IS ${activity.id}");

    if(activity.id == null){
      /// It is a new activity
      await _addActivity(houseHold: houseHold, activity: activity);
    }else{
      /// Activity is edited
      await _editActivity(houseHold: houseHold, activity: activity);
    }


  }

  /// Initializes firebase, if not done already
  static void ensureInitialized() {
    if (_initialized) return;

    AuthService.stateChange.listen((user) {
      print(
        "USER IS signed in;: ${user?.displayName}",
      );
      if (user != null) {
        print("STARING STREAM LISTENING");
        availableHouseholds.listen((hoseholds) {
          print("----");
          print("HOUSEHOLD_UPDATE");
          for (var h in hoseholds) {
            print(h.name);
          }
          print("----");
        });
      }
    });

    AuthService.stateChange.listen((User? user) async {
      if (user != null) {
        /// The user is signed in

        print("Checking ref # ${RefService.currentUserRef?.path}");
        var snapshot = await RefService.currentUserRef!.get();

        if (!snapshot.exists) {
          /// Create the user in the db, if it does not exist already
          await RefService.currentUserRef!.set({
            "displayName": user.displayName,
            "email": user.email,
            "photoURL": user.photoURL,
            "uid": user.uid,
          });
        }
      }
    });

    _initialized = true;
  }
}
