source includes.sh

search="$1"	#Alfred argument

echo "# search: ${search}"  >> /tmp/alfred.txt

iso_date_component=$(echo "$search" | awk -F'[[:space:]]+' '{print $1}')
timestamp_val=$(date -ju -f "%Y-%m-%dT%H:%M:%SZ" "$iso_date_component" +"%s" 2>/dev/null)
if [ $? -eq 0 ]; then

    echo "Valid ISO date. Timestamp: $timestamp_val" >> /tmp/alfred.txt

    echo -n "$timestamp_val"

    exit
else
    echo "Not an ISO Date" >> /tmp/alfred.txt
fi
