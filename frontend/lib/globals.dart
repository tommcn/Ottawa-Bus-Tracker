library my_prj.globals;
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';

bool isLoggedIn = false;
FirebaseUser user; 
AuthService auth;
String backend = '127.0.0.1:5000';