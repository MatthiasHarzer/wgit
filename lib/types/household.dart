import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:get_it/get_it.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wgit/types/audit_log_item.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/firebase_ref_service.dart';
import '../services/firebase/firebase_service.dart';
import 'activity.dart';
import 'app_user.dart';
import 'group.dart';

final getIt = GetIt.I;
final authService = getIt<AuthService>();
final firebaseService = getIt<FirebaseService>();

/// A users role in a [HouseHold]
class Role {
  static const MEMBER = "member";
  static const ADMIN = "admin";

  static String get(String role) {
    if (role.toLowerCase() == ADMIN.toLowerCase()) return ADMIN;
    return MEMBER;
  }
}

/// Contains user specific content for one [HouseHold]
class HouseHoldMemberData {
  late AppUser user;
  late double totalShouldPay;
  late double totalPaid;
  String role = Role.MEMBER;

  double get standing => totalPaid - totalShouldPay;

  HouseHoldMemberData._(
      {required this.user,
      required this.totalShouldPay,
      required this.totalPaid,
      this.role = Role.MEMBER});

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
  final BehaviorSubject<List<AuditLogItem>> _auditLog =
      BehaviorSubject.seeded([]);

  Stream<List<AppUser>> get membersStream => _members.stream;

  Stream<List<Group>> get groupsStream => _groups.stream;

  Stream<List<Activity>> get activitiesStream => _activities.stream;

  Stream<List<HouseHoldMemberData>> get membersDataStream => _memberData.stream;

  Stream<List<AuditLogItem>> get auditLogStream => _auditLog.stream;

  List<AppUser> get membersSnapshot => _members.value;

  List<Group> get groupsSnapshot => _groups.value;

  List<Activity> get activitiesSnapshot => _activities.value;

  List<HouseHoldMemberData> get membersDataSnapshot => _memberData.value;

  List<AuditLogItem> get auditLogSnapshot => _auditLog.value;

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
        .listen((snapshot) async {
      _memberData.add(await Future.wait(
          [for (var doc in snapshot.docs) HouseHoldMemberData.fromDoc(doc)]));
      _setReadyOf("memberData");
    }));

    /// Audit log stream
    _subs.add(RefService.auditLogRefOf(houseHoldId: id)
        .limit(50)
        .orderBy("timestamp", descending: true)
        .snapshots()
        .listen((snapshot) async {
      _auditLog.add(await Future.wait(
          [for (var doc in snapshot.docs) AuditLogItem.fromDoc(doc, houseHold: this)]));
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
  void _setReadyOf(String key) {
    Completer? cmp = awaitReadyCompleter[key];
    if (cmp == null || cmp.isCompleted) return;
    cmp.complete();
    // if(awaitReadyCompleter[type]?.isCompleted) return;
  }

  /// Awaits all completers defined in [awaitReadyCompleter]
  void _awaitReady() async {
    await Future.wait(
        [for (var completer in awaitReadyCompleter.values) completer.future]);
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
    return memberDataOf(member: user).role.toUpperCase();
    // return isUserAdmin(user) ? "ADMIN" : "MEMBER";
  }

  /// Returns the member data of this household
  HouseHoldMemberData memberDataOf({required AppUser member}) {
    return _memberData.value
            .firstWhereOrNull((mb) => mb.user.uid == member.uid) ??
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

  /// Retunrs the activity with the given id if it exists
  Activity? findActivity(String? activityId){
    if(activityId == null) return null;
    return _activities.value.firstWhereOrNull((a)=>a.id==activityId);
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

    await firebaseService.addAuditLogItem(
      AuditLogItem.byMe(
          type: AuditLogType.sendMoney,
          data: {"from": from.uid, "to": to.uid, "amount": amount}),
      houseHoldId: id,
    );
  }

  Future cancelAll() async {
    List<Future> futures = [
      ..._subs.map((s) => s.cancel()),
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

  static Future clearAll() async {
    for (var cached in _cache.values) {
      await cached.cancelAll();
    }
    _cache.clear();
  }

  @override
  String toString() {
    return "Household<$name @ $id>";
  }
}
