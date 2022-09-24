import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wgit/services/firebase/auth_service.dart';

import '../types.dart';
import 'firebase_service.dart';

/// Responsible for providing references in the cloud firestore
class RefService{
  static Map<String, AppUser> _user_cache = {};

  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static DocumentReference get appRef => _firestore.doc("wg-it/public");

  static CollectionReference get usersRef => appRef.collection("users");

  static CollectionReference get householdsRef => appRef.collection("households");

  /// The reference of the currently logged in user
  static DocumentReference? get currentUserRef => FirebaseService.signedIn ? usersRef.doc(FirebaseService.user?.uid) : null;

  static DocumentReference refOf({required String user}){
    return usersRef.doc(user);
  }


  /// Gets users information by its user id
  static Future<AppUser?> resolveUid(String uid)async{
    if(_user_cache.keys.contains(uid)){
      return _user_cache[uid];
    }

    var doc = await usersRef.doc(uid).get();
    if(!doc.exists) return null;

    _user_cache[uid] = AppUser.fromDoc(doc);

    return _user_cache[uid];
  }

  /// Like [resolveUid] but for arrays
  static Future<Iterable<AppUser>> resolveUids(Iterable<String> uids)async{
    var futures = uids.map((uid) => resolveUid(uid));

    return (await Future.wait(futures)).whereType<AppUser>();
  }


}




















