import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../services/firebase/firebase_service.dart';
import 'app_user.dart';

final getIt = GetIt.I;
final authService = getIt<AuthService>();
final firebaseService = getIt<FirebaseService>();

class AuditLogType {
  static const ADD_ACTIVITY = "ADD_ACTIVITY";
  static const EDIT_ACTIVITY = "EDIT_ACTIVITY";
  static const SEND_MONEY = "SEND_MONEY";
  static const ADD_MEMBER = "ADD_MEMBER";
  static const REMOVE_MEMBER = "REMOVE_MEMBER";
  static const PROMOTE_MEMBER = "PROMOTE_MEMBER";
  static const ADD_GROUP = "ADD_GROUP";
  static const EDIT_GROUP = "EDIT_GROUP";
  static const REMOVE_GROUP = "REMOVE_GROUP";
}

class AuditLogItem {
  late AppUser initiator;
  late String type;
  late String id;
  late DateTime date;
  late Map<String, dynamic> data;

  AuditLogItem._(
      {required this.id,
      required this.initiator,
      required this.type,
      required this.date,
        required  this.data
      });

  AuditLogItem.byMe(
      {
      // required this.initiator,
      required this.type,
      required this.data}) {
    initiator = authService.currentUser!;
    id = "";
  }

  static Future<AuditLogItem> fromDoc(DocumentSnapshot doc) async {
    final id = doc.id;

    final rawData = doc.data() as Map<String, dynamic>;

    final initiator = await AppUser.fromUid(rawData["initiator"]);
    final type = rawData["type"];
    final date = rawData["timestamp"]?.toDate() ?? DateTime.now();

    final data = rawData["data"] as Map<String, dynamic>;

    return AuditLogItem._(
        id: id,
        data: data,
        initiator: initiator!,
        type: type,
        date: date);
  }

  Map<String, dynamic> toJson() {
    return {
      "initiator": initiator.uid,
      "type": type,
      "data": data,
    };
  }
}

