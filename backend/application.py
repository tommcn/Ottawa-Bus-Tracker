import os
import sys
import sqlite3
from flask import Flask, flash, jsonify, redirect, request
from tempfile import mkdtemp
from werkzeug.exceptions import default_exceptions, HTTPException, InternalServerError
import flask_sqlalchemy
import time
import datetime
# import direction

# THIS IS THE QUERY TO USE TO JOIN ALL THE TABLES FOR THE DATABASE FOR EFFICEIENCY
# SELECT routes.route_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_text_color, trips.trip_id, arrival_time, departure_time, stops.stop_id, stop_sequence, pickup_type, drop_off_type, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type, service_id, trip_headsign, direction_id, block_id, stop_id FROM stops JOIN stop_times ON stops.stop_id = stop_times.stop_id JOIN trips ON trips.trip_id = stop_times.trip_id JOIN routes ON trips.route_id = routes.route_id
# Configure application
app = Flask(__name__)

# Ensure templates are auto-reloaded
app.config["TEMPLATES_AUTO_RELOAD"] = True

# Ensure responses aren't cached
@app.after_request
def after_request(response):
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Expires"] = 0
    response.headers["Pragma"] = "no-cache"
    return response

# check to make sure that there is the correct number of arguments
if len(sys.argv) != 2:
    print("Usage: python application.py database.db")
    sys.exit()

dbFile = sys.argv[1]

# Turns a list of tuples into a dict for SQLite
def DICT_FACTORY(cursor, row):
    d = {}
    for index, col in enumerate(cursor.description):
        d[col[0]] = row[index]
    return d

# A function to execute SQL
def SQL_EXECUTE(statement, **params):
    con = sqlite3.connect(dbFile)
    con.row_factory = DICT_FACTORY
    c =  con.cursor()
    c.execute(statement, params)
    if statement.split(' ')[0].upper() != "SELECT":
        con.commit()
        toReturn = None 
    else:
        toReturn = c.fetchall()
    con.close()
    return toReturn

@app.route("/")
def index():
    """RETURN 404"""
    return HTTPException, 404

@app.route("/stops")
def stopsQuery():
    """RETURN all of the stops
    or in the case of getting a route id, return all of the stops for that route"""
    req_data = dict(request.args)
    if not req_data:
        select = SQL_EXECUTE("SELECT * FROM stops ")
    elif 'route_id' in req_data and 'stop_id' in req_data:
        select = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type FROM joined WHERE route_id = :route_id", route_id = req_data["route_id"])
    elif 'route_id' in req_data:
        select = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type FROM joined WHERE route_id = :route_id", route_id = req_data["route_id"])
    elif 'stop_id' in req_data:
        select = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type FROM joined WHERE stop_id = :stop_id", stop_id = req_data["stop_id"])
    elif 'distance' in req_data:
        select = SQL_EXECUTE("SELECT * FROM stops WHERE  stop_lon < :lon_in + :distance AND stop_lon > :lon_in - :distance AND stop_lat < :lat_in + :distance AND stop_lat > :lat_in - :distance ", distance = req_data['distance'], lon_in = req_data["lon"], lat_in = req_data["lat"])
    return jsonify(select), 200

@app.route("/time")
def timeQuery():
    """RETURN all of the times
    or in the case of getting a route id, return all of the stops for that route"""
    req_data = dict(request.args)
    if not req_data:
        select = SQL_EXECUTE("SELECT route_id, route_short_name, route_type, trip_id, trip_headsign, stop_name, arrival_time, stop_sequence, direction_id FROM joined")
    elif 'stop_id' in req_data:
        select = SQL_EXECUTE("SELECT route_id, route_short_name, route_type, trip_id, trip_headsign, stop_name, arrival_time, stop_sequence, direction_id FROM joined WHERE stop_id = :stop_id", stop_id = req_data["stop_id"])
    return jsonify(select), 200

