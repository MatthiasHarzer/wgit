import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/firebase_ref_service.dart';
import '../services/firebase/firebase_service.dart';


final getIt = GetIt.I;
final authService = getIt<AuthService>();
final firebaseService = getIt<FirebaseService>();


/// An app user
class AppUser {
  late final String uid;
  late String displayName;
  late String photoURL;
  String? dynLink;

  bool get isSelf => uid == authService.currentUser?.uid;

  final BehaviorSubject<AppUser> _thisUser = BehaviorSubject();

  Future<String> getDynLink() async {
    if (dynLink == null) {
      dynLink = await firebaseService.createDynamicLinkFor(user: this);
      await firebaseService.modifyUser(uid: uid, dynLink: dynLink);
    }
    return dynLink!;
  }

  /// Creates an instance from a [DocumentSnapshot]
  AppUser._fromDoc(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    uid = doc.id;
    displayName = data["displayName"] ?? "(Unnamed)";
    photoURL = data["photoURL"];
    dynLink = data["dynLink"];
  }

  AppUser.empty() {
    uid = "";
    displayName = "";
    photoURL = "";
  }

  /// Updated the attributed with the data from the given [DocumentSnapshot]
  AppUser _modifyWith({required DocumentSnapshot doc}) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    displayName = data["displayName"] ?? displayName;
    photoURL = data["photoURL"] ?? photoURL;
    dynLink = data["dynLink"] ?? dynLink;

    return this;
  }

  static final Map<String, AppUser> _cache = {};
  static final BehaviorSubject<List<AppUser>> _users =
  BehaviorSubject.seeded([]);

  // static final List<AppUser2> _allUsers = [];

  static Stream<List<AppUser>> get usersStream => _users.stream;

  /// Tries to get a cached instance and update in with the doc data or create a new instance with the doc data
  static AppUser _getCachedAndUpdateFromDocOrCreateNew(DocumentSnapshot doc) {
    AppUser? user = _cache[doc.id];

    if (user == null) {
      user = AppUser._fromDoc(doc);
      _cache[doc.id] = user;
    } else {
      user = user._modifyWith(doc: doc);
    }
    user._thisUser.add(user);
    _users.add(_cache.values.toList());

    return user;
  }

  /// Resolved an user from a given [uid]
  static Future<AppUser?> fromUid(String uid) async {
    if (_cache.containsKey(uid)) return _cache[uid]!;

    final ref = RefService.refOf(uid: uid);

    final completer = Completer<AppUser?>();

    final sub = ref.snapshots().listen((doc) {
      if (!doc.exists) {
        if (!completer.isCompleted) {
          completer.complete(null);
        }
        return;
      }
      final user = _getCachedAndUpdateFromDocOrCreateNew(doc);
      if (!completer.isCompleted) {
        completer.complete(user);
      }
    });

    return completer.future;
  }

  /// Returns a list of users matching the [uids]
  static Future<List<AppUser>> fromUids(Iterable<String> uids) async {
    return (await Future.wait([for (var uid in uids) fromUid(uid)]))
        .whereType<AppUser>()
        .toList();
  }

  @override
  String toString() {
    return "AppUser<$displayName @$uid>";
  }
}
