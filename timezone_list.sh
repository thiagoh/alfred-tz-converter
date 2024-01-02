source includes.sh

search="$1"	#Alfred argument

# Argument can be empty or have 1, 2 or 3 space separated components
# empty: use current time on current date at local timezone
# one component: <time> or <city> - use given time on current date at local timezone or sarch for city
# two components: <date modification> <time> - use given time on calculated date at local timezone
# three components: <source timezone> <date modification> <time> - use given time on calculated date at given source timezone

# <time> can have following formats:
# HH (assume minutes to be zero)
# HH:MM
# HHMM

# <date modification> can have following formats:
# t (short for today)
# today
# tm (short for tomorrow)
# tomorrow
# DD (assume current month and year)
# MMDD (assume current year)
# YYMMDD
# DDd (DD days added to today)

# <source timezone> can have following formats:
# CITY (to be looked up in /usr/share/zoneinfo.default)

comp1=$(echo "$search" | awk -F'[[:space:]]+' '{print $1}')
comp2=$(echo "$search" | awk -F'[[:space:]]+' '{print $2}')
comp3=$(echo "$search" | awk -F'[[:space:]]+' '{print $3}')

echo "# search: ${search}"  >> /tmp/alfred.txt
echo "# comp1 / comp2 / comp3: ${comp1} / ${comp2} / ${comp3}"   >> /tmp/alfred.txt

if [[ "$comp1" =~ ^([01]?[0-9]|2[0-3])(:[0-5][0-9](:[0-5][0-9])?)?(([pP]|[aA])[mM])?$ ]]; then
  comp1_is_time=1
else
  comp1_is_time=0
fi

if [[ "$comp2" =~ ^([01]?[0-9]|2[0-3])(:[0-5][0-9](:[0-5][0-9])?)?(([pP]|[aA])[mM])?$ ]]; then
  comp2_is_time=1
else
  comp2_is_time=0
fi
echo "# comp1 is time: ${comp1_is_time}" >> /tmp/alfred.txt
echo "# comp2 is time: ${comp2_is_time}" >> /tmp/alfred.txt

