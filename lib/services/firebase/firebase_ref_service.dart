import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wgit/services/firebase/auth_service.dart';

/// Responsible for providing references in the cloud firestore
class RefService{
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  static DocumentReference get appRef => _firestore.doc("wg-it/public");

  static CollectionReference get usersRef => appRef.collection("users");

  /// The reference of the currently logged in user
  static DocumentReference? get currentUserRef => usersRef.doc(AuthService.user?.uid);

  static DocumentReference refOf({required String user}){
    return usersRef.doc(user);
  }


}