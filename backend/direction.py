import googlemaps
import os
from datetime import datetime

#get the google api key from the environemnt variable
API_KEY = os.environ.get("DIRECTION_API_KEY")
print("Using key: " + API_KEY)
gmaps = googlemaps.Client(key=API_KEY)

# Geocoding an address
geocode_result = gmaps.geocode('1600 Amphitheatre Parkway, Mountain View, CA')

# Look up an address with reverse geocoding
reverse_geocode_result = gmaps.reverse_geocode((40.714224, -73.961452))

# Request directions via public transit
now = datetime.now()
directions_result = gmaps.directions("Sydney Town Hall",
                                     "Parramatta, NSW",
                                     mode="transit",
                                     departure_time=now)