timestamp_component=$(echo "$search" | awk -F'[[:space:]]+' '{print $1}')
timestamp_component=$(echo $timestamp_component | awk '{printf "%.0f\n", $1}')
timestamp_component_length=${#timestamp_component}
iso_date_val=$(date -u -r "$timestamp_component" +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null)

if [ $? -eq 0 ] && [ $timestamp_component_length -gt 8 ]; then

    echo "Valid timestamp. ISO 8601 date: $iso_date_val" >> /tmp/alfred.txt

    #Populate Alfred results with Timezones list
    echo '<?xml version="1.0"?>
        <items>'
    echo "<!--$sortkey-->\
        <item arg=\"$iso_date_val\" valid=\"yes\">\
            <title>Timestamp to ISO DateTime</title>\
            <subtitle>$iso_date_val</subtitle>\
            <icon>./icon.png</icon>\
        </item>"
    echo '</items>'

    exit
else
    echo "Not a timestamp. Trying out something else" >> /tmp/alfred.txt
fi

iso_date_component=$(echo "$search" | awk -F'[[:space:]]+' '{print $1}')
timestamp_val=$(date -ju -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date_component" +"%s" 2>/dev/null)
if [ $? -eq 0 ]; then

    echo "Valid ISO date. Timestamp: $timestamp_val" >> /tmp/alfred.txt

    #Populate Alfred results with Timezones list
    echo '<?xml version="1.0"?>
        <items>'
    echo "<!--$sortkey-->\
        <item arg=\"$timestamp_val\" valid=\"yes\">\
            <title>ISO DateTime to Timestamp</title>\
            <subtitle>$timestamp_val</subtitle>\
            <icon>./icon.png</icon>\
        </item>"
    echo '</items>'

    exit
else
    echo "Not a timestamp. Trying out something else" >> /tmp/alfred.txt
fi


if [ -n "$comp3" ] && [ $comp2_is_time -eq 1 ]; then
  # string is like "Recife 01:00:00 PM"
  echo "<City> <Time> [AM/PM descriptor]" >> /tmp/alfred.txt

  # convert <City> <Time> [AM/PM descriptor] to <City> <Time>[AM/PM descriptor]
  if [[ "$comp3" =~ ^([aA]|[pP])[mM]$ ]] ; then
    comp2=$comp2$comp3
    comp3=""
  fi
fi

if [ -n "$comp2" ]; then
  if [ $comp2_is_time -eq 1 ] ; then

    # string is like "Recife 01:00:00PM"
    echo "<City> <Time>[AM/PM descriptor]" >> /tmp/alfred.txt

    source_timezone_search=$comp1
    date_modification_search='t'
    time_search=$comp2

    # set flat to PM to true if hour is in format "1AM"
    if [[ "$comp2" =~ ^.+[pP][mM]$ ]] ; then
      set_to_pm=1
    fi

    # remove last two digits (AM|PM)
    if [[ "$comp2" =~ ^.+([pP]|[aA])[mM]$ ]] ; then
      time_search=$(echo "$time_search" | rev | cut -c 3- | rev)
    fi

    # set flat to PM to true if hour is in format "1 AM"
    if [[ "$comp3" =~ ^[pP][mM]$ ]] ; then
      set_to_pm=1
    fi

    echo "set_to_pm: $set_to_pm" >> /tmp/alfred.txt

  elif [ $comp1_is_time -eq 1 ] ; then

    # string is like "01:00:00 PM"

    echo "<Time> [AM/PM descriptor]" >> /tmp/alfred.txt

    source_timezone_search=''
    date_modification_search='t'
    time_search=$comp1

    # set flat to PM to true if hour is in format "1AM"
    if [[ "$comp2" =~ ^[pP][mM]$ ]] ; then
      set_to_pm=1
    fi

    # remove last two digits (AM|PM)
    if [[ "$comp2" =~ ^.+([pP]|[aA])[mM]$ ]] ; then
      time_search=$(echo "$time_search" | rev | cut -c 3- | rev)
    fi

    # set flat to PM to true if hour is in format "1 AM"
    if [[ "$comp3" =~ ^[pP][mM]$ ]] ; then
      set_to_pm=1
    fi

    echo "set_to_pm: $set_to_pm" >> /tmp/alfred.txt

  else

    echo "Unknown entry: $search" >> /tmp/alfred.txt

  fi

elif [ -n "$comp1" ] && [ $comp1_is_time -eq 1 ]; then

  # string is like "01:00:00PM"

  echo "<Time>[AM/PM descriptor]" >> /tmp/alfred.txt

  source_timezone_search=''
  date_modification_search='t'
  time_search=$comp1

  # set flat to PM to true if hour is in format "1PM"
  if [[ "$time_search" =~ ^.+[pP][mM]$ ]] ; then
    set_to_pm=1
  fi

  # remove last two digits (AM|PM)
  if [[ "$time_search" =~ ^.+([pP]|[aA])[mM]$ ]] ; then
    time_search=$(echo "$time_search" | rev | cut -c 3- | rev)
  fi

  echo "Time in available timezones: $time_search" >> /tmp/alfred.txt
  echo "set_to_pm: $set_to_pm" >> /tmp/alfred.txt

else

  if [[ "$comp1" =~ ^[[:alpha:]]+$ ]]; then
    # string is like "Recife 01:00:00PM"
    echo "<City>" >> /tmp/alfred.txt
    city_search=$comp1
  else
    echo "Unknown entry: $search" >> /tmp/alfred.txt
    exit
  fi
fi

echo "# source_timezone_search: ${source_timezone_search}" >> /tmp/alfred.txt
echo "# date_modification_search: ${date_modification_search}" >> /tmp/alfred.txt
echo "# time_search: ${time_search}" >> /tmp/alfred.txt

#
# create source timezone
#
if [ -n "$source_timezone_search" ]; then
    timezone_to_convert=$(cat "$timezone_file" | awk -v query="$source_timezone_search" -F'|' 'tolower($1) ~ tolower(query) {print $3}' )
    if [ -n "$timezone_to_convert" ]; then
        timezone_offset_to_convert=$(TZ=$timezone_to_convert date +%z)
    fi
fi

if [ -z "$timezone_offset_to_convert" ]; then
    timezone_offset_to_convert=$(date +%z)
    timezone_to_convert=$(date +%Z)
fi

echo "# timezone_offset: ${timezone_offset_to_convert}" >> /tmp/alfred.txt
echo "# timezone: ${timezone_to_convert}" >> /tmp/alfred.txt

#
# create source date
#
if [ 'tm' = "$date_modification_search" -o 'tomorrow' = "$date_modification_search" ]
then
    dateToConvert=$(date -v +1d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]+d$ ]]
then
    dateToConvert=$(date -v +${date_modification_search} +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{1,2}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{3}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search:0:1}m -v ${date_modification_search:1}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{4}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search:0:2}m -v ${date_modification_search:2}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{5}$ ]]
then
    dateToConvert=$(date -v 20${date_modification_search:0:1}y -v ${date_modification_search:1:2}m -v ${date_modification_search:3}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{6}$ ]]
then
    dateToConvert=$(date -v 20${date_modification_search:0:2}y -v ${date_modification_search:2:2}m -v ${date_modification_search:4}d +%Y%m%d)
elif [[ "$date_modification_search" =~ ^[0-9]{8}$ ]]
then
    dateToConvert=$(date -v ${date_modification_search:0:4}y -v ${date_modification_search:4:2}m -v ${date_modification_search:6}d +%Y%m%d)
else
    # fallback that also covers 't' and 'today'
    dateToConvert=$(date +%Y%m%d)
fi

