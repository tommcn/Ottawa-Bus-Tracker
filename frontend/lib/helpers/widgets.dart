import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:intl/intl.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:ottawa_bus_tracker/main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:sprintf/sprintf.dart';
import 'package:url_launcher/url_launcher.dart';
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
Uint8List markerIconBytes;
double sliderVal = 0.005;
getBytesFromAsset(String path, int width) async {
  ByteData data = await rootBundle.load(path);
  ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  ui.FrameInfo fi = await codec.getNextFrame();
  markerIconBytes = (await fi.image.toByteData(format: ui.ImageByteFormat.png))
      .buffer
      .asUint8List();
}

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
                OutlineButton(
                  onPressed: () {
                    Navigator.push(context, ScaleRoute(page: HomePage()));
                  },
                  child: Text(
                    "Continue without signing in",
                    style: TextStyle(
                      color: Colors.black,
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

Future getNextTrips(String stopId) async {
  print("Getting trips");
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Next Trips");
  myTrace.start();
  final queryParameters = {
    "stop_id": stopId,
  };
  final uri = Uri.http(globals.backend, '/time', queryParameters);
  print(uri);
  final response = await http.get(uri);

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

Future getCloseStops(LatLng pos, double dist) async {
  final Trace myTrace =
      FirebasePerformance.instance.newTrace("Get Nearby Stops");
  myTrace.start();

  print("Gettings");
  print("uris:");
  final queryParameters = {
    "distance": dist.toString(),
    "lon": pos.longitude.toString(),
    "lat": pos.latitude.toString(),
  };
  print("uria:");
  final uri = Uri.http(globals.backend, '/stops', queryParameters);
  print("uri:");
  print(uri);
  final response = await http.get(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();
  print(":");

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
          Row(children: [
            RaisedButton(
              onPressed: () {
                showAboutDialog(
                  applicationVersion: "v1.0",
                  applicationLegalese: "Transit data provided by OC Transpo.",
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

  BitmapDescriptor pinLocationIcon;
  GoogleMapController mapController;
  double distance = 0.005;
  double slider_val = 0.005;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void initState() {
    print('INIT STATE-------------');
    super.initState();
    setCustomMapPin();
    getBytesFromAsset('assets/location_icon.png', 50);
  }

  void setCustomMapPin() async {
    print('assets/location_icon.png');
    pinLocationIcon = await BitmapDescriptor.fromAssetImage(
        ImageConfiguration(devicePixelRatio: 2.5, size: Size(0.5, 0.5)),
        'assets/location_icon.png');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getUserLocation(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            print("GOt location");
            if (snapshot.data != null) {
              print(snapshot.data);
              LatLng pos =
                  LatLng(snapshot.data.latitude, snapshot.data.longitude);
              globals.userPosition = pos;
              Set<Marker> _markers = {};
              _markers.add(Marker(
                alpha: 1,
                icon: BitmapDescriptor.fromBytes(markerIconBytes),
                markerId: MarkerId("curPos"),
                position: pos,
              ));
              return FutureBuilder(
                future: getCloseStops(
                    LatLng(snapshot.data.latitude, snapshot.data.longitude),
                    distance),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    print(snapshot.data);
                    String errorText;
                    
                    var data;
                    try {
                      data = json.decode(snapshot.data.body);
                    } catch (e) {
                      if (snapshot.data.body == "The database is not ready! Check again in 3 minutes")
                      {
                        errorText = "We are preparing the database for you, please come back in 3 minutes";
                      } else  {
                        errorText = "An error has occured, pleasy try again";
                      }
                      return Text(errorText);
                    }
                    
                    Set<Marker> _closeStations = {};
                    for (var s in data) {
                      _closeStations.add(Marker(
                          markerId: MarkerId(s['stop_id']),
                          position: LatLng(s['stop_lat'], s['stop_lon']),
                          onTap: () {
                            showDialogStop(context, s);
                          }));
                    }
                    _closeStations.add(_markers.first);
                    return Stack(children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        myLocationButtonEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target: pos,
                          zoom: 15.0,
                        ),
                        markers: _closeStations,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(children: [
                            Row(
                              children: [
                                Text(
                                  "  Distance:",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                CustomSlider(),
                                RaisedButton(
                                  color: Colors.red,
                                  textColor: Colors.white,
                                  child: Text("Apply"),
                                  onPressed: () {
                                    setState(() {
                                      distance = sliderVal;
                                    });
                                  },
                                )
                              ],
                            ),
                          ]),
                        ],
                      )
                    ]);
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

class CustomSlider extends StatefulWidget {
  @override
  _CustomSliderState createState() => _CustomSliderState();
}

class _CustomSliderState extends State<CustomSlider> {
  @override
  Widget build(BuildContext ctx) {
    return Slider(
        divisions: 10,
        min: 0.001,
        max: 0.02,
        value: sliderVal,
        onChanged: (double val) {
          setState(() {
            if (val <= 0.2)
              sliderVal = val;
            else
              sliderVal = 0.2;
          });
        });
  }
}

Future<LocationData> getUserLocation() async {
  print("Getting permission");
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
  print("Checking permissions");

  _permissionGranted = await location.hasPermission();
  print("Running ifs");
  if (_permissionGranted == PermissionStatus.denied) {
    _permissionGranted = await location.requestPermission();
    print("Requesting permisison");
    if (_permissionGranted != PermissionStatus.granted) {
      print("Failed");
      return null;
    }
  }

  print("Got permisison");
  _locationData = await location.getLocation();
  print(_locationData.toString());
  return _locationData;
}

class RoutesMenu extends StatelessWidget {
  final choices = ["See schedule", "Get Directions"];

  RoutesMenu(this.routeID, this.lat, this.lon);

  final String routeID;
  final double lat;
  final double lon;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert),
      elevation: 3.2,
      tooltip: 'More',
      onSelected: (selection) {
        switch (selection) {
          case "See schedule":
            print("Get schedule");
            print(routeID.toString());

            Navigator.push(
              context,
              ScaleRoute(
                page: RouteDetail(
                  routeID.toString(),
                  0,
                ),
              ),
            );
            break;

          case "Get Directions":
            print("Launching url");
            String url = sprintf(
                "https://www.google.com/maps/dir/?api=1&destination=%s,%s&travelmode=walking",
                [lat.toString(), lon.toString()]);
            url = Uri.encodeFull(url);
            _launchURL(url);
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return choices.map((choice) {
          return PopupMenuItem(
            value: choice,
            child: Text(choice),
          );
        }).toList();
      },
    );
  }
}

class RouteDetail extends StatefulWidget {
  RouteDetail(this.routeID, this.offset);
  final String routeID;
  final int offset;
  RouteDetailState createState() => RouteDetailState();
}

class RouteDetailState extends State<RouteDetail> {
  String routeID;
  int offset;
  Widget _scrollingList(ScrollController sc, data, _pc) {
    return ListView.builder(
      controller: sc,
      itemCount: data == null ? 1 : data.length + 1,
      itemBuilder: (BuildContext context, int i) {
        if (i == 0) {
          // return the header
          return new Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              child: Text(
                "Schedule",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_left),
                  onPressed: () {
                    print("Offset before: " + offset.toString());
                    setState(() {
                      offset--;
                    });
                    print("Offset: " + offset.toString());
                  },
                ),
                IconButton(
                  icon: Icon(Icons.arrow_right),
                  onPressed: () {
                    print("Offset before: " + offset.toString());
                    setState(() {
                      offset++;
                    });
                    print("Offset: " + offset.toString());
                  },
                )
              ],
            )
          ]);
        }
        i -= 1;

        return Center(
            child: Text(
          data[i]['stop_name'] +
              " - " +
              DateFormat.Hms()
                  .format(
                      DateTime.parse('2020-01-01T' + data[i]['arrival_time']))
                  .toString(),
        ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print("Building");
    BorderRadiusGeometry radius = BorderRadius.only(
      topLeft: Radius.circular(24.0),
      topRight: Radius.circular(24.0),
    );
    PanelController _pc = new PanelController();
    print("HI");
    if (offset == null)
      setState(() {
        routeID = widget.routeID;
        offset = widget.offset;
      });
    return Scaffold(
      appBar: AppBar(
        title: Text("Route " + routeID + " - Schedule"),
      ),
      body: Center(
        child: FutureBuilder(
            future: getRouteInfo(routeID, offset),
            builder: (BuildContext context, snapshot) {
              print("Herer");
              if (snapshot.connectionState == ConnectionState.done) {
                var data = json.decode(snapshot.data.body);
                return Stack(
                  children: [
                    FutureBuilder(
                      future: getPolyline(data[0]['shape_id'].toString()),
                      builder: (BuildContext context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          var decoded = json.decode(snapshot.data.body);
                          PolylinePoints polylinePoints = PolylinePoints();

                          List<PointLatLng> result = polylinePoints
                              .decodePolyline(decoded[0]['polyline']);
                          List<LatLng> _markers = [];

                          for (var i in result) {
                            _markers.add(LatLng(i.latitude, i.longitude));
                          }

                          Set<Marker> stops = Set();
                          for (var i in data) {
                            stops.add(
                              Marker(
                                infoWindow: InfoWindow(
                                    title: i['stop_name'],
                                    snippet: i['arrival_time']),
                                markerId: MarkerId(i['stop_id']),
                                position: LatLng(i['stop_lat'], i['stop_lon']),
                              ),
                            );
                          }
                          stops.add(
                            Marker(
                              icon: BitmapDescriptor.fromBytes(markerIconBytes),
                              markerId: MarkerId("upos"),
                              position: globals.userPosition,
                            ),
                          );
                          Polyline polyline = Polyline(
                            width: 1,
                            visible: true,
                            points: _markers,
                            polylineId: PolylineId(
                              decoded[0]['polyline'],
                            ),
                          );

                          Set<Polyline> polylines = Set();
                          polylines.add(polyline);

                          return GoogleMap(
                            padding: EdgeInsets.fromLTRB(0, 0, 0,
                                120), // move google logo up from pull down
                            markers: stops,
                            polylines: polylines,
                            myLocationButtonEnabled: false,
                            initialCameraPosition: CameraPosition(
                              zoom: 14,
                              target: stops.first.position,
                            ),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    ),
                    SlidingUpPanel(
                      borderRadius: radius,
                      controller: _pc,
                      panelBuilder: (ScrollController sc) =>
                          _scrollingList(sc, data, _pc),
                    ),
                  ],
                );
              } else {
                return CircularProgressIndicator();
              }
            }),
      ),
    );
  }
}

class SearchView extends StatefulWidget {
  final results;

  SearchView({this.results});

  @override
  SearchViewState createState() => SearchViewState();
}

class SearchViewState extends State<SearchView> {
  final myController = TextEditingController();
  ScrollController _listcontroller = new ScrollController();
  var results;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: myController,
          decoration: InputDecoration(
            icon: Icon(Icons.search),
            labelText: "Search",
          ),
        ),
        OutlineButton(
          onPressed: () {
            if (myController.text.toString() != "")
            getSearch(myController.text.toString()).then((res) {
              print('In Builder');
              var asJson;
              try {
                asJson = json.decode(res.body);
              } catch(e) {
                print(e);
                if (res == "The database is not ready! Check again in 3 minutes")
                {
                  asJson = "We are preparing the database for you, please come back in 3 minutes";
                } else  {
                  asJson = "An error has occured, please try again";
                }
                // asJson = "error";
              }              
              setState(() {
                results = asJson;
              });
            });
          },
          child: Text("Search"),
        ),
        Container(
          height: 300,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            controller: _listcontroller,
            shrinkWrap: true,
            children: [
              if (results is List)
              for (var res in results)
              ListTile(
                  leading: Icon(Icons.directions_bus),
                  title: Text(res['stop_name']),
                  subtitle: Text("Code: ${res['stop_code']}"),
                  trailing: IconButton(
                      icon: Icon(Icons.more_vert),
                      onPressed: () {
                        var s = res;
                        showDialogStop(context, s);
                      }),
                ),
              if (results is String)
                ListTile(
                    leading: Icon(Icons.directions_bus),
                    title: Text("Error"),
                    subtitle: Text(results),
                  ),
            ],
          ),
        )
      ],
    );
  }
}

Future getSearch(String query) async {
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Route Info");
  myTrace.start();

  print("Getting search info");
  final queryParameters = {'query': query};
  final uri = Uri.http(globals.backend, '/searchStop', queryParameters);
  print(uri);
  final response = await http.get(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();

  return response;
}

Future getRouteInfo(String routeID, int offset) async {
  print("Getting route info");
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Route Info");
  myTrace.start();

  final queryParameters = {'route': routeID, "offset": offset.toString()};
  final uri = Uri.http(globals.backend, '/routeStops', queryParameters);
  print(uri);
  final response = await http.get(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();

  return response;
}

Future getPolyline(String shapeId) async {
  final Trace myTrace = FirebasePerformance.instance.newTrace("Get Polyline");
  myTrace.start();

  print("Getting");
  final queryParameters = {'shape_id': shapeId};
  final uri = Uri.http(globals.backend, '/polylines', queryParameters);
  print(uri);
  final response = await http.get(uri);

  myTrace.setMetric("responce code", response.statusCode);
  myTrace.stop();

  return response;
}

_launchURL(url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

String format(DateTime value) {
  return "${value.hour}:${value.minute}:${value.second}";
}

void showDialogStop(context, s) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: getNextTrips(s['stop_id'].toString()),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
            var data;
              try {
                data = json.decode(snapshot.data.body);
              } catch (e)  {
                String errorText;
                if (snapshot.data.body == "The database is not ready! Check again in 3 minutes")
                {
                  errorText = "We are preparing the database for you, please come back in 3 minutes";
                } else  {
                  errorText = "An error has occured, please try again";
                }
                return AlertDialog(
                  title: Text("Error"),
                  content: Text(errorText),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                );
              }
              
              var testRoutes = [];
              testRoutes = data;
              var routes = [];

              for (int i = 0; i < testRoutes.length; i++) {
                bool dupFound = false;
                for (int j = 0; j < testRoutes.length; j++) {
                  if (testRoutes[i]['arrival_time'] ==
                          testRoutes[j]['arrival_time'] &&
                      testRoutes[i]['route_id'] == testRoutes[j]['route_id'] &&
                      i != j) {
                    dupFound = true;
                    print("foubd a duplicate");
                  }
                }
                if (!dupFound) routes.add(testRoutes[i]);
              }
              // routes = test_routes;
              return new AlertDialog(
                scrollable: true,
                title: Text(s['stop_name']),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    children: [
                      Text("Stop Number: "),
                      Text(s['stop_code'].toString()),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        "Next Buses:",
                        style: Theme.of(context).textTheme.headline6,
                      )
                    ],
                  ),
                  for (var route in routes)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              route['route_short_name'].toString() +
                                  "-" +
                                  route['trip_headsign'].toString().substring(
                                      0,
                                      route['trip_headsign'].length > 10
                                          ? 10
                                          : null),
                            ),
                            RoutesMenu(route['route_short_name'].toString(),
                                s['stop_lat'], s['stop_lon']),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              DateFormat.Hms()
                                  .format(DateTime.parse(
                                      '2020-01-01T' + route['arrival_time']))
                                  .toString(),
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  if (data == []) Text("No data")
                ]),
                actions: [
                  OutlineButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Exit"),
                  ),
                ],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              );
            } else {
              return AlertDialog(
                title: Text("Loading"),
                content: LinearProgressIndicator(
                  value: null,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              );
            }
          },
        );
      });
}
