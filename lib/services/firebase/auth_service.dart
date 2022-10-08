import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:rxdart/rxdart.dart';

import '../../types/app_user.dart';
import '../../types/household.dart';

enum AuthState { signedIn, signedOut, signingIn, signingOut }

/// Responsible for user management
class AuthService {
  bool _initialized = false;
  final BehaviorSubject<AppUser?> _user = BehaviorSubject.seeded(null);
  final BehaviorSubject<bool> _working = BehaviorSubject.seeded(false);
  final BehaviorSubject<bool> _signedIn = BehaviorSubject.seeded(false);
  final BehaviorSubject<AuthState> _authState =
      BehaviorSubject.seeded(AuthState.signedOut);
  bool _wasSignedIn = false;

  Stream<AppUser?> get appUserStream => _user.stream;

  Stream<bool> get workingStream => _working.stream;

  Stream<bool> get signedInStream => _signedIn.stream;

  Stream<AuthState> get authStateStream => _authState.stream;

  AppUser? get currentUser => _user.value;

  bool get signedIn => _user.value != null;

  final List<VoidCallback> _onFirstSignInCallbacks = [];

  void onFirstSignIn(VoidCallback cb) {
    if (_wasSignedIn) {
      cb();
    } else {
      _onFirstSignInCallbacks.add(cb);
    }
  }

  /// Makes sure the auth service is initialized correctly
  Future ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;

    _authState.listen((state) {
      /// Update _working
      switch (state) {
        case AuthState.signedOut:
        case AuthState.signedIn:
          _working.add(true);
          break;
        case AuthState.signingIn:
        case AuthState.signingOut:
          _working.add(true);
          break;
      }

      /// update _signedIn
      switch (state) {
        case AuthState.signedIn:
          _signedIn.add(true);
          break;
        case AuthState.signedOut:
          _signedIn.add(false);
          break;
        default:
      }
    });

    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user != null) {
        _user.add(await AppUser.fromUid(user.uid));
        _authState.add(AuthState.signedIn);

        if (!_wasSignedIn) {
          _wasSignedIn = true;
          _onFirstSignInCallbacks.forEach((cb) => cb());
          // appUser = await AppUser.fromUid(user.uid);
        }
      } else {
        _user.add(null);
        _authState.add(AuthState.signedOut);
      }
    });
  }

  /// Tries to sign in with google an returns the nullable user object
  Future<User?> _trySignInWithGoogle() async {
    User? u;
    if (kIsWeb) {
      u = (await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider()))
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

        u = (await FirebaseAuth.instance.signInWithCredential(credential)).user;
      } catch (e) {
        print(e);
      }
    } else {
      // throw PlatformException(
      //     code: "not_supported",
      //     message:
      //         "${Platform.localeName} is not supported for login with google");
    }
    return u;
  }

  /// Tries to sign in the client from a Google account. Returns true if the operation was successfully
  Future<bool> signInWithGoogle() async {
    _authState.add(AuthState.signingIn);

    User? u = await _trySignInWithGoogle();

    if (u == null) {
      _authState.add(AuthState.signedOut);
    }else{
      _authState.add(AuthState.signedIn);
    }

    return u != null;
  }

  /// Signs the current user out
  Future signOut() async {
    _authState.add(AuthState.signingOut);
    await HouseHold.clearAll();
    await FirebaseAuth.instance.signOut();
    GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    _authState.add(AuthState.signedOut);
  }
}
