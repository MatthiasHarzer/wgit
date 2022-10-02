import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_service.dart';

/// Responsible for providing references in the cloud firestore
class RefService {
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static DocumentReference get appRef => _firestore.doc("wg-it/public");

  static CollectionReference get usersRef => appRef.collection("users");

  static CollectionReference get householdsRef =>
      appRef.collection("households");

  /// The reference of the currently logged in user
  // static DocumentReference? get currentUserRef =>
  //     FirebaseService.signedIn ? usersRef.doc(FirebaseService.user?.uid) : null;

  /// Gets a reference of the given type. If more than one type (user/household) is give, this methods can produced unexpected bahaviour
  static DocumentReference refOf({String? uid, String? houseHoldId}) {
    if (uid != null) {
      return usersRef.doc(uid);
    } else if (houseHoldId != null) {
      return householdsRef.doc(houseHoldId);
    }

    return usersRef.doc(uid);
  }

  /// Returns the ref to save activities in.
  static CollectionReference refOfActivities({required String houseHoldId}) {
    return refOf(houseHoldId: houseHoldId).collection("activities");
  }

  static DocumentReference refOfActivity(
      {required String houseHoldId, required String activityId}) {
    return refOfActivities(houseHoldId: houseHoldId).doc(activityId);
  }

  static CollectionReference membersDataRefOf({required String houseHoldId}){
    return refOf(houseHoldId: houseHoldId).collection("member-data");
  }

  /// Retunrs the ref of the given users data of a household
  static DocumentReference memberDataRefOf(
      {required String houseHoldId, required String uid}) {
    return membersDataRefOf(houseHoldId: houseHoldId).doc(uid);
  }

  static CollectionReference groupsRefOf({required String houseHoldId}) {
    return refOf(houseHoldId: houseHoldId).collection("group-data");
  }

  static DocumentReference groupRefOf(
      {required String houseHoldId, required String groupId}) {
    return groupsRefOf(houseHoldId: houseHoldId).doc(groupId);
  }


  /// Gets users information by its user id
  // static Future<AppUser?> resolveUid(String uid) async {
  //   var cached = AppUser.tryGetCached(uid);
  //   if (cached != null) return cached;
  //
  //   var doc = await usersRef.doc(uid).get();
  //   if (!doc.exists) return null;
  //
  //   return AppUser.fromDoc(doc);
  // }

  // /// Like [resolveUid] but for arrays
  // static Future<Iterable<AppUser>> resolveUids(Iterable<String> uids) async {
  //   var futures = uids.map((uid) => resolveUid(uid));
  //
  //   return (await Future.wait(futures)).whereType<AppUser>();
  // }
}
