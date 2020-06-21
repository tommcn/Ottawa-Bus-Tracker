import googlemaps
import os
from datetime import datetime
import pprint

#get the google api key from the environemnt variable
API_KEY = os.environ.get("DIRECTION_API_KEY")
print("Using key: " + API_KEY)
gmaps = googlemaps.Client(key=API_KEY)

# Request directions via public transit

def transit(start, end):
    now = datetime.now()
    directions_result = gmaps.directions(start,end,mode="transit",departure_time=now)
    return directions_result