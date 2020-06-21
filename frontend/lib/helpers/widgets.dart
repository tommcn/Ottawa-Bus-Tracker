import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:ottawa_bus_tracker/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:webfeed/webfeed.dart';
import 'package:location/location.dart';

import 'package:dio/dio.dart';

import 'package:http/http.dart' as http;

import '../globals.dart' as globals;
import 'transitions.dart';
import '../home.dart';

final backgroundPaint = LoginPainter();

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
      size: Size(400, 400),
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
          Text(
            isLogin ? "Welcome back" : "Lets get you started",
            style: Theme.of(context).textTheme.headline3,
            textAlign: TextAlign.left,
          ),
          Divider(
            height: isLogin ? 60 : 0,
            thickness: 0,
            color: Colors.transparent,
          ),
          Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              children: [
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
                      fontFamily:
                          GoogleFonts.roboto(fontWeight: FontWeight.w600)
                              .fontFamily,
                    ),
                  ),
                )
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
    double height = size.height;
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

Future getRoutes() async {
  var response = await http.get("http://127.0.0.1:5000/stops");
  return response;
}

Future getRSS() async {
  Response response =
      await Dio().get("https://www.octranspo.com/en/feeds/updates-en/");
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
              Text("Signed in as ${globals.user.email}"),
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

/*
class StopList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getRoutes(),
      builder: (context, result) {
        if (result.connectionState == ConnectionState.done) {
          var data = json.decode(result.data.body.toString());
          return ListView.separated(
            separatorBuilder: (context, index) => Divider(
              color: Colors.black,
              height: 0,
              thickness: 0.5,
            ),
            itemCount: data.length,
            itemBuilder: (context, index) {
              var filter = "sussex";
              return filter == null || filter == ""
                  ? new ListTile(
                      leading: Icon(Icons.transfer_within_a_station),
                      title: Text(data[index]["stop_name"]),
                      subtitle: Text(data[index]["stop_code"].toString()),
                      onTap: () {})
                  : data[index]["stop_name"]
                          .toLowerCase()
                          .contains(filter.toLowerCase())
                      ? ListTile(
                          leading: Icon(Icons.transfer_within_a_station),
                          title: Text(data[index]["stop_name"]),
                          subtitle: Text(data[index]["stop_code"].toString()),
                          onTap: () {})
                      : new Container();

              /*ListTile(
                  leading: Icon(Icons.transfer_within_a_station),
                  title: Text(data[index]["stop_name"]),
                  subtitle: Text(data[index]["stop_code"].toString()),
                  onTap: () {
                  },
                );  */
            },
          );
        } else {
          return LinearProgressIndicator(
            value: null,
          );
        }
      },
    );
  }
}
*/
class Map extends StatefulWidget {
  @override
  _MapState createState() => _MapState();
}

class _MapState extends State<Map> {
  GoogleMapController mapController;

  final LatLng _center = const LatLng(45.521563, -122.677433);

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
                markerId: MarkerId("curPos"),
                position: pos,
              ));
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: pos,
                  zoom: 14.0,
                ),
                markers: _markers,
              );
            } else {
              return Text("Failed");
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
