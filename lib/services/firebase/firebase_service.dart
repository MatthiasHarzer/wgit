import 'dart:async';

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

    return await Future.wait(
        [for (var doc in snapshot.docs) HouseHold.fromDoc(doc)]);
  }

  static Stream<List<HouseHold>>  get availableHouseholds{
    StreamController<List<HouseHold>> controller = StreamController();

    AuthService.stateChange.listen((user) {
      if(user == null){
        controller.add([]);
      }else{
        RefService.householdsRef
            .where("members", arrayContains: user.uid)
            .snapshots()
            .asyncMap((event) => Future.wait(
            [for (var doc in event.docs) HouseHold.fromDoc(doc)]))
            .listen((households) {
          controller.add(households);
        });
      }
    });
    return controller.stream;
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

    return HouseHold.fromDoc(doc);
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
