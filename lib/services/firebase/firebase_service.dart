import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wgit/secrets.dart';
import 'package:wgit/util/consts.dart';

import '../../types/activity.dart';
import '../../types/app_user.dart';
import '../../types/household.dart';
import '../../util/util.dart';
import 'auth_service.dart';
import 'firebase_ref_service.dart';

final getIt = GetIt.I;
final authService = getIt<AuthService>();

/// Dart interface to communicate with the firebase platform
class FirebaseService {
  final List<StreamSubscription> _signedSubscriptions = [];

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  bool _initialized = false;

  final BehaviorSubject<List<HouseHold>> _households = BehaviorSubject.seeded([]);

  Stream<List<HouseHold>> get availableHouseholds => _households.stream;

  AppUser? get user => authService.currentUser;

  bool get signedIn => user != null;

  // /// Returns a list of all households the current user is a member of
  // Future<List<HouseHold>> getAvailableHouseHolds() async {
  //   if (!signedIn) return [];
  //   var snapshot = await RefService.householdsRef
  //       .where("members", arrayContains: user!.uid)
  //       .get();
  //
  //   return await Future.wait([
  //     for (var doc in snapshot.docs)
  //       HouseHold.getCachedAndUpdateFromDocOrCreateNew(doc)
  //   ]);
  // }


  /// Adds the given [user] to the given [houseHold], if the current user is an admin in the household
  Future addMember(HouseHold houseHold, AppUser user) async {
    if (!houseHold.thisUserIsAdmin) return;

    var currentMembers = houseHold.membersSnapshot.map((m) => m.uid).toList();

    if (currentMembers.contains(user.uid)) return;

    currentMembers.add(user.uid);

    await RefService.refOf(houseHoldId: houseHold.id)
        .update({"members": currentMembers});
  }

  /// Promotes the given [member] int the given [houseHold]
  Future promoteMember(HouseHold houseHold, AppUser member) async {
    if (!houseHold.membersSnapshot.contains(member)) return;

    // var admins = [...houseHold.admins];
    // admins.add(member);

    await RefService.memberDataRefOf(houseHoldId: houseHold.id, uid: member.uid)
        .update({"role": Role.ADMIN});

    // await RefService.refOf(houseHoldId: houseHold.id)
    //     .update({"admins": admins.map((a) => a.uid).toList()});
  }

  /// Deletes the household, including all sub collections
  Future deleteHouseHold(HouseHold houseHold) async {
    var activities =
        await RefService.refOfActivities(houseHoldId: houseHold.id).get();
    var memberData =
        await RefService.membersDataRefOf(houseHoldId: houseHold.id).get();
    var groupData =
        await RefService.groupsRefOf(houseHoldId: houseHold.id).get();

    var batch = _firestore.batch();

    for (var doc in [
      ...activities.docs,
      ...memberData.docs,
      ...groupData.docs
    ]) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    var houseHoldRef = RefService.refOf(houseHoldId: houseHold.id);
    await houseHoldRef.delete();
  }

  Future leaveHousehold(HouseHold houseHold) {
    return removeMember(houseHold, houseHold.thisUser);
  }

  /// Removes the given [member] from the given [houseHold]
  Future removeMember(HouseHold houseHold, AppUser member) async {
    if (!houseHold.membersSnapshot.contains(member)) return;

    var members = [...houseHold.membersSnapshot];
    members.remove(member);

    await RefService.refOf(houseHoldId: houseHold.id)
        .update({"members": members.map((a) => a.uid).toList()});
  }

  /// Adds a household with the current user as an admin
  Future<HouseHold?> createHousehold(String name) async {
    if (!signedIn) return null;

    var docRef = await RefService.householdsRef.add({
      "name": name,
      "members": [user!.uid],
      // "admins": [user!.uid],
    });
    var empty = HouseHoldMemberData.emptyOf(user!);
    empty.role = Role.ADMIN;
    await RefService.memberDataRefOf(houseHoldId: docRef.id, uid: user!.uid)
        .set(empty.toJson());
    var doc = await docRef
        .get(); // Just to make sure the household was really created

    return HouseHold.getCachedAndUpdateFromDocOrCreateNew(doc);
  }