@app.route("/shapes")
def shapesQuery():
    """RETURN all the shapes"""
    req_data = dict(request.args)
    if not req_data:
        select = SQL_EXECUTE("SELECT * FROM shapes")
    elif 'trip_id' in req_data:
        if 'get_shape_id' in req_data:
            if req_data['get_shape_id'] == "1":
                select = SQL_EXECUTE("SELECT DISTINCT shape_id FROM joined WHERE trip_id = :trip_id", trip_id = req_data["trip_id"])
        else:
            select = SQL_EXECUTE("SELECT * FROM trip_shapes_joined WHERE trip_id = :trip_id", trip_id = req_data["trip_id"])
    return jsonify(select), 200

# Commented out beacuse we are not using this rn
# @app.route("/direction")
# def directionQuery():
#     """RETURN the direction from a start location to an end location using the google
#     direction API"""
#     req_data = dict(request.args)
#     if not req_data:
#         return "Lacking any data", 404
#     elif 'start_lat' not in req_data or 'start_lon' not in req_data:
#         return "Lacking start data", 404
#     elif 'end_lat' not in req_data or 'end_lon' not in req_data:
#         return "Lacking end data", 404
#     else:
#         toReturn = direction.transit(str(req_data['start_lat'])+ ',' + str(req_data['start_lon']), str(req_data['end_lat'])+ ',' + str(req_data['end_lon']))
#     return jsonify(toReturn), 200

@app.route("/searchStop")
def searchStop():
    # RETURN a list of all stops that contain the query
    req_data = dict(request.args)
    if not req_data:
        return "Lacking any data", 404
    # Check if there is a query in the data
    elif 'query' not in req_data:
        return "Lacking query", 404
    elif req_data['query'] == '':
        return "No query", 404
    elif 'order' not in req_data:
        toReturn = SQL_EXECUTE("SELECT * FROM stops WHERE stop_name LIKE '%':query'%'", query = req_data['query'])
        print(req_data['query'])
    else:
        # If we want to order in a cerain way
        if req_data['order'] == "1":
            toReturn = SQL_EXECUTE("SELECT * FROM stops WHERE stop_name LIKE %:query% ORDER BY stop_name ASC", query = req_data['query'])
        # If we are looking for a favorite route
        elif req_data['order'] == "2":
            toReturn = SQL_EXECUTE("SELECT * FROM stops WHERE stop_name LIKE %:query% ORDER BY stop_name DESC'", query = req_data['query'])
        else:
            return "Invalid order", 404
    return jsonify(toReturn), 200

@app.route("/adduser")
def addUser():
    # ADD a user to the database
    req_data = dict(request.args)
    if not req_data:
        return "Lacking any data", 404
    # Check if there is a valid key in the data
    elif 'key' not in req_data:
        return "Lacking key", 403
    elif req_data['key'] == '':
        return "No key", 404
    elif int(SQL_EXECUTE("SELECT COUNT (key) FROM keys WHERE key = :key", key = req_data['key'])[0]['COUNT (key)']) < 1:
        return "Incorrect key", 403
    # Next look for user in the data
    elif 'user_id' not in req_data:
        return "No user_id", 404
    elif req_data['user_id'] == '':
        return "No user_id", 404
    elif int(SQL_EXECUTE("SELECT COUNT (user_id) FROM users WHERE user_id = :user_id", user_id = req_data['user_id'])[0]['COUNT (user_id)']) < 1:
        return "There is allready a user with the same UUID.", 403
    else:
        SQL_EXECUTE("INSERT INTO users(user_id) VALUES(:user_id)", user_id = req_data['user_id'])
    return "User added", 200


