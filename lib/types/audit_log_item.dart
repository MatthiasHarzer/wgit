import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/types/activity.dart';
import 'package:wgit/types/household.dart';

import '../services/firebase/firebase_service.dart';
import '../util/util.dart';
import 'app_user.dart';
import 'group.dart';

final getIt = GetIt.I;
final authService = getIt<AuthService>();
final firebaseService = getIt<FirebaseService>();

enum AuditLogType{
  addActivity,
  editActivity,
  sendMoney,
  addMember,
  removeMember,
  promoteMember,
  addGroup,
  editGroup,
  removeGroup,
  unknown
}

AuditLogType stringToAuditLogType(String s){
  try{
    return AuditLogType.values.byName(s);
  }catch(_){
    return AuditLogType.unknown;
  }
}

class AuditLogItem {
  late AppUser initiator;
  late AuditLogType type;
  late String id;
  late DateTime date;
  late HouseHold houseHold;
  late Map<String, dynamic> data;

  AuditLogItem._(
      {required this.id,
      required this.initiator,
      required this.type,
      required this.date,
        required  this.data,
        required this.houseHold,
      });

  AuditLogItem.byMe(
      {
      // required this.initiator,
      required this.type,
      required this.data}) {
    initiator = authService.currentUser!;
    id = "";
  }


  Map<String, dynamic> toJson() {
    return {
      "initiator": initiator.uid,
      "type": type.name,
      "data": data,
    };
  }

  IconData get icon => _auditLogIconMap[type] ?? Icons.question_mark;

  /// For [AuditLogType.addMember], [AuditLogType.removeMember] and [AuditLogType.promoteMember]
  Future<List<String>> _getMemberText() async{
    AppUser? member = await AppUser.fromUid(data["member"] ?? "");
    Map<AuditLogType, String> actionTexts = {
      AuditLogType.addMember: "added",
      AuditLogType.removeMember: "removed",
      AuditLogType.promoteMember: "promoted"
    };
    Map<AuditLogType, String> closingsTexts = {
      AuditLogType.addMember: "to the household",
      AuditLogType.removeMember: "from the household",
      AuditLogType.promoteMember: ""
    };

    String actionText;
    if(type == AuditLogType.removeMember && member?.uid == initiator.uid){
      return [
        initiator.displayName,
        "left the household."
      ];
    }
    return [
      initiator.displayName,
      actionTexts[type] ?? "(unknown action)",
      member?.displayName ?? "(unknown user)",
      closingsTexts[type] ?? "?????"
    ];
  }

  /// For [AuditLogType.addActivity] and [AuditLogType.editActivity]
  Future<List<String>> _getActivityText() async{
    Activity? activity = houseHold.findActivity(data["id"]);
    Group? group = houseHold.findGroup(data["group_id"]);
    String addEditText;
    final total = data["total"] ?? 0;
    final groupName = group?.name ?? data["group_name"] ?? "(Group Unknown)";

    final contributions = data["contributions"] as Map<String, dynamic>;
    final contributors = await AppUser.fromUids(contributions.keys);

    if(type == AuditLogType.addActivity){
      addEditText = "added activity";
    }else{
      addEditText = "edited activity";
    }

    return [
      initiator.displayName,
      "$addEditText »",
      activity?.label ?? "(Does not exist)",
      "« in group »",
      groupName,
      "« with contributions by",
      contributors.map((c)=>c.displayName).join(", "),
      "and a total of",
      "€${Util.formatAmount(total)}",
    ];
  }

  /// for [AuditLogType.addGroup], [AuditLogType.editGroup] and [AuditLogType.removeGroup]
  Future<List<String>> _getGroupText() async{
    Group? group = houseHold.findGroup(data["id"]);
    List<AppUser> members = await AppUser.fromUids(data["members"].cast<String>());
    String groupName = group?.name ?? data["name"] ?? "(Name unknown)";

    if(type == AuditLogType.removeGroup){
      return [
        initiator.displayName,
         "deleted group »",
        groupName,
        "«"
      ];
    }

    String addEdit = type == AuditLogType.addGroup ? "created group »" : "edited group »";

    return [
      initiator.displayName,
      addEdit,
      groupName,
      "« with members",
      members.map((m)=>m.displayName).join(", ")
    ];
  }

  /// For [AuditLogType.sendMoney]
  Future<List<String>> _getSendMoneyText() async{
    AppUser? from = await AppUser.fromUid(data["from"] ?? "");
    AppUser? to = await AppUser.fromUid(data["to"] ?? "");
    double amount = data["amount"] ?? 0;

    return [
      from?.displayName ?? "(Unknown user)",
      "send",
      Util.formatAmount(amount),
      "to",
      to?.displayName ?? "(Unknown user)",
    ];
  }



  Future<List<String>> getText() async{
    // return _getActivityText();
    switch(type){

      case AuditLogType.addActivity:
      case AuditLogType.editActivity:
        return _getActivityText();
      case AuditLogType.addMember:
      case AuditLogType.removeMember:
      case AuditLogType.promoteMember:
        return _getMemberText();
      case AuditLogType.addGroup:
      case AuditLogType.editGroup:
      case AuditLogType.removeGroup:
        return _getGroupText();

      case AuditLogType.sendMoney:
        return _getSendMoneyText();
      case AuditLogType.unknown:
        return [
          initiator.displayName,
          "did something unexpected. Here is what we know:",
          data.toString()
        ];
    }
  }

  static Future<AuditLogItem> fromDoc(DocumentSnapshot doc, {required HouseHold houseHold}) async {
    final id = doc.id;

    final rawData = doc.data() as Map<String, dynamic>;

    final initiator = await AppUser.fromUid(rawData["initiator"]);
    final type = stringToAuditLogType(rawData["type"] ?? "unknown");
    final date = rawData["timestamp"]?.toDate() ?? DateTime.now();

    final data = rawData["data"] as Map<String, dynamic>;

    return AuditLogItem._(
        id: id,
        data: data,
        initiator: initiator!,
        type: type,
        date: date,
        houseHold: houseHold
    );
  }

  static const Map<AuditLogType, IconData> _auditLogIconMap = {
    AuditLogType.removeGroup: Icons.group_off,
    AuditLogType.addGroup: Icons.groups,
    AuditLogType.editGroup: Icons.edit,
    AuditLogType.addMember: Icons.group_add,
    AuditLogType.removeMember: Icons.group_remove,
    AuditLogType.addActivity: Icons.notes,
    AuditLogType.editActivity: Icons.edit_note,
    AuditLogType.sendMoney: Icons.payments,
    AuditLogType.promoteMember: Icons.add_moderator,
    AuditLogType.unknown: Icons.question_mark
  };


}