  Future updateMemberData(
      {required HouseHold houseHold,
      required HouseHoldMemberData memberData}) async {
    var ref = RefService.memberDataRefOf(
        houseHoldId: houseHold.id, uid: memberData.user.uid);

    await ref.set(memberData.toJson());
  }

  Future _addActivity(
      {required HouseHold houseHold, required Activity activity}) async {
    if (activity.contributions.keys.isEmpty) return;
    var ref = RefService.refOfActivities(houseHoldId: houseHold.id);
    var map = activity.toJson();
    map["timestamp"] = FieldValue.serverTimestamp();
    await ref.add(map);

    var relativeValue = activity.total / activity.contributions.keys.length;

    var batch = _firestore.batch();

    for (var entry in activity.contributions.entries) {
      var user = entry.key;
      var contribution = entry.value;

      var currentMemberData = houseHold.memberDataOf(member: user);
      currentMemberData.totalPaid += contribution;
      currentMemberData.totalShouldPay += relativeValue;

      batch.set(
          RefService.memberDataRefOf(houseHoldId: houseHold.id, uid: user.uid),
          currentMemberData.toJson());
    }
    await batch.commit();
  }

  Future _editActivity(
      {required HouseHold houseHold, required Activity activity}) async {
    if (activity.contributions.keys.isEmpty) return;
    var ref = RefService.refOfActivity(
        houseHoldId: houseHold.id, activityId: activity.id!);

    var existingDoc = await ref.get();
    var existingActivity = await Activity.fromDoc(existingDoc);

    var map = activity.toJson();
    await ref.update(map);

    var totalDelta = activity.total - existingActivity.total;
    var relativeDeltaValue = totalDelta / activity.contributions.keys.length;

    var batch = _firestore.batch();

    for (var entry in activity.contributions.entries) {
      var user = entry.key;
      var deltaContribution =
          entry.value - existingActivity.getContributionOf(user);

      var currentMemberData = houseHold.memberDataOf(member: user);
      currentMemberData.totalPaid += deltaContribution;
      currentMemberData.totalShouldPay += relativeDeltaValue;

      batch.set(
          RefService.memberDataRefOf(houseHoldId: houseHold.id, uid: user.uid),
          currentMemberData.toJson());
    }
    await batch.commit();
  }

  /// Creates a new activity, or if the activity has an id, edits the existing one
  Future submitActivity(
      {required HouseHold houseHold, required Activity activity}) async {
    // print("ID IS ${activity.id}");

    if (activity.id == null) {
      /// It is a new activity
      await _addActivity(houseHold: houseHold, activity: activity);
    } else {
      /// Activity is edited
      await _editActivity(houseHold: houseHold, activity: activity);
    }
  }

  Future createGroup(
      {required String houseHoldId,
      required String name,
      required List<AppUser> members,
      String? groupId}) async {
    if (groupId != null) {
      await RefService.groupRefOf(houseHoldId: houseHoldId, groupId: groupId)
          .set({
        "name": name,
        "members": members.map((m) => m.uid).toList(),
      });
      return;
    }

    await RefService.groupsRefOf(houseHoldId: houseHoldId).add({
      "name": name,
      "members": members.map((m) => m.uid).toList(),
    });
  }

  Future deleteGroup(
      {required String houseHoldId, required String groupId}) async {
    await RefService.groupRefOf(houseHoldId: houseHoldId, groupId: groupId)
        .delete();
  }

