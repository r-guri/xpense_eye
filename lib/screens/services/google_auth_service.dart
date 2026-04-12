import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

static Future<User?> signInWithGoogle() async {
  try {

    /// 🔥 FORCE LOGOUT BEFORE LOGIN (IMPORTANT)
    await _googleSignIn.signOut();

    final googleUser = await _googleSignIn.signIn();

    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    return userCredential.user;

  } catch (e) {
    // print("Google Login Error: $e");
    return null;
  }
}

  static Future signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}