@app.route("/addfavorite")
def addFavorite():
    # ADD a user's favorite to the database
    req_data = dict(request.args)
    if not req_data:
        return "Lacking any data", 404
    # Check if there is a valid key in the data
    elif 'key' not in req_data:
        return "Lacking key", 403
    elif req_data['key'] == '':
        return "No key", 404
    elif int(SQL_EXECUTE("SELECT COUNT (key) FROM keys WHERE key = :key", key = req_data['key'])[0]['COUNT (key)']) < 1:
        return "Incorrect key", 403
    # Next look for user in the database
    elif 'user_id' not in req_data:
        return "No user_id", 404
    elif req_data['user_id'] == '':
        return "No user_id", 404
    elif int(SQL_EXECUTE("SELECT COUNT (user_id) FROM users WHERE user_id = :user_id", user_id = req_data['user_id'])[0]['COUNT (user_id)']) < 1:
        return "No user_id", 404
    elif 'type' not in req_data:
        return "No type", 404
    elif req_data['type'] == '':
        return "No type", 404
    elif 'id' not in req_data:
        return "No id", 404
    elif req_data['id'] == '':
        return "No id", 404
    else:
        # If we are looking to add to favorite stops
        if req_data['type'] == "0":
            SQL_EXECUTE("INSERT INTO favorite_stops(user_id, stop_id) VALUES(:user_id, :stop_id)", user_id = req_data['user_id'], stop_id = req_data['id'])
         # If we are looking to add to favorite routes
        elif req_data['type'] == "1":
            SQL_EXECUTE("INSERT INTO favorite_routes(user_id, route_id) VALUES(:user_id, :route_id)", user_id = req_data['user_id'], route_id = req_data['id'])
        else:
            return "Invalid type", 404
    return "Added " + req_data['favorite'] + "to " + req_data['user_id'] + "'s database.", 200


@app.route("/favorites")
def favoritesQuery():
    # RETURN the user's favorite routes or stops
    req_data = dict(request.args)
    if not req_data:
        return "Lacking any data", 404
    # Check if there is a valid key in the data
    elif 'key' not in req_data:
        return "Lacking key", 403
    elif req_data['key'] == '':
        return "No key", 404
    elif int(SQL_EXECUTE("SELECT COUNT (key) FROM keys WHERE key = :key", key = req_data['key'])[0]['COUNT (key)']) < 1:
        return "Incorrect key", 403
    # Next 2 ifs are to authenticate the user
    elif 'user_id' not in req_data:
        return "No user_id", 404
    elif req_data['user_id'] == '':
        return "No user_id", 404
    elif int(SQL_EXECUTE("SELECT COUNT (user_id) FROM users WHERE user_id = :user_id", user_id = req_data['user_id'])[0]['COUNT (user_id)']) < 1:
        return "No user_id", 404
    elif 'type' not in req_data:
        return "No favorite type given", 404
    else:
        # If we are looking for favorite stops
        if req_data['type'] == "0":
            toReturn = SQL_EXECUTE("SELECT stops_id FROM favorite_stops WHERE user_id = :user_id", user_id = req_data['user_id'])
        # If we are looking for a favorite route
        elif req_data['type'] == "1":
            toReturn = SQL_EXECUTE("SELECT route_id FROM favorite_routes WHERE user_id = :user_id", user_id = req_data['user_id'])
        else:
            return "Invalid type", 404
    return jsonify(toReturn), 200


@app.route("/routeInfo")
def routeInfo():
    # RETURN all stop_id, stop_lon, stop_lat and stop_name for every stop on a route (will use the nearset trip from the time of query) 
    req_data = dict(request.args)
    if not req_data:
        return "Lacking any data", 404
    # Check if there is a route
    elif 'route' not in req_data:
        return "Lacking route", 404
    elif req_data['route'] == '':
        return "No route", 404
    else:
        trip = SQL_EXECUTE("SELECT trip_id FROM joined WHERE route_short_name = :route_name AND stop_sequence = '1' AND arrival_time < :now ORDER BY arrival_time LIMIT 1", route_name = req_data['route'], now = datetime.datetime.now())
        print(trip)
        toReturn = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_lat, stop_lon, stop_name FROM joined WHERE trip_id = :trip_id ORDER BY stop_sequence", trip_id = trip[0]['trip_id'])
    return jsonify(toReturn), 200

def errorhandler(e):
    """Handle error"""
    if not isinstance(e, HTTPException):
        e = InternalServerError()
    return e.name, e.code


# Listen for errors
for code in default_exceptions:
    app.errorhandler(code)(errorhandler)

# Run the app
app.run(host="0.0.0.0")