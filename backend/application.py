import os
import sys
import sqlalchemy
from flask import Flask, flash, jsonify, redirect, request
from tempfile import mkdtemp
from werkzeug.exceptions import default_exceptions, HTTPException, InternalServerError
import flask_sqlalchemy

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
    with engine.connect() as con:
        statement = sqlalchemy.text(statement)
        return con.execute(statement, params)

@app.route("/")
def index():
    """RETURN 404"""
    return HTTPException, 404

@app.route("/stops")
def stops():
    """RETURN all of the stops"""
    select = SQL_EXECUTE("SELECT * FROM stops")
    for row in select:
        print(row)
    return jsonify(SQL_EXECUTE("SELECT * FROM stops")), 200 


def errorhandler(e):
    """Handle error"""
    if not isinstance(e, HTTPException):
        e = InternalServerError()
    return e.name, e.code


# Listen for errors
for code in default_exceptions:
    app.errorhandler(code)(errorhandler)

app.run()
