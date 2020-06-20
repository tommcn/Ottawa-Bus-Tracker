import os
import sys
import sqlalchemy
from flask import Flask, flash, jsonify, redirect, request
from tempfile import mkdtemp
from werkzeug.exceptions import default_exceptions, HTTPException, InternalServerError
import flask_sqlalchemy
import time

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

# Configure the SQL database
engine = sqlalchemy.create_engine("sqlite:///"+ dbFile)

# A function to execute SQL
def SQL_EXECUTE(statement, **params):
    con = engine.connect()
    statement = sqlalchemy.text(statement)
    toReturn = con.execute(statement, params)
    return toReturn

@app.route("/")
def index():
    """RETURN 404"""
    return HTTPException, 404

@app.route("/stops")
def stops():
    """RETURN all of the stops
    or in the case of getting a route id, return all of the stops for that route"""
    req_data = request.get_json()
    if not req_data:
        select = SQL_EXECUTE("SELECT * FROM stops ")
    select = SQL_EXECUTE("SELECT * FROM stops")
    result = []
    for row in select:
        result.append(dict(row))
    return jsonify(result), 200

@app.route("/join")
def join():
    """COMPILE all of the tables together to make running more efficient"""
    print("Begin joining")
    start_time = time.time()
    select = SQL_EXECUTE("SELECT routes.route_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_text_color, trips.trip_id, arrival_time, departure_time, stops.stop_id, stop_sequence, pickup_type, drop_off_type, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type, service_id, trip_headsign, direction_id, block_id FROM stops JOIN stop_times ON stops.stop_id = stop_times.stop_id JOIN trips ON trips.trip_id = stop_times.trip_id JOIN routes ON trips.route_id = routes.route_id")
    for row in select:
        SQL_EXECUTE("INSERT INTO joined(route_id, route_short_name, route_long_name, route_desc, route_type, route_url, route_text_color, trip_id, arrival_time, departure_time, stop_id, stop_sequence, pickup_type, drop_off_type, stop_id, stop_code, stop_name, stop_desc, stop_lat, stop_lon, zone_id, stop_url, location_type, route_id, service_id, trip_id, trip_headsign, direction_id, block_id) VALUES(:route_id, :route_short_name, :route_long_name, :route_desc, :route_type, :route_url, :route_text_color, :trip_id, :arrival_time, :departure_time, :stop_id, :stop_sequence, :pickup_type, :drop_off_type, :stop_id, :stop_code, :stop_name, :stop_desc, :stop_lat, :stop_lon, :zone_id, :stop_url, :location_type, :route_id, :service_id, :trip_id, :trip_headsign, :direction_id, :block_id)"
        , route_id = row['route_id'], route_short_name = row['route_short_name'], route_long_name = row['route_long_name'], route_desc = row['route_desc'], route_type = row['route_type'], route_url = row['route_url'], route_text_color = row['route_text_color'], trip_id = row['trip_id'], arrival_time = row['arrival_time'], departure_time = row['departure_time'], stop_id = row['stop_id'], stop_sequence = row['stop_sequence'], pickup_type = row['pickup_type'], drop_off_type = row['drop_off_type'], stop_code = row['stop_code'], stop_name = row['stop_name'], stop_desc = row['stop_desc'], stop_lat = row['stop_lat'], stop_lon = row['stop_lon'], zone_id = row['zone_id'], stop_url = row['stop_url'], location_type = row['location_type'], service_id = row['service_id'], trip_headsign = row['trip_headsign'], direction_id = row['direction_id'], block_id = row['block_id'])
    return "DONE JOINING IN {{time.time() - start_time}}", 200 


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
