#! /bin/bash
# 6/18/2017
# Script that pulls local weather data from Weather Underground and posts to ElasticSearch

# Set up variables used per script run time
timestamp=$(date -u +%FT%H:%M:%S)
index_name="wunderground-$(date +%F)"
server_ip=192.168.1.18
wunder_api_key="aaaaaaaaaaaa" // API key
state="ST" // State
city="City" // City in state

raw_json=$(curl -L --silent "http://api.wunderground.com/api/$wunder_api_key/conditions/q/$state/$city.json")

parsed_data=""
# You can add more json items to add but these are the usual ones
for data in weather temp_f relative_humidity wind_dir wind_mph wind_gust_mph pressure_mb dewpoint_f heat_index_f visibility_mi solarradiation precip_1hr_in precip_today_in
do	
# Pull out the fields you want and format them nice for elasticsearch
	parsed_data="$parsed_data $(echo "$raw_json"|grep "\"$data\""|sed -e 's/-999.00/0/' -e 's/--/0/' -e 's/\"NA\"/0/' -e 's/%//' -e 's/:\"\([0-9\.-]\+\)\"/:\1/')"
done

echo '{'$parsed_data'"@timestamp":"'$timestamp'"}'
# POST the data to the Elasticsearch cluster
curl --silent -XPOST -H "Content-Type: application/json" -d ''$(echo '{'$parsed_data'"@timestamp":"'$timestamp'" }'|sed 's/[ ]\+//g')'' "http://$server_ip:9200/$index_name/weather_event/" 2>&1 /dev/null
