// ignore_for_file: constant_identifier_names
import 'package:collection/collection.dart';
import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_ref_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

import '../util/util.dart';

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

/// An activity is an expense shared by multiple [AppUsers]
class Activity {
  String? id;
  String label;
  DateTime? date;
  Map<AppUser, double> contributions;

  double get total => contributions.values.fold(0, (p, c) => p + c);

  double getContributionOf(AppUser user) {
    return contributions[user] ?? 0;
  }

  Activity._({
    required this.label,
    required this.contributions,
    this.date,
    this.id,
  });

  /// Creates an activity from a document snapshot
  static Future<Activity> fromDoc(DocumentSnapshot doc) async {
    var id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    var label = data["label"];
    var date = data["timestamp"]?.toDate() ?? DateTime.now();

    var raw = data["contributions"] as Map<String, dynamic>;
    Map<String, double> contr = raw.cast<String, double>();

    Map<AppUser, double> contributions = {};
    for (var entry in contr.entries) {
      var user = await AppUser.fromUid(entry.key);
      if (user == null) continue;

      contributions[user] = entry.value;
    }

    return Activity._(
        id: id, label: label, contributions: contributions, date: date);
  }

  Activity.empty() : this._(contributions: {}, label: "");

  Activity.temp({
    required this.label,
    required this.contributions,
  }) {
    date = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "contributions":
          contributions.map((key, value) => MapEntry(key.uid, value)),
      "total": total
    };
  }

  @override
  String toString() {
    return "Action<$label @$id on $date with $contributions>";
  }

  Activity copy() {
    return Activity._(
      id: id,
      contributions: Map.of(contributions),
      label: label,
      date: date,
    );
  }
}

/// A group consists of a subset of [AppUsers] from one [HouseHold] members, sharing financials
class Group {
  late final String id;
  late String name;
  late List<AppUser> members;
  late final HouseHold houseHold;

  bool get isDefault => id == "all";

  Group._({
    required this.id,
    required this.name,
    required this.members,
    required this.houseHold,
  }){
    if(id == "all"){
      members = houseHold.members;
    }
  }

  Group.createDefault({required this.houseHold}) {
    id = "all";
    name = "Default";
    members = [...houseHold.members];
  }

  Group.temp(HouseHold houseHold)
      : this._(id: "", name: "", members: List.empty(growable: true), houseHold: houseHold);

