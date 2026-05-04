import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db =FirebaseFirestore.instance;

  bool isValidEmail(String email){
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }
  bool isAtLeast13(DateTime dob){
    final now = DateTime.now();
    return now.year - dob.year >= 13;
  }
  Future<void> signup({
    required String firstName,
    required String lastName,
    required DateTime dob,
    required String email,
    required String password

})async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _db.collection("users").doc(cred.user!.uid).set({
      "firstName":firstName,"lastName":lastName,"dob":dob.toString().split(" ")[0],"email":email
    });
  }
  Future<bool> login(String email,String password) async{
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (cred.user != null) {
        await _setLoginState(true);
        return true;
      }

      return false;
    } on FirebaseAuthException catch (e) {
      print(e.message);
      return false;
    }

  }
  Future<Map<String,dynamic>> getProfile(String uid) async{
    final doc = await _db.collection("users").doc(uid).get();
    return doc.data()!;
  }
  Future<void> logout() async{
    await _setLoginState(false);
    await _auth.signOut();
  }
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("logged_in") ?? false;
  }


  Future<void> _setLoginState(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("logged_in", value);
  }

  User? get currentUser => _auth.currentUser;
}