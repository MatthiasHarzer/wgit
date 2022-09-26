// ignore_for_file: constant_identifier_names
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_ref_service.dart';

class Cache<E, T> {
  final Map<E, T> _cache = {};
  late final Future<T> Function(E) resolver;

  // late final Function<T>(T)? updater;
  Cache.withResolver({required this.resolver});

  // Cache.withUpdater({required this.updater});

  /// Tries to get the cached value with the [key] or resolves it if it is not present
  Future<T> get(E key) async {
    if (!_cache.containsKey(key)) {
      _cache[key] = await resolver(key);
    }

    return _cache[key]!;
  }
}

class Role {
  static const MEMBER = "member";
  static const ADMIN = "admin";

  static String get(String role) {
    if (role == ADMIN) return ADMIN;
    return MEMBER;
  }
}

class AppUser {
  static final Map<String, AppUser> _CACHE = {};

  late final String uid;
  late final String displayName;
  late final String photoURL;

  AppUser._(
      {required this.uid, required this.displayName, required this.photoURL});

  static AppUser _getCachedOrCreate(
      {required String uid,
      required String displayName,
      required String photoURL}) {
    if (_CACHE.containsKey(uid)) return _CACHE[uid]!;

    var user =
        AppUser._(uid: uid, displayName: displayName, photoURL: photoURL);
    _CACHE[uid] = user;
    return user;
  }

  static AppUser fromFirebaseUser(User user) {
    var uid = user.uid;
    var displayName = user.displayName!;
    var photoURL = user.photoURL!;
    return _getCachedOrCreate(
        uid: uid, displayName: displayName, photoURL: photoURL);
  }

  static AppUser fromJson(Map<String, dynamic> data) {
    var uid = data["uid"];
    var displayName = data["displayName"];
    var photoURL = data["photoURL"];
    return _getCachedOrCreate(
        uid: uid, displayName: displayName, photoURL: photoURL);
  }

  static AppUser fromDoc(DocumentSnapshot doc) {
    return fromJson(doc.data() as Map<String, dynamic>);
  }

  static AppUser? tryGetCached(String uid) {
    if (_CACHE.containsKey(uid)) return _CACHE[uid];
    return null;
  }
}

class HouseHoldMemberData {
  late final double standing;
  late final double totalPaid;

  HouseHoldMemberData.fromDoc(DocumentSnapshot doc) {
    if (!doc.exists) {
      standing = 0;
      totalPaid = 0;
    } else {
      var data = doc.data() as Map<String, dynamic>;

      standing = data["standing"].toDouble();
      totalPaid = data["total"].toDouble();
    }
  }
}

class HouseHold {
  static final Map<String, HouseHold> _CACHE = {};

  late String id;
  late String name;
  late List<AppUser> members;
  late List<AppUser> admins;

  late final Cache<String, HouseHoldMemberData> _memberInfoCache;

  // Iterable<String> get memberIds => members.map((m) => m.user.uid);
  AppUser get thisUser => AuthService.appUser!;

  final List<VoidCallback> _onChange = [];

  void onChange(VoidCallback cb) {
    _onChange.add(cb);
  }

  void _callOnChange() {
    _onChange.forEach((cb) => cb());
  }

  HouseHold._(
      {required this.id,
      required this.name,
      required this.members,
      required this.admins}) {
    _memberInfoCache = Cache.withResolver(resolver: (String uid) async {
      var ref = RefService.memberDataRefOf(houseHoldId: id, uid: uid);
      var doc = await ref.get();
      return HouseHoldMemberData.fromDoc(doc);
    });
  }

  static HouseHold? tryGetCached(String id) {
    if (_CACHE.containsKey(id)) return _CACHE[id];
    return null;
  }

  static Future<HouseHold> getCachedAndUpdateFromDocOrCreateNew(
      DocumentSnapshot doc) async {
    var id = doc.id;

    HouseHold houseHold;

    var cached = tryGetCached(id);
    if (cached != null) {
      houseHold = await cached._updateWith(doc);
    } else {
      var data = doc.data() as Map<String, dynamic>;

      var name = data["name"];
      var members =
          await RefService.resolveUids(data["members"].cast<String>());
      var admins = await RefService.resolveUids(data["admins"].cast<String>());

      houseHold = HouseHold._(
          id: id,
          name: name,
          members: members.toList(),
          admins: admins.toList());
      _CACHE[id] = houseHold;
    }
    houseHold._callOnChange();
    return houseHold;
  }

  /// Updates this household with data from the given [doc]. Returns itself
  Future<HouseHold> _updateWith(DocumentSnapshot doc) async {
    id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    name = data["name"];
    members =
        (await RefService.resolveUids(data["members"].cast<String>())).toList();
    admins =
        (await RefService.resolveUids(data["admins"].cast<String>())).toList();
    return this;
  }

  /// Determines if the given [user] is an admin in this household
  bool isUserAdmin(AppUser user) {
    return admins.contains(user);
  }

  /// Returns the role name depending on [isUserAdmin]
  String getUserRoleName(AppUser user) {
    return isUserAdmin(user) ? "ADMIN" : "MEMBER";
  }

  /// Returns the member data of this household
  Future<HouseHoldMemberData> memberDataOf({required AppUser member}) async {
    return _memberInfoCache.get(member.uid);
  }

  @override
  String toString() {
    return "Household<$name @ $id>";
  }
// late AppUser owner;
}