  Group copy(){
    return Group._(
      houseHold: houseHold,
      members: members,
      id: id,
      name: name,
    );
  }
  static Future<Group> fromDoc(
      DocumentSnapshot doc, HouseHold houseHold) async {
    var id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    var name = data["name"];
    var members = await AppUser.fromUids(data["members"].cast<String>());

    members = members.where((m) => houseHold.members.contains(m)).toList();

    if (id == "all") {
      members = [...houseHold.members];
    }

    return Group._(
        id: id, name: name, members: members.toList(), houseHold: houseHold);
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

/// An user from the database
class AppUser {
  static final Map<String, AppUser> _CACHE = {};

  late final String uid;
  late final String displayName;
  late final String photoURL;
  String? dynLink;

  bool get isSelf => uid == AuthService.appUser?.uid;

  Future<String> getDynLink() async {
    if (dynLink != null) return dynLink!;

    return FirebaseService.createDynamicLinkFor(user: this);
  }

  AppUser._(
      {required this.uid,
      required this.displayName,
      required this.photoURL,
      this.dynLink});

  static AppUser _getCachedOrCreate(
      {required String uid,
      required String displayName,
      required String photoURL,
      String? dynLink}) {
    if (_CACHE.containsKey(uid)) return _CACHE[uid]!;

    var user = AppUser._(
        uid: uid,
        displayName: displayName,
        photoURL: photoURL,
        dynLink: dynLink);
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
    var dynLink = data["dynLink"];
    return _getCachedOrCreate(
        uid: uid,
        displayName: displayName,
        photoURL: photoURL,
        dynLink: dynLink);
  }

  static AppUser fromDoc(DocumentSnapshot doc) {
    return fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Returns the user with the given [uid]
  static Future<AppUser?> fromUid(String uid) async {
    if (_CACHE.containsKey(uid)) return _CACHE[uid]!;
    var doc = await RefService.refOf(uid: uid).get();
    if (!doc.exists) return null;
    return fromDoc(doc);
  }

  /// Returns a list of users matching the [uids]
  static Future<List<AppUser>> fromUids(Iterable<String> uids) async {
    return (await Future.wait([for (var uid in uids) fromUid(uid)]))
        .whereType<AppUser>()
        .toList();
  }

  static AppUser? tryGetCached(String uid) {
    if (_CACHE.containsKey(uid)) return _CACHE[uid];
    return null;
  }

  @override
  String toString() {
    return "AppUser<$displayName @$uid>";
  }
}

/// Contains user specific content for one [HouseHold]
class HouseHoldMemberData {
  late String id;
  late double totalShouldPay;
  late double totalPaid;

  HouseHoldMemberData.emptyOf(AppUser user) {
    id = user.uid;
    totalPaid = 0;
    totalShouldPay = 0;
  }

  HouseHoldMemberData.fromDoc(DocumentSnapshot doc) {
    id = doc.id;
    if (!doc.exists) {
      totalShouldPay = 0;
      totalPaid = 0;
    } else {
      var data = doc.data() as Map<String, dynamic>;

      totalShouldPay = data["totalShouldPay"].toDouble();
      totalPaid = data["totalPaid"].toDouble();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "totalPaid": totalPaid,
      "totalShouldPay": totalShouldPay,
    };
  }
}

/// A household is a collective of [AppUsers]
class HouseHold {
  static final Map<String, HouseHold> _CACHE = {};

  late String id;
  late String name;
  late List<AppUser> members;
  late List<AppUser> admins;

  final List<VoidCallback> _onChange = [];
  List<Activity> activities = [];
  List<Group> groups = [];
  Map<String, HouseHoldMemberData> memberData = {};

  Group? get defaultGroup => groups.firstWhereOrNull((g) => g.isDefault);

  List<AppUser> get validAdmins =>
      members.where((m) => admins.contains(m)).toList();

  final List<StreamController<List<Activity>>> _activitiesStreamControllers =
      [];
  final List<StreamController<List<Group>>> _groupsStreamControllers = [];

  // Iterable<String> get memberIds => members.map((m) => m.user.uid);
  AppUser get thisUser => AuthService.appUser!;

  bool get thisUserIsAdmin => isUserAdmin(thisUser);

  bool get thisUserIsTheOnlyAdmin => thisUserIsAdmin && validAdmins.length == 1;

  /// Returns whether the current user can leave the house hold or not.
  /// e.x. the user can't leave if it's the only admin in the household
  // bool canLeaveHousehold(){
  //   if(thisUserIsAdmin && validAdmins.length == 1){
  //     /// The user is the only admin
  //   }
  // }



  void onChange(VoidCallback cb) {
    _onChange.add(cb);
  }

  void callOnChange() {
    _onChange.forEach((cb) => cb());
  }

  /// Returns a stream that gets updated when new activities are incoming
  Stream<List<Activity>> getActivityStream() {
    StreamController<List<Activity>> controller = StreamController();
    _activitiesStreamControllers.add(controller);
    Util.runDelayed(() {
      _updateStreams(
          controllers: _activitiesStreamControllers, withData: activities);
    }, const Duration(milliseconds: 300));
    return controller.stream;
  }

  /// Returns a stream that gets updated when new groups are incoming
  Stream<List<Group>> getGroupsStream() {
    StreamController<List<Group>> controller = StreamController();
    _groupsStreamControllers.add(controller);
    Util.runDelayed(() {
      _updateStreams(controllers: _groupsStreamControllers, withData: groups);
    }, const Duration(milliseconds: 300));
    return controller.stream;
  }

  /// Unregisters a stream from any controller streams
  void unregisterStream(Stream stream) {
    var allStream = [
      ..._activitiesStreamControllers,
      ..._groupsStreamControllers
    ];
    var t = allStream.where((c) => c.stream == stream);
    if (t.isEmpty) return;

    t.forEach((c) => c.close());
  }

  /// Updates an array of [controllers] with the given data
  void _updateStreams(
      {required List<StreamController> controllers, required List withData}) {
    for (var ctrl in controllers) {
      ctrl.add(withData);
    }
  }

  /// Setups firebase listeners (streams)
  void _setup() {
    _setupActivityStream();
    _setupGroupsStream();
    _setupMemberDataStream();
  }

  /// Setup realtime updates for activities
  void _setupActivityStream() {
    RefService.refOfActivities(houseHoldId: id)
        .limit(50)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((event) async {
      var docs = event.docs;

      activities =
          await Future.wait([for (var doc in docs) Activity.fromDoc(doc)]);

      callOnChange();
      _updateStreams(
          controllers: _activitiesStreamControllers, withData: activities);
    });
  }

  /// Setup realtime updates for groups
  void _setupGroupsStream() {
    RefService.groupsRefOf(houseHoldId: id).snapshots().listen((event) async {
      var docs = event.docs;

      groups =
          await Future.wait([for (var doc in docs) Group.fromDoc(doc, this)]);

      if (!groups.map((g) => g.id).contains("all")) {
        var df = Group.createDefault(houseHold: this);
        FirebaseService.createGroup(
            houseHoldId: id,
            name: df.name,
            members: df.members,
            groupId: df.id);
        return;
      }

      callOnChange();
      _updateStreams(controllers: _groupsStreamControllers, withData: groups);
    });
  }

  void _setupMemberDataStream() {
    RefService.membersDataRefOf(houseHoldId: id)
        .snapshots()
        .listen((event) async {
      var docs = event.docs;
      memberData = {
        for (var doc in docs) doc.id: HouseHoldMemberData.fromDoc(doc)
      };

      callOnChange();
    });
  }

  HouseHold._(
      {required this.id,
      required this.name,
      required this.members,
      required this.admins}) {
    _setup();
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
      var members = await AppUser.fromUids(data["members"].cast<String>());
      var admins = await AppUser.fromUids(data["admins"].cast<String>());

      houseHold = HouseHold._(
          id: id,
          name: name,
          members: members.toList(),
          admins: admins.toList());
      _CACHE[id] = houseHold;
    }
    houseHold.callOnChange();
    return houseHold;
  }

  /// Updates this household with data from the given [doc]. Returns itself
  Future<HouseHold> _updateWith(DocumentSnapshot doc) async {
    id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    name = data["name"];
    members = await AppUser.fromUids(data["members"].cast<String>());
    admins = await AppUser.fromUids(data["admins"].cast<String>());

    defaultGroup?.members = members;

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
  HouseHoldMemberData memberDataOf({required AppUser member}) {
    if (memberData.keys.contains(member.uid)) return memberData[member.uid]!;
    return HouseHoldMemberData.emptyOf(member);
  }

  Future exchangeMoney(
      {required AppUser from,
      required AppUser to,
      required double amount}) async {
    var fromMemberData = memberDataOf(member: from);
    var toMemberData = memberDataOf(member: to);

    fromMemberData.totalPaid += amount;
    toMemberData.totalPaid -= amount;

    await Future.wait([
      FirebaseService.updateMemberData(
          houseHold: this, memberData: fromMemberData),
      FirebaseService.updateMemberData(
          houseHold: this, memberData: toMemberData)
    ]);
  }

  @override
  String toString() {
    return "Household<$name @ $id>";
  }
// late AppUser owner;
}