#
# create source time
#
if [[ $time_search =~ ^[0-9:]+$ ]] ; then

    # HH
    if [[ $time_search =~ ^[0-9]{2}$ ]]; then
        #echo "2 digits" >> /tmp/alfred.txt
        time_search=${time_search}:00
    fi
    echo "1 time_search: $time_search" >> /tmp/alfred.txt

    # H (pad to 0H)
    if [[ $time_search =~ ^[0-9]{1}$ ]]; then
        #echo "1 digit" >> /tmp/alfred.txt
        time_search=0${time_search}:00
    fi

    echo "2 time_search: $time_search" >> /tmp/alfred.txt

    # H: (pad to 0H:)
    if [[ $time_search =~ ^[0-9]{1}\: ]]; then
        #echo "1 digit" >> /tmp/alfred.txt
        time_search=0${time_search}
    fi

    echo "3 time_search: $time_search" >> /tmp/alfred.txt

    if [[ $time_search =~ ^[0-2]?[0-9]:[0-5][0-9]$ ]]; then
      # pad seconds
      time_search=${time_search}:00
    fi

    echo "4 time_search: $time_search" >> /tmp/alfred.txt

    hour=${time_search:0:2}
    hour="$((10#$hour))"
    echo "hour: $hour" >> /tmp/alfred.txt

    if [ $hour -le 12 ] && [ $set_to_pm -eq 1 ]; then
      hour=$((($hour + 12) % 24))
      echo "new hour: $hour" >> /tmp/alfred.txt
      time_search=$hour:${time_search:3}
    fi

    echo "5 time_search: $time_search" >> /tmp/alfred.txt

    time_search=${time_search//:}

    echo "6 time_search: $time_search" >> /tmp/alfred.txt

    timeToConvert=${time_search}

    time_search="" # undefine it
else
    timeToConvert=$(date +%H%M)00
    time_search="" # undefine it
fi

#Populate Alfred results with Timezones list
echo '<?xml version="1.0"?>
    <items>'

if [[ "$TIME_FORMAT" = "24h" ]]; then
    TIME_FORMAT_STR='%0k:%M:%S'
fi

if [[ "$TIME_FORMAT" = "12h" ]]; then
    TIME_FORMAT_STR='%-l:%M:%S %p'
fi

if [[ "$TIME_FORMAT" = "Both" ]]; then
    # Both - 24hr (12hr)
    TIME_FORMAT_STR='%0k:%M:%S (%-l:%M:%S %p)'
fi

sortkey=1

while IFS='|' read -r city country timezone country_code telephone_code favourite
    do

    # skip comment line
    if [[ "$city" =~ ^[[:space:]]*\# ]]
    then
        continue
    fi

    if [[ "$favourite" == "0" ]]
    then
        favourite_string="⭐️ •"
    else
        favourite_string=""
    fi

    timezone_to_convert_offset=$(TZ=$timezone_to_convert date +"%z")
    current_timezone_offset=$(TZ=$timezone date +"%z")
    # echo "Current timezone: $timezone / Offset: $current_timezone_offset " >> /tmp/alfred.txt

    if [ "$timezone" = "$timezone_to_convert" ] ; then
        sourceTimezone_string="👉 "
    elif [ "$timezone_to_convert_offset" = "$current_timezone_offset" ] ; then
        sourceTimezone_string="🎯 "
    else
        sourceTimezone_string=""
    fi

    setTimeOptionArguments="-jf %Y%m%d%H%M%S%z $dateToConvert$timeToConvert$timezone_offset_to_convert"

    # UTC hours needs swap the sign (minus)->(plus) and vice-versa
    timezoneOpposite="$timezone"

    if [[ "$timezone" == *UTC-* ]]; then
        timezoneOpposite="${timezone/-/+}"
    elif [[ "$timezone" == *UTC+* ]]; then
        timezoneOpposite="${timezone/+/-}"
    fi

    city_time=$(TZ=$timezoneOpposite date $setTimeOptionArguments +"$TIME_FORMAT_STR")
    city_date=$(TZ=$timezoneOpposite date $setTimeOptionArguments +"%A, %d %B %Y" )
    iso_date_val=$(TZ=$timezoneOpposite date $setTimeOptionArguments +"%Y-%m-%dT%H:%M:%SZ" )

    #Determine flag icon
    country_flag="$(echo "$country" | tr '[A-Z]' '[a-z]')"
    country_flag="${country_flag// /_}"
    flag_icon="$country_flag.png"
    if [[ ! -e "./flags/$flag_icon" ]]; then
        flag_icon="_no_flag.png"
    fi

    # It shall be possible to disable sorting
    # in fact, it means we're assiging an incremaental sort key
    if [[ ! "$SORTING" == "n" ]]
    then
        # we start the output with a sort key to simply pipe the result to 'sort'
        # we sort first by favourite, second by time ascending, third by city name
        sortkey=$favourite$(TZ=$timezone date $setTimeOptionArguments +%Y%m%d%H%M )"$city"
    else
        sortkey=$(printf "%03d" $(( 10#$sortkey + 1 )))
    fi

    ITEM_ARG="$iso_date_val"

    if [[ "$city" =~ ${city_search:-.} ]]; then
        echo "<!--$sortkey-->\
              <item arg=\"$ITEM_ARG\" valid=\"yes\">\
                  <title>$sourceTimezone_string$city: $city_time • ${country}</title>\
                  <subtitle>$favourite_string $city_date • $iso_date_val</subtitle>\
                  <icon>./flags/$flag_icon</icon>\
              </item>"
    fi
done < "$timezone_file" | sort

echo '</items>'

# exit
