import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../services/firebase/auth_service.dart';
import '../services/firebase/firebase_service.dart';
import 'app_user.dart';

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

