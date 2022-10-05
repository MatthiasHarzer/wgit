// ignore_for_file: constant_identifier_names, avoid_function_literals_in_foreach_calls
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_ref_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

final getIt = GetIt.I;
final authService = getIt<AuthService>();
final firebaseService = getIt<FirebaseService>();

/// An activity is an expense shared by multiple [AppUsers]
class Activity {
  String? id;
  String label;
  DateTime? date;
  Map<AppUser, double> contributions;
  String? groupId;

  double get total => contributions.values.fold(0, (p, c) => p + c);

  double getContributionOf(AppUser user) {
    return contributions[user] ?? 0;
  }

  Activity._(
      {required this.label,
      required this.contributions,
      this.date,
      this.id,
      this.groupId});

  /// Creates an activity from a document snapshot
  static Future<Activity> fromDoc(DocumentSnapshot doc) async {
    var id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    var label = data["label"];
    var date = data["timestamp"]?.toDate() ?? DateTime.now();

    var group = data["groupId"] ?? "all";

    var raw = data["contributions"] as Map<String, dynamic>;
    Map<String, double> contr = raw.cast<String, double>();

    Map<AppUser, double> contributions = {};
    for (var entry in contr.entries) {
      var user = await AppUser.fromUid(entry.key);
      if (user == null) continue;

      contributions[user] = entry.value;
    }

    return Activity._(
        id: id,
        label: label,
        contributions: contributions,
        date: date,
        groupId: group);
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
      "total": total,
      "groupId": groupId,
    };
  }

  Activity copy() {
    return Activity._(
        id: id,
        contributions: Map.of(contributions),
        label: label,
        date: date,
        groupId: groupId);
  }

  @override
  String toString() {
    return "Action<$label @$id on $date with $contributions>";
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
  }) {
    if (id == "all") {
      members = houseHold.membersSnapshot;
    }
  }

  Group.createDefault({required this.houseHold}) {
    id = "all";
    name = "Default";
    members = [...houseHold.membersSnapshot];
  }

  Group.temp(HouseHold houseHold)
      : this._(
            id: "",
            name: "",
            members: List.empty(growable: true),
            houseHold: houseHold);

  Group copy() {
    return Group._(
      houseHold: houseHold,
      members: members,
      id: id,
      name: name,
    );
  }

  // static Map<String, Group>
  //
  // static getCachedAndUpdateFromDocOrCreateNew(DocumentSnapshot doc, HouseHold houseHold){
  //
  // }

  static Future<Group> fromDoc(
      DocumentSnapshot doc, HouseHold houseHold) async {
    var id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    var name = data["name"];
    var members = await AppUser.fromUids(data["members"].cast<String>());

    members =
        members.where((m) => houseHold.membersSnapshot.contains(m)).toList();

    if (id == "all") {
      members = [...houseHold.membersSnapshot];
    }

    return Group._(
        id: id, name: name, members: members.toList(), houseHold: houseHold);
  }
}

/// A users role in a [HouseHold]
class Role {
  static const MEMBER = "member";
  static const ADMIN = "admin";

  static String get(String role) {
    if (role == ADMIN) return ADMIN;
    return MEMBER;
  }
}

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

/// Contains user specific content for one [HouseHold]
class HouseHoldMemberData {
  late AppUser user;
  late double totalShouldPay;
  late double totalPaid;
  String role = "member";

  double get standing => totalPaid - totalShouldPay;

  HouseHoldMemberData._(
      {required this.user,
      required this.totalShouldPay,
      required this.totalPaid,
      this.role = "member"});

  HouseHoldMemberData.emptyOf(AppUser user) {
    user = user;
    totalPaid = 0;
    totalShouldPay = 0;
  }

