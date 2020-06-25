import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:ottawa_bus_tracker/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webfeed/webfeed.dart';
import 'package:location/location.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:apple_sign_in/apple_sign_in.dart';

import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';

import 'package:http/http.dart' as http;

import '../globals.dart' as globals;
import 'transitions.dart';
import '../home.dart';

final backgroundPaint = LoginPainter();

class AppleSignInAvailable {
  AppleSignInAvailable(this.isAvailable);
  final bool isAvailable;

  static Future<AppleSignInAvailable> check() async {
    return AppleSignInAvailable(await AppleSignIn.isAvailable());
  }
}

class LoginSignupPage extends StatefulWidget {
  @override
  LoginSignupPageState createState() => LoginSignupPageState();
}

class LoginSignupPageState extends State<LoginSignupPage> {
  String username;
  String password;
  String password2;

  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  void toggleLogin() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(400, 2200),
      painter: backgroundPaint,
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(16),
        children: [
          Divider(
            height: 10,
            thickness: 0,
            color: Colors.transparent,
          ),
          Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
                Text(
                  isLogin ? "Welcome back" : "Lets get you started",
                  style: Theme.of(context).textTheme.headline3,
                  textAlign: TextAlign.left,
                ),
                Divider(
                  height: isLogin ? 20 : 0,
                  thickness: 0,
                  color: Colors.transparent,
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                  child: TextFormField(
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter an email';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      username = value;
                    },
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.person),
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                  child: TextFormField(
                    obscureText: true,
                    validator: (value) {
                      if (value.isEmpty) {
                        return 'Please enter a password';
                      } else if (value.length <= 6) {
                        return 'Your password should be longer than 6 characters';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      password = value;
                    },
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.lock),
                      contentPadding:
                          EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                      labelText: "Password",
                    ),
                  ),
                ),
                if (!isLogin)
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: TextFormField(
                      obscureText: true,
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter a password';
                        } else if (password != password2) {
                          return 'Both passwords do not match';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        password2 = value;
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock),
                        contentPadding:
                            EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                        labelText: "Password (again) ",
                      ),
                    ),
                  ),
                SignInButton(Buttons.Email,
                    text: isLogin ? "Sign in with email" : "Sign up with email",
                    onPressed: () {
                  if (_formKey.currentState.validate()) {
                    var u;
                    if (isLogin) {
                      u = globals.auth
                          .signIn(username, password)
                          .whenComplete(() {
                        if (globals.isLoggedIn) {
                          Navigator.push(context, ScaleRoute(page: HomePage()));
                        } else {
                          Scaffold.of(context).showSnackBar(
                              SnackBar(content: Text("Invalid credentials")));
                        }
                      });
                    } else {
                      u = globals.auth
                          .signUp(username, password)
                          .whenComplete(() {
                        if (globals.isLoggedIn) {
                          Navigator.push(context, ScaleRoute(page: HomePage()));
                        } else {
                          Scaffold.of(context).showSnackBar(
                              SnackBar(content: Text("Invalid credentials")));
                        }
                      });
                    }
                    print(u);
                  }
                }),
                FlatButton(
                  onPressed: () {
                    toggleLogin();
                  },
                  child: Text(
                    isLogin
                        ? "I don't have an account"
                        : "I already have an account",
                    style: TextStyle(
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SignInButton(
                  Buttons.Apple,
                  onPressed: () {
                    globals.auth.signInWithApple().whenComplete(() {
                      if (globals.isLoggedIn) {
                        Navigator.push(context, ScaleRoute(page: HomePage()));
                      }
                    });
                  },
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
          )
        ],
      ),
    );
  }
}

class LoginPainter extends CustomPainter {
  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    // double height = size.height;
    double width = size.width;
    Paint paint = Paint();
    paint.color = Colors.red;

