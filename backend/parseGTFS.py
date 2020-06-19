import os
import sys
import flask_sqlalchemy
import sqlalchemy
import csv
import time

# THIS IS NOW OBCELETE BECASUSE WE FOUND A WAY OF USING DB READER TO PARSE CSV INTO A DB

# check to make sure that there is the correct number of arguments
if len(sys.argv) != 3:
    print("Usage: python parseGTFS.py folder database.db")
    sys.exit()

dbFile = sys.argv[2]
dataFolder = sys.argv[1]

# Configure the SQL database
engine = sqlalchemy.create_engine("sqlite:///"+ dbFile)

# A function to execute SQL
def SQL_EXECUTE(statement, **params):
    with engine.connect() as con:
        statement = sqlalchemy.text(statement)
        con.execute(statement, params)

def parseAgency():
    print("Begin parsing agency")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM agency")
    # open the csv
    openCSV = open(dataFolder + "/agency.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO agency(agency_id, agency_name, agency_url, agency_timezone, agency_lang, agency_phone, agency_fare_url, agency_email) VALUES(:agency_id, :agency_name, :agency_url, :agency_timezone, :agency_lang, :agency_phone, :agency_fare_url, :agency_email)",
         agency_id = line['agency_id'], agency_name = line['agency_name'], agency_url = line['agency_url'], agency_timezone= line['agency_timezone'], agency_lang = line['agency_lang'], agency_phone = line['agency_phone'], agency_fare_url = line['agency_fare_url'], agency_email = line['agency_email'])

    openCSV.close()
    print("Done parsing agency", time.time() - start_time, "to run")

def parseAttributions():
    print("Begin parsing attributions")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM attributions")
    # open the csv
    openCSV = open(dataFolder + "/attributions.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO agency(attribution_id, agency_id, route_id, trip_id, organization_name, is_producer, is_operator, is_authority, attribution_url, attribution_email, attribution_phone) VALUES(:attribution_id, :agency_id, :route_id, :trip_id, :organization_name, :is_producer, :is_operator, :is_authority, :attribution_url, :attribution_email, :attribution_phone)",
         attribution_id = line['attribution_id'], agency_id = line['agency_id'], route_id= line['route_id'], trip_id = line['trip_id'], organization_name = line['organization_name'], is_producer = line['is_producer'], is_operator = line['is_operator'], is_authority = line['is_authority'], attribution_url = line['attribution_url'], attribution_email = line['attribution_email'], attribution_phone = line['attribution_phone'])

    openCSV.close()
    print("Done parsing attributions", time.time() - start_time, "to run")

def parseCalendar():
    print("Begin parsing calendar")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM calendar")
    # open the csv
    openCSV = open(dataFolder + "/calendar.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO calendar(service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date) VALUES(:service_id,:monday,:tuesday,:wednesday,:thursday,:friday,:saturday,:sunday,:start_date,:end_date)",
         service_id = line['service_id'], monday = line['monday'], tuesday= line['tuesday'], wednesday = line['wednesday'], thursday = line['thursday'], friday = line['friday'], saturday = line['saturday'], sunday = line['sunday'], start_date = line['start_date'], end_date = line['end_date'])

    openCSV.close()
    print("Done parsing calendar", time.time() - start_time, "to run")

def parseCalendar_Dates():
    print("Begin parsing calendar dates")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM calendar_dates")
    # open the csv
    openCSV = open(dataFolder + "/calendar_dates.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO calendar_dates(service_id,date,exception_type) VALUES(:service_id,:date,:exception_type)",
         service_id = line['service_id'], date = line['date'], exception_type= line['exception_type'])
    openCSV.close()

    print("Done parsing calendar dates", time.time() - start_time, "to run")

def parseFare_Attributes():
    print("Begin parsing fare attributes")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM fare_attributes")
    # open the csv
    openCSV = open(dataFolder + "/fare_attributes.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO fare_attributes(fare_id,price,currency_type,payment_method,transfers,agency_id,transfer_duration) VALUES(:fare_id,:price,:currency_type,:payment_method,:transfers,:agency_id,:transfer_duration)",
         fare_id = line['fare_id'], price = line['price'], currency_type= line['currency_type'], payment_method = line['payment_method'], transfers = line['transfers'], agency_id = line['agency_id'], transfer_duration = line['transfer_duration'])

    openCSV.close()
    print ("Done parsing fare attributes:", time.time() - start_time, "to run")

