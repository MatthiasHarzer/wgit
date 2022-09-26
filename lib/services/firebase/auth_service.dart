import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../types.dart';

/// Responsible for user management
class AuthService {
  static Function(bool) _workingUpdate = (_) =>null;

  static void onWorkingUpdate(Function(bool) cb){
    _workingUpdate = cb;
  }

  /// The current firebase user
  static User? get _user => FirebaseAuth.instance.currentUser;

  static AppUser? get appUser => signedIn ? AppUser.fromFirebaseUser(_user!) : null;

  /// Whether the client is signed in or not
  static bool get signedIn => _user != null;

  /// The authState stream. Updates on sign-in / sign-out
  static Stream<User?> get stateChange => FirebaseAuth.instance.authStateChanges();

  /// Tries to sign in the client from a Google account.
  /// Returns true if the operation was successfully
  static Future<bool> signInWithGoogle() async {
    User? u;
    _workingUpdate(true);
    if (kIsWeb) {
      u =
          (await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider()))
              .user;
    } else if (Platform.isAndroid) {
      try {
        // Trigger the authentication flow
        final GoogleSignInAccount? googleUser =
        await GoogleSignIn(scopes: ["email"]).signIn();

        // Obtain the auth details from the request
        final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth?.accessToken,
          idToken: googleAuth?.idToken,
        );

        u =
            (await FirebaseAuth.instance.signInWithCredential(credential)).user;
      } catch (e) {
        print(e);
      }
    } else {
      throw PlatformException(
          code: "not_supported",
          message:
          "${Platform.localeName} is not supported for login with google");
    }
    _workingUpdate(false);
    return u != null;
  }

  /// Signs the current user out
  static Future signOut() async{
    _workingUpdate(true);
    await FirebaseAuth.instance.signOut();
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    _workingUpdate(false);
  }
}