  static Future<HouseHoldMemberData> fromDoc(DocumentSnapshot doc) async {
    if (!doc.exists) {
      return HouseHoldMemberData._(
          user: AppUser.empty(), totalPaid: 0, totalShouldPay: 0);
    } else {
      var data = doc.data() as Map<String, dynamic>;

      return HouseHoldMemberData._(
          user: await AppUser.fromUid(doc.id) ?? AppUser.empty(),
          totalShouldPay: data["totalShouldPay"]?.toDouble() ?? 0,
          totalPaid: data["totalPaid"]?.toDouble() ?? 0,
          role: data["role"] ?? Role.MEMBER,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      "totalPaid": totalPaid,
      "totalShouldPay": totalShouldPay,
      "role": role,
    };
  }
}

/// A household is a collective of [AppUsers]
class HouseHold {
  late String id;
  late String name;

  /// Consider using [membersStream] instead of this list
  // late List<AppUser> members;

  final List<StreamSubscription> _subs = [];

  final BehaviorSubject<List<Group>> _groups = BehaviorSubject.seeded([]);
  final BehaviorSubject<List<Activity>> _activities =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<List<HouseHoldMemberData>> _memberData =
      BehaviorSubject.seeded([]);
  final BehaviorSubject<List<AppUser>> _members = BehaviorSubject.seeded([]);

  Stream<List<AppUser>> get membersStream => _members.stream;

  Stream<List<Group>> get groupsStream => _groups.stream;

  Stream<List<Activity>> get activitiesStream => _activities.stream;

  Stream<List<HouseHoldMemberData>> get membersDataStream => _memberData.stream;

  List<AppUser> get membersSnapshot => _members.value;

  List<Group> get groupsSnapshot => _groups.value;

  List<Activity> get activitiesSnapshot => _activities.value;

  List<HouseHoldMemberData> get membersDataSnapshot => _memberData.value;

  Group? get defaultGroup => _groups.value.firstWhereOrNull((g) => g.isDefault);

  List<AppUser> get validAdmins =>
      membersSnapshot.where((m) => isUserAdmin(m)).toList();

  // Iterable<String> get memberIds => members.map((m) => m.user.uid);
  AppUser get thisUser => authService.currentUser!;

  bool get thisUserIsAdmin => isUserAdmin(thisUser);

  bool get thisUserIsTheOnlyAdmin => thisUserIsAdmin && validAdmins.length == 1;

  Completer ready = Completer();
  Map<String, Completer> awaitReadyCompleter = {
    "members": Completer(),
    "groups": Completer(),
    "activities": Completer(),
    "memberData": Completer(),
  };


  HouseHold._({
    required this.id,
    required this.name,
    required List<AppUser> members,
  }) {
    /// Initial value
    _members.add(members);

    /// members stream
    _subs.add(AppUser.usersStream.listen((event) {
      _members.add(event.where((m) => membersSnapshot.contains(m)).toList());
      _setReadyOf("members");
    }));

    /// Groups stream
    _subs.add(RefService.groupsRefOf(houseHoldId: id)
        .snapshots()
        .listen((snapshot) async {
      _groups.add(await Future.wait(
          [for (var doc in snapshot.docs) Group.fromDoc(doc, this)]));
      _setReadyOf("groups");
    }));

    /// Activities stream
    _subs.add(RefService.refOfActivities(houseHoldId: id)
        .limit(50)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) async {
      _activities.add(await Future.wait(
          [for (var doc in snapshot.docs) Activity.fromDoc(doc)]));
      _setReadyOf("activities");
    }));

    /// Member data stream
    _subs.add(RefService.membersDataRefOf(houseHoldId: id)
        .snapshots()
        .listen((snapshot) async{
      _memberData.add(
          await Future.wait([for (var doc in snapshot.docs) HouseHoldMemberData.fromDoc(doc)]));
      _setReadyOf("memberData");
    }));

    /// Keep the attribute up to date with member changes
    _members.listen((value) {
      members = value;
    });

