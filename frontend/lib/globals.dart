library my_prj.globals;
import 'package:firebase_auth/firebase_auth.dart';
import 'auth.dart';


bool isLoggedIn = false;
FirebaseUser user; 
AuthService auth;
String backend = '192.168.1.26:5000';

String ocAppId = "KEY";
String ocApiKey = "KEY";
String backEndKey = "KEY";


