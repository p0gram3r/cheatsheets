## curl
```
-L  --location  --- If the server reports that the requested page has moved to a different location (indicated with a
                    Location: header and a 3XX response code), this option will make curl redo the request on  the  new
                    place.
-s  --silent    --- Silent or quiet mode. Don't show progress meter or error messages.  Makes Curl mute. It will still
                    output the data you ask for, potentially even to the terminal/stdout unless you redirect it.
-S --show-error --- When used with "-s", it makes curl show an error message if it fails. 
```


## netstat
- prints network connections, routing tables, interface statistics, masquerade connections, and multicast memberships

```
-n  --- show numerical addresses
-t  --- disply tcp connections
-u  --- disply udp connections
-l  --- show only listening sockets
-p  --- show name and PID of programs
-r  --- display kernel routing table
-e  --- identical to -r (on some systems)
-s  --- print network statistics
```


## tr
- used to transform or delete characters from a string
- whitespaces might be affected as well!

```
# convert string from uppercase to lowercase
echo "Hello World" | tr [:upper:] [:lower:]

# translate character
echo "Hello World" | tr [:space:] '\n'

# remove specific characters
echo "Hello World" | tr -d 'lo'

# replace those characters with the second character that don’t match with the first character value
echo "Hello World" | tr -c 'lo' 'x'

# remove all non-digit characters from a string
echo "Phone No: 985634854" | tr -cd '0-9'
```
