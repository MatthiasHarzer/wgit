import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/firebase_service.dart';
import 'app_user.dart';
import 'household.dart';

final getIt = GetIt.I;
final authService = getIt<AuthService>();
final firebaseService = getIt<FirebaseService>();


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
