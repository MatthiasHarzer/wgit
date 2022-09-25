// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_ref_service.dart';

class Role {
  static const MEMBER = "member";
  static const ADMIN = "admin";

  static String get(String role) {
    if (role == ADMIN) return ADMIN;
    return MEMBER;
  }
}

class AppUser {
  late final String uid;
  late final String displayName;
  late final String photoURL;

  AppUser(
      {required this.uid, required this.displayName, required this.photoURL});

  AppUser.fromFirebaseUser(User user) {
    uid = user.uid;
    displayName = user.displayName!;
    photoURL = user.photoURL!;
  }

  AppUser.fromJson(Map<String, dynamic> data) {
    uid = data["uid"];
    displayName = data["displayName"];
    photoURL = data["photoURL"];
  }

  AppUser.fromDoc(DocumentSnapshot doc)
      : this.fromJson(doc.data() as Map<String, dynamic>);
}

class HouseHoldMember {
  late final AppUser user;
  late final String role;

  String get uid => user.uid;

  bool get isAdmin => role == Role.ADMIN;

  HouseHoldMember({required this.user, required this.role});
}

class HouseHold {
  late String id;
  late String name;
  late List<HouseHoldMember> members;
  late List<HouseHoldMember> admins;

  late HouseHoldMember thisUser;

  Iterable<String> get memberIds => members.map((m)=>m.user.uid);

  HouseHold._(
      {required this.id,
      required this.name,
      required List<AppUser> members,
      required List<AppUser> admins}) {
    this.members = members.map((m) {
      return HouseHoldMember(user: m, role: roleOf(m, admins));
    }).toList();
    this.admins = this.members.where((m) => m.role == Role.ADMIN).toList();
    thisUser = this.members.firstWhere((m) => m.user.uid == AuthService.appUser!.uid);
  }

  static String roleOf(AppUser member, Iterable<AppUser> admins) {
    if (admins.map((m) => m.uid).contains(member.uid)) {
      return Role.ADMIN;
    }
    return Role.MEMBER;
  }

  static Future<HouseHold> fromDoc(DocumentSnapshot doc) async {
    var id = doc.id;

    var data = doc.data() as Map<String, dynamic>;

    var name = data["name"];
    var members = await RefService.resolveUids(data["members"].cast<String>());
    var admins = await RefService.resolveUids(data["admins"].cast<String>());

    return HouseHold._(
        id: id, name: name, members: members.toList(), admins: admins.toList());
  }

  @override
  String toString() {
    return "Household<$name @ $id>";
  }
// late AppUser owner;
}
