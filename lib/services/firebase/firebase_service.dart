import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'firebase_ref_service.dart';




/// Dart interface to communicate with the firebase platform
class FirebaseService {
  static bool _initialized = false;

  /// Initializes firebase, if not done already
  static void ensureInitialized() {
    if (_initialized) return;

    AuthService.stateChange.listen((User? user) async{
      if(user != null){
        /// The user is signed in

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
