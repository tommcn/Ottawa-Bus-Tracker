import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:apple_sign_in/apple_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

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
    createUserInBackend(globals.user.uid);

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
    createUserInBackend(globals.user.uid);
    return user.uid;
  }

  Future<FirebaseUser> signInWithApple({List<Scope> scopes = const []}) async {
    // 1. perform the sign-in request
    final AuthorizationResult result = await AppleSignIn.performRequests([
      AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])
    ]);

    // 2. check the result
    switch (result.status) {
      case AuthorizationStatus.authorized:
        final appleIdCredential = result.credential;
        final provider = new OAuthProvider(providerId: 'apple.com');

        final credential = provider.getCredential(
          idToken: String.fromCharCodes(appleIdCredential.identityToken),
          accessToken:
              String.fromCharCodes(appleIdCredential.authorizationCode),
        );
        final authResult = await _auth.signInWithCredential(credential);
        final firebaseUser = authResult.user;
        print("signInWithApple succeeded: ${firebaseUser.providerId}");
        print('${firebaseUser.uid}');
        globals.isLoggedIn = true;
        globals.user = firebaseUser;
        createUserInBackend(globals.user.uid);

        return firebaseUser;
      case AuthorizationStatus.error:
        print(result.error.toString());
        throw PlatformException(
          code: 'ERROR_AUTHORIZATION_DENIED',
          message: result.error.toString(),
        );

      case AuthorizationStatus.cancelled:
        throw PlatformException(
          code: 'ERROR_ABORTED_BY_USER',
          message: 'Sign in aborted by user',
        );
    }
    return null;
  }

  void createUserInBackend(String uid) async {
    final queryParameters = {
      "user_id": uid,
      "key": globals.backEndKey
    };
    final uri = Uri.http(globals.backend, '/adduser', queryParameters);
    await http.get(uri);
  }
}
