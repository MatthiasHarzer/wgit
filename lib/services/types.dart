import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wgit/services/firebase/firebase_ref_service.dart';

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

class HouseHold {
  late String id;
  late String name;
  late List<AppUser> members;
  late List<AppUser> admins;

  HouseHold._(
      {required this.id,
      required this.name,
      required this.members,
      required this.admins});

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
  String toString(){
    return "Household<$name @ $id>";
  }
// late AppUser owner;
}