    // List<StreamSubscription> readySubs = [];
    // Map<String, bool> isReady = {
    //   "members": false,
    //   "memberData": false,
    //
    // }
    _awaitReady();
  }

  /// Completes the completer in [awaitReadyCompleter] with the given [key]
  void _setReadyOf(String key){
    Completer? cmp = awaitReadyCompleter[key];
    if(cmp == null || cmp.isCompleted) return;
    cmp.complete();
    // if(awaitReadyCompleter[type]?.isCompleted) return;
  }

  /// Awaits all completers defined in [awaitReadyCompleter]
  void _awaitReady() async {
    await Future.wait([
      for(var completer in awaitReadyCompleter.values) completer.future
    ]);
    ready.complete();
  }

  /// Updates this household with data from the given [doc]. Returns itself
  Future<HouseHold> _updateWith(DocumentSnapshot doc) async {
    id = doc.id;
    var data = doc.data() as Map<String, dynamic>;

    name = data["name"];

    _members.add(await AppUser.fromUids(data["members"].cast<String>()));
    // members = await AppUser.fromUids(data["members"].cast<String>());

    defaultGroup?.members = membersSnapshot;
    return this;
  }


  /// Determines if the given [user] is an admin in this household
  bool isUserAdmin(AppUser user) {
    return memberDataOf(member: user).role == Role.ADMIN;
  }

  /// Returns the role name depending on [isUserAdmin]
  String getUserRoleName(AppUser user) {
    return isUserAdmin(user) ? "ADMIN" : "MEMBER";
  }

  /// Returns the member data of this household
  HouseHoldMemberData memberDataOf({required AppUser member}) {
    return _memberData.value.firstWhereOrNull((mb) => mb.user.uid == member.uid) ??
        HouseHoldMemberData.emptyOf(member);
  }

  /// Returns whether the given [user] is active (member) or only in active (no member but memberdata)
  bool isUserActive(AppUser user) {
    return membersSnapshot.contains(user);
  }

  /// Returns the group with the given [groupId] or [null] if none was found
  Group? findGroup(String? groupId) {
    return _groups.value.firstWhereOrNull((g) => g.id == groupId);
  }

  /// Adjusts the [from] and [to] users paid/shouldPay amount to ...
  Future exchangeMoney(
      {required AppUser from,
      required AppUser to,
      required double amount}) async {
    var fromMemberData = memberDataOf(member: from);
    var toMemberData = memberDataOf(member: to);

    fromMemberData.totalPaid += amount;
    toMemberData.totalPaid -= amount;

    await Future.wait([
      firebaseService.updateMemberData(
          houseHold: this, memberData: fromMemberData),
      firebaseService.updateMemberData(
          houseHold: this, memberData: toMemberData)
    ]);
  }

  Future cancelAll() async {
    List<Future> futures = [
      ..._subs.map((s)=>s.cancel()),
      _memberData.close(),
      _activities.close(),
      _groups.close(),
      _members.close(),
    ];
    await Future.wait(futures);
  }

  static final Map<String, HouseHold> _cache = {};

  // static Stream<List<HouseHold2>> get availableHouseholdsStream => _availableHouseholds.stream;

  /// Tries to fetch a cached household and updates it with the doc data or creates a new household from the doc data
  static Future<HouseHold> getCachedAndUpdateFromDocOrCreateNew(
      DocumentSnapshot doc) async {
    HouseHold? houseHold = _cache[doc.id];

    if (houseHold == null) {
      final data = doc.data() as Map<String, dynamic>;
      final id = doc.id;
      final name = data["name"];
      final members = await AppUser.fromUids(data["members"].cast<String>());

      houseHold = HouseHold._(id: id, name: name, members: members);
      await houseHold.ready.future;
      _cache[doc.id] = houseHold;
    } else {
      houseHold = await houseHold._updateWith(doc);
    }
    return houseHold;
  }

  static HouseHold? tryGetCached(String id) {
    return _cache[id];
  }

  static Future clearAll()async{
    for(var cached in _cache.values){
     await  cached.cancelAll();
    }
    _cache.clear();

  }

  @override
  String toString() {
    return "Household<$name @ $id>";
  }
}
