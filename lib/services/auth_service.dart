import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // গুগল দিয়ে লগইন
  Future<User?> signInWithGoogle() async {
    try {
      // ১. গুগল সাইন-ইন প্রম্পট দেখানো
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // ইউজার যদি ব্যাক বাটন চেপে ক্যানসেল করে

      // ২. অথেন্টিকেশন ডিটেইলস নেওয়া
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // ৩. ফায়ারবেস ক্রেডেনশিয়াল তৈরি করা
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // ৪. ফায়ারবেসে সাইন-ইন করা
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

  // লগআউট
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print("Sign-Out Error: $e");
    }
  }

  // বর্তমান ইউজার চেক
  User? get currentUser => _auth.currentUser;

  // ইউজারের স্টেট পরিবর্তন পর্যবেক্ষণ (main.dart-এ ব্যবহারের জন্য)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}