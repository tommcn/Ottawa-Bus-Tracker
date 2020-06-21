import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'globals.dart' as globals;

final FirebaseAuth _auth = FirebaseAuth.instance;
final GoogleSignIn googleSignIn = GoogleSignIn();

class AuthService {
  FirebaseUser loggedInUser;
  final FirebaseAuth _fbAuth = FirebaseAuth.instance;

  Future<String> signInWithGoogle() async {
    print("Signing in google");
    GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount == null) {
      return null;
    }

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult authResult = await _auth.signInWithCredential(credential);
    final FirebaseUser user = authResult.user;

    loggedInUser = user;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);

    print("signInWithGoogle succeeded: $user");
    globals.isLoggedIn = true;
    globals.user = user;

    return 'signInWithGoogle succeeded: $user';
  }

  void signOutGoogle() async {
    await googleSignIn.signOut();
    globals.isLoggedIn = false;
    globals.user = null;

    print("User Sign Out");
  }

  Future<void> signOut() async {
    globals.isLoggedIn = false;
    globals.user = null;
    return _fbAuth.signOut();
  }

  Future<String> signIn(String email, String password) async {
    AuthResult result;
    try {
      result = await _fbAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
    FirebaseUser user = result.user;
    globals.isLoggedIn = true;
    globals.user = user;
    return user.uid;
  }

  Future<String> signUp(String email, String password) async {
    AuthResult result;
    try {
      result = await _fbAuth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      print(e.toString());
      return e.toString();
    }
    FirebaseUser user = result.user;
    globals.isLoggedIn = true;
    globals.user = user;
    return user.uid;
  }
}
