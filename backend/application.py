import os
import sys
import sqlite3
from flask import Flask, flash, jsonify, redirect, request
from tempfile import mkdtemp
from werkzeug.exceptions import default_exceptions, HTTPException, InternalServerError
import flask_sqlalchemy
import time

# THIS IS THE QUERY TO USE TO JOIN ALL THE TABLES FOR THE DATABASE FOR EFFICEIENCY
# SELECT routes.route_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_text_color, trips.trip_id, arrival_time, departure_time, stops.stop_id, stop_sequence, pickup_type, drop_off_type, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type, service_id, trip_headsign, direction_id, block_id FROM stops JOIN stop_times ON stops.stop_id = stop_times.stop_id JOIN trips ON trips.trip_id = stop_times.trip_id JOIN routes ON trips.route_id = routes.route_id
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
    req_data = request.get_json()
    if not req_data:
        select = SQL_EXECUTE("SELECT * FROM stops ")
    elif 'route_id' in req_data and 'stop_id' in req_data:
        select = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type FROM joined WHERE route_id = :route_id", route_id = req_data["route_id"])
    elif 'route_id' in req_data:
        select = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type FROM joined WHERE route_id = :route_id", route_id = req_data["route_id"])
    elif 'stop_id' in req_data:
        select = SQL_EXECUTE("SELECT DISTINCT stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type FROM joined WHERE stop_id = :stop_id", stop_id = req_data["stop_id"])
    return jsonify(select), 200

@app.route("/time")
def timeQuery():
    """RETURN all of the times
    or in the case of getting a route id, return all of the stops for that route"""
    req_data = request.get_json()
    if not req_data:
        select = SQL_EXECUTE("SELECT route_id, route_short_name, route_type, trip_id, trip_headsign, stop_name, arrival_time, stop_sequence, direction_id FROM stop_times")
    elif 'stop_id' in req_data:
        select = SQL_EXECUTE("SELECT route_id, route_short_name, route_type, trip_id, trip_headsign, stop_name, arrival_time, stop_sequence, direction_id FROM joined WHERE stop_id = :stop_id", stop_id = req_data["stop_id"])
    return jsonify(select), 200

@app.route("/shapes")
def shapesQuery():
    """RETURN all the shapes"""
    req_data = request.get_json()
    if not req_data:
        select = SQL_EXECUTE("SELECT * FROM shapes")
    elif 'trip_id' in req_data:
        if 'get_shape_id' in req_data:
            if req_data['get_shape_id'] == 1:
                select = SQL_EXECUTE("SELECT shape_id FROM joined WHERE trip_id = :trip_id", trip_id = req_data["trip_id"])
        else:
            select = SQL_EXECUTE("SELECT * FROM trip_shapes_joined WHERE trip_id = :trip_id", trip_id = req_data["trip_id"])
    return jsonify(select), 200

def errorhandler(e):
    """Handle error"""
    if not isinstance(e, HTTPException):
        e = InternalServerError()
    return e.name, e.code


# Listen for errors
for code in default_exceptions:
    app.errorhandler(code)(errorhandler)

# Close the database when we are done with it
try:
    app.run()
except:
    con.close()