  Future<String> createDynamicLinkFor({required AppUser user}) async {
    final apiUrl =
        "$CREATE_DYN_LINK_ENPOINT?key=$TAPTWICE_FIREBSE_API_KEY&user_id=${user.uid}";
    final data = await Util.makeRequest(url: apiUrl);
    final link = data["link"];

    if (link == null) {
      throw Exception("Failed to generate dynamic link from response: $data");
    }

    // await modifyUser(uid: user.uid, dynLink: link);

    return link;

    // final targetUrl = "$DYNLINK_REDIRECT_URI/?user=${user.uid}";
    // final params = DynamicLinkParameters(
    //     link: Uri.parse(targetUrl),
    //     uriPrefix: DYNLINK_URI_PREFIX,
    //   androidParameters: const AndroidParameters(
    //     packageName: "dev.taptwice.wgit"
    //   )
    // );
    //
    // final dynLink = await _dynLinks.buildShortLink(params);
    //
    // return dynLink.shortUrl.toString();

    // print("dynLink $dynLink");
    // print(dynLink.shortUrl);
  }

  Future<AppUser?> resolveDynLinkUser(PendingDynamicLinkData dynLink) async {
    Uri uri = dynLink.link;
    String? uid = uri.queryParameters["user"];

    if (uid == null) return null;

    AppUser? user = await AppUser.fromUid(uid);
    if (user == null) return null;

    return user;
  }

  Future<AppUser?> resolveShortDynLinkUser(String shortDynLink) async {
    final apiUrl =
        "$GET_USER_BY_DYN_LINK_ENPOINT?key=$TAPTWICE_FIREBSE_API_KEY&link=$shortDynLink";
    // print(apiUrl);
    final data = await Util.makeRequest(url: apiUrl);
    final uid = data["user_id"];

    if (uid == null) return null;

    return await AppUser.fromUid(uid);
  }

  /// Modifies a users [displayName] and/or [photoURL]
  Future modifyUser(
      {required String uid,
      String? displayName,
      String? photoURL,
      String? dynLink}) async {
    Map<String, dynamic> updateData = {};

    if (displayName != null) {
      updateData["displayName"] = displayName;
    }
    if (photoURL != null) {
      updateData["photoURL"] = photoURL;
    }
    if (dynLink != null) {
      updateData["dynLink"] = dynLink;
    }

    if (updateData.keys.isEmpty) return;

    final ref = RefService.refOf(uid: uid);
    await ref.update(updateData);
  }

  /// Initializes firebase, if not done already
  Future ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    // AuthService.stateChange.listen((user) {
    //   print(
    //     "USER IS signed in;: ${user?.displayName}",
    //   );
    //   if (user != null) {
    //     print("STARING STREAM LISTENING");
    //     availableHouseholds.listen((hoseholds) {
    //       print("----");
    //       print("HOUSEHOLD_UPDATE");
    //       for (var h in hoseholds) {
    //         print(h.name);
    //       }
    //       print("----");
    //     });
    //   }
    // });

    authService.appUserStream.listen((AppUser? user) async {
      if (user != null) {
        /// The user is signed in
        final ref = RefService.refOf(uid: user.uid);
        print("Checking ref # ${ref.path}");
        var snapshot = await ref.get();

        if (!snapshot.exists) {
          /// Create the user in the db, if it does not exist already
          await ref.set({
            "displayName": user.displayName,
            // "email": user.email,
            "photoURL": user.photoURL,
            "uid": user.uid,
          });
        }

        _signedSubscriptions.add(RefService.householdsRef
            .where("members", arrayContains: user.uid)
            .snapshots()
            .asyncMap((event) => Future.wait([
                  for (var doc in event.docs)
                    HouseHold.getCachedAndUpdateFromDocOrCreateNew(doc)
                ]))
            .listen((households) {
          _households.add(households);
        }));
      } else {
        /// Cancel all running fb subs
        await Future.wait([for (var sub in _signedSubscriptions) sub.cancel()]);
        _signedSubscriptions.clear();
      }
    });
  }
}
