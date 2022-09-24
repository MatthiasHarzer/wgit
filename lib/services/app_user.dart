
import 'package:firebase_auth/firebase_auth.dart' as fb;

/// An user of the app
class AppUser{
  late final String uid;
  late final String displayName;
  late final String photoUrl;

  AppUser({required this.uid, required this.displayName, required this.photoUrl});

  AppUser.fromFirebaseUser(fb.User user){
    uid = user.uid;
    displayName = user.displayName!;
    photoUrl = user.photoURL!;
  }

  AppUser.fromJson(Map<String, dynamic> data){
    uid = data["uid"];
    displayName = data["displayName"];
    photoUrl = data["photoUrl"];
  }
}