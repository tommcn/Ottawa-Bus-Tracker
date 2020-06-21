import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_crashlytics/flutter_crashlytics.dart';
import 'dart:async';

import 'package:ottawa_bus_tracker/globals.dart' as globals;
import 'package:ottawa_bus_tracker/helpers/transitions.dart';
import 'package:ottawa_bus_tracker/helpers/widgets.dart';
import 'package:ottawa_bus_tracker/auth.dart';
import 'package:ottawa_bus_tracker/home.dart';

import 'package:provider/provider.dart';

AuthService _auth = AuthService();


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isInDebugMode = false;
  globals.auth = _auth;

  FlutterError.onError = (FlutterErrorDetails details) {
    if (isInDebugMode) {
      // In development mode simply print to console.
      FlutterError.dumpErrorToConsole(details);
    } else {
      // In production mode report to the application zone to report to
      // Crashlytics.
      Zone.current.handleUncaughtError(details.exception, details.stack);
    }
  };

  await FlutterCrashlytics().initialize();

  runZoned<Future<Null>>(() async {
    runApp(
  ChangeNotifierProvider<AppStateNotifier>(
    create: (context) => AppStateNotifier(),
    child: MyApp(),
  ),
);
  }, onError: (error, stackTrace) async {
    // Whenever an error occurs, call the `reportCrash` function. This will send
    // Dart errors to our dev console or Crashlytics depending on the environment.
    await FlutterCrashlytics().reportCrash(error, stackTrace, forceCrash: false);
  });
}

class AppStateNotifier extends ChangeNotifier {
  //
  bool isDarkMode = false;

  void updateTheme(bool isDarkMode) {
    this.isDarkMode = isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppStateNotifier>(
      builder: (context, appState, child) {
        return MaterialApp(
          title: "App",
          theme: ThemeData(
            primarySwatch: Colors.red,
            fontFamily:
                GoogleFonts.roboto(fontWeight: FontWeight.w100).fontFamily,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData.dark(),
          themeMode: appState.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: MyHomePage(),
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Column(
        children: <Widget>[
          Container(
            child: LoginSignupPage(),
          ),
          Divider(
            thickness: 2,
            height: 10,
            indent: 50,
            endIndent: 50,
          ),
          SignInButton(
            Buttons.Google,
            onPressed: () {
              globals.auth.signInWithGoogle().whenComplete(() {
                if (globals.isLoggedIn) {
                  Navigator.push(context, ScaleRoute(page: HomePage()));
                }
              });
            },
          ),
        ],
      ),
    );
  }
}
