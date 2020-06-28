import os
import sys
import sqlite3
import polyline
import ast

# check to make sure that there is the correct number of arguments
if len(sys.argv) != 2:
    print("Usage: python shapes_to_polyline.py database.db")
    sys.exit()

dbFile = sys.argv[1]

# SQL_EXECUTE
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

# A variable to set the percision of the polyline
precision = 5

# Get the number of shapes to itterate over
n = SQL_EXECUTE("SELECT COUNT(DISTINCT shape_id) FROM shapes")[0]["COUNT(DISTINCT shape_id)"]
shape_id = SQL_EXECUTE("SELECT DISTINCT shape_id FROM shapes")

# clear the polylines table
SQL_EXECUTE("DELETE FROM polylines")
# Itterate over all of the shapes
for i in range(n):
    string = ""
    segments = SQL_EXECUTE("SELECT shape_pt_lat, shape_pt_lon FROM shapes WHERE shape_id = :shape_id ORDER BY shape_pt_sequence", shape_id = shape_id[i]['shape_id'])
    for l in range(len(segments)):
        string = string + ', (' + str(segments[l]['shape_pt_lat']) + ',' + str(segments[l]['shape_pt_lon']) + ')'
    string = string[2:]
    string = list(ast.literal_eval(string))
    donePolyline = polyline.encode(string, precision)
    SQL_EXECUTE("INSERT INTO polylines(shape_id, polyline) VALUES(:shape_id, :polyline)", shape_id = shape_id[i]['shape_id'], polyline = donePolyline)