

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:wgit/services/firebase/auth_service.dart';

import 'app_user.dart';

class AppManager{

  static AppUser? currentUser;


  static Future ensureInitialized() async{
    AuthService.stateChange.listen((fb.User? user) {
      if(user != null){
        currentUser = AppUser.fromFirebaseUser(user);
      }else{
        currentUser = null;
      }
    });
  }
}