    var path = Path();
    path.moveTo(0, 180);
    path.lineTo(width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RSSFeed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: FutureBuilder(
        future: getRSS(),
        builder: (context, result) {
          if (result.connectionState == ConnectionState.done) {
            var feed = new RssFeed.parse(result.data.toString());
            return ListView.separated(
              separatorBuilder: (context, index) => Divider(
                color: Colors.black,
                height: 0,
                thickness: 0.5,
              ),
              itemCount: feed.items.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.warning),
                  title: Text(feed.items[index].title),
                  subtitle: Text(feed.items[index].pubDate),
                  onTap: () {
                    Navigator.push(
                        context,
                        ScaleRoute(
                            page: RSSDetail(
                          description: feed.items[index].description,
                        )));
                  },
                );
              },
            );
          } else {
            return LinearProgressIndicator(
              value: null,
            );
          }
        },
      ),
    );
  }
}

class RSSDetail extends StatelessWidget {
  final String description;
  RSSDetail({Key key, @required this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notification'),
      ),
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Html(data: description),
      )),
    );
  }
}

Future getNextTrips(String stopNo) async {
  print("Getting trips");
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Next Trips");
  myTrace.start();
  final queryParameters = {
    "appID": globals.ocAppId,
    "apiKey": globals.ocApiKey,
    "stopNo": stopNo,
    "format": "json"
  };
  final uri = Uri.http("api.octranspo1.com",
      '/v1.3/GetNextTripsForStopAllRoutes', queryParameters);
  print(uri);
  final response = await http.post(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();
  return response;
}

Future getStopInfo(String stopId) async {
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Stop Info");
  myTrace.start();
  final queryParameters = {
    "stop_id": stopId,
  };
  final uri = Uri.http(globals.backend, '/time', queryParameters);
  final response = await http.get(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();
  return response;
}

Future getRoutes() async {
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Routes");
  myTrace.start();
  var response = await http.get("${globals.backend}/stops");
  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();
  return response;
}

Future getRSS() async {
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get RSS Feed");
  myTrace.start();

  var dio = Dio();
  dio.interceptors.add(
      DioCacheManager(CacheConfig(baseUrl: "http://www.google.com"))
          .interceptor);
  Response response = await dio.get(
      "https://www.octranspo.com/en/feeds/updates-en/",
      options: buildCacheOptions(Duration(hours: 12)));
  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();

  return response;
}

Future getCloseStops(LatLng pos) async {
  final Trace myTrace =
      FirebasePerformance.instance.newTrace("Get Nearby Stops");
  myTrace.start();

  print("Getting");
  final queryParameters = {
    "distance": 0.005.toString(),
    "lon": pos.longitude.toString(),
    "lat": pos.latitude.toString(),
  };
  final uri = Uri.http(globals.backend, '/stops', queryParameters);
  print(uri);
  final response = await http.get(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();

  return response;
}

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          Row(children: [
            Text(
              "Dark Mode: ",
              style: TextStyle(fontSize: 24),
            ),
            Switch(
              value: Provider.of<AppStateNotifier>(context).isDarkMode,
              onChanged: (boolVal) {
                Provider.of<AppStateNotifier>(context, listen: false)
                    .updateTheme(boolVal);
              },
            ),
          ]),
          Row(
            children: [
              Text(
                  "Signed in as ${globals.user.email ?? 'an Apple ID user'}"),
            ],
          ),
          Row(
            children: [
              FlatButton(
                onPressed: () {
                  globals.auth.signOut();
                  Navigator.push(context, ScaleRoute(page: MyHomePage()));
                },
                child: Text("Log Out"),
              )
            ],
          ),
          Row(children: [
            RaisedButton(
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Ottawa Bus Tracker",
                );
              },
              child: Text("About"),
            )
          ]),
        ],
      ),
    );
  }
}

class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {

  Widget buildTable(List data) {
    var colls = <DataColumn>[];
    var dcell = <DataRow>[];

    for (var i = 0; i < data[0].length; i++) {
      colls.add(
        DataColumn(
          label: Text(
            data[0][i],
            style: TextStyle(fontStyle: FontStyle.italic),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      );
    }
    for (var i = 1; i < data.length; i++) {
      var cells = <DataCell>[];
      for (var j = 0; j < data[i].length; j++) {
        cells.add(DataCell(Text(data[i][j])));
      }
      dcell.add(
        DataRow(cells: cells),
      );
    }
    return DataTable(
      columns: colls,
      rows: dcell,
    );
  }

  GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getUserLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.data != null) {
              LatLng pos =
                  LatLng(snapshot.data.latitude, snapshot.data.longitude);
              Set<Marker> _markers = {};
              _markers.add(Marker(
                alpha: 0.5,
                markerId: MarkerId("curPos"),
                position: pos,
              ));
              return FutureBuilder(
                future: getCloseStops(
                    LatLng(snapshot.data.latitude, snapshot.data.longitude)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var data = json.decode(snapshot.data.body);
                    Set<Marker> _closeStations = {};
                    for (var s in data) {
                      _closeStations.add(Marker(
                          markerId: MarkerId(s['stop_id']),
                          position: LatLng(s['stop_lat'], s['stop_lon']),
                          onTap: () {
                            showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return FutureBuilder(
                                    future:
                                        getNextTrips(s['stop_code'].toString()),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.done) {
                                        var data =
                                            json.decode(snapshot.data.body);
                                        data = data[
                                            'GetRouteSummaryForStopResult'];
                                        var routes = data['Routes']['Route'];
                                        if (routes is! List) routes = [routes];
                                        return new AlertDialog(
                                          scrollable: true,
                                          title: Text(s['stop_name']),
                                          content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text("Stop Number: "),
                                                    Text(s['stop_code']
                                                        .toString()),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Text(
                                                      "Next Buses:",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .headline6,
                                                    )
                                                  ],
                                                ),
                                                if (routes != [null])
                                                  for (var route in routes)
                                                    Row(
                                                      children: [
                                                        Text(
                                                          route['RouteNo']
                                                                  .toString() +
                                                              "-" +
                                                              route['RouteHeading']
                                                                  .toString()
                                                                  .substring(
                                                                      0,
                                                                      route['RouteHeading'].length >
                                                                              20
                                                                          ? 20
                                                                          : null),
                                                        ),
                                                        Container(
                                                          child: IconButton(
                                                            padding: EdgeInsets.all(1),
                                                            visualDensity: VisualDensity.compact,
                                                            onPressed: () {
                                                            },
                                                            icon: Icon(
                                                              Icons.star_border,
                                                              color: Colors
                                                                  .yellow[600],
                                                            ),
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                if (data['Routes']['Route'] ==
                                                    null)
                                                  Text("No data")
                                              ]),
                                          actions: [
                                            OutlineButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: Text("Exit"),
                                            ),
                                          ],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        );
                                      } else {
                                        return AlertDialog(
                                          title: Text("Loading"),
                                          content: LinearProgressIndicator(
                                            value: null,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                });
                          }));
                    }
                    _closeStations.add(_markers.first);
                    return GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: pos,
                        zoom: 15.0,
                      ),
                      markers: _closeStations,
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              );
            } else {
              return Text(
                  "It seems that you have not allowed us to use your position");
            }
          } else {
            return CircularProgressIndicator();
          }
        });
  }
}

Future<LocationData> getUserLocation() async {
  Location location = new Location();

  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  LocationData _locationData;

  _serviceEnabled = await location.serviceEnabled();
  if (!_serviceEnabled) {
    _serviceEnabled = await location.requestService();
    if (!_serviceEnabled) {
      return null;
    }
  }

  _permissionGranted = await location.hasPermission();
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    if (_permissionGranted != PermissionStatus.granted) {
      return null;
    }
  }

  _locationData = await location.getLocation();
  return _locationData;
}
