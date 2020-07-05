library my_prj.globals;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'auth.dart';


bool isLoggedIn = false;
FirebaseUser user; 
AuthService auth;
String backend = "ottawa-bus-tracker-database.herokuapp.com";

LatLng userPosition = LatLng(0.0, 0.0);

String ocAppId = "KEY";
String ocApiKey = "KEY";
String backEndKey = "KEY";