def parseFare_Rules():
    print("Begin parsing fare rules")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM fare_rules")
    # open the csv
    openCSV = open(dataFolder + "/fare_rules.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO fare_rules(fare_id,route_id,origin_id,destination_id,contains_id) VALUES(:fare_id,:route_id,:origin_id,:destination_id,:contains_id)",
         fare_id = line['fare_id'], route_id = line['route_id'], origin_id= line['origin_id'], destination_id = line['destination_id'], contains_id = line['contains_id'])

    openCSV.close()
    print ("Done parsing fare rules:", time.time() - start_time, "to run")

def parseFeed_Info():
    print("Begin parsing feed info")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM feed_info")
    # open the csv
    openCSV = open(dataFolder + "/feed_info.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO feed_info(feed_publisher_name,feed_publisher_url,feed_lang,default_lang,feed_start_date, feed_end_date, feed_version, feed_contact_email, feed_contact_url) VALUES(:feed_publisher_name,:feed_publisher_url,:feed_lang,:default_lang,:feed_start_date, :feed_end_date, :feed_version, :feed_contact_email, :feed_contact_url)",
         feed_publisher_name = line['feed_publisher_name'], feed_publisher_url = line['feed_publisher_url'], feed_lang= line['feed_lang'], default_lang = line['default_lang'], feed_start_date = line['feed_start_date'], feed_end_date = line['feed_end_date'], feed_version = line['feed_version'], feed_contact_email = line['feed_contact_email'], feed_contact_url = line['feed_contact_url'])

    openCSV.close()
    print ("Done parsing feed info:", time.time() - start_time, "to run")

def parseFrequencies():
    print("Begin parsing frequencies")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM frequencies")
    # open the csv
    openCSV = open(dataFolder + "/frequencies.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO frequencies(trip_id,start_time,end_time) VALUES(:trip_id,:start_time,:end_time,:headway_secs,:exact_times)",
         trip_id = line['trip_id'], start_time = line['start_time'], end_time= line['end_time'], headway_secs = line['headway_secs'], exact_times = line['exact_times'])

    openCSV.close()
    print ("Done parsing frequencies:", time.time() - start_time, "to run")

def parseLevels():
    print("Begin parsing levels")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM levels")
    # open the csv
    openCSV = open(dataFolder + "/levels.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO levels(level_id,level_index,level_name) VALUES(:level_id,:level_index,:level_name)",
         level_id = line['level_id'], level_index = line['level_index'], level_name= line['level_name'])

    openCSV.close()
    print ("Done parsing levels:", time.time() - start_time, "to run")

def parsePathways():
    print("Begin parsing pathways")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM pathways")
    # open the csv
    openCSV = open(dataFolder + "/pathways.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO pathways(pathway_id,from_stop_id,to_stop_id,pathway_mode,is_bidirectional, length, traversal_time, stair_count, max_slope, min_width, signposted_as, reversed_signposted_as) VALUES(:pathway_id,:from_stop_id,:to_stop_id,:pathway_mode,:is_bidirectional, :length, :traversal_time, :stair_count, :max_slope, :min_width, :signposted_as, :reversed_signposted_as)",
         pathway_id = line['pathway_id'], from_stop_id = line['from_stop_id'], to_stop_id= line['to_stop_id'], pathway_mode = line['pathway_mode'], is_bidirectional = line['is_bidirectional'], length = line['length'], traversal_time = line['traversal_time'], stair_count = line['stair_count'], max_slope = line['max_slope'], min_width = line['min_width'], signposted_as = line['signposted_as'], reversed_signposted_as = line['reversed_signposted_as'])

    openCSV.close()
    print ("Done parsing pathways:", time.time() - start_time, "to run")

def parseRoutes():
    print("Begin parsing routes")
    start_time = time.time()
    SQL_EXECUTE("DELETE FROM routes")
    # open the csv
    openCSV = open(dataFolder + "/routes.txt", 'r')

    # make a dictreader
    dataReader = csv.DictReader(openCSV)

    for line in dataReader:
        SQL_EXECUTE("INSERT INTO routes(route_id,agency_id,route_short_name,route_long_name,route_desc, route_type, route_url, route_color, route_text_color, route_sort_order, continuous_pickup, continuous_drop_off) VALUES(:route_id,:agency_id,:route_short_name,:route_long_name,:route_desc, :route_type, :route_url, :route_color, :route_text_color, :route_sort_order, :continuous_pickup, :continuous_drop_off)",
         route_id = line['route_id'], agency_id = line['agency_id'], route_short_name= line['route_short_name'], route_long_name = line['route_long_name'], route_desc = line['route_desc'], route_type = line['route_type'], route_url = line['route_url'], route_color = line['route_color'], route_text_color = line['route_text_color'], route_sort_order = line['route_sort_order'], continuous_pickup = line['continuous_pickup'], continuous_drop_off = line['continuous_drop_off'])

    openCSV.close()
    print ("Done parsing routes:", time.time() - start_time, "to run")