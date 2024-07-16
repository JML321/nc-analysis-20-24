#!/bin/sh
# Replace the PORT placeholder in the nginx.conf file with the actual port
sed -i.bak "s|\$PORT|$PORT|g" /etc/nginx/conf.d/default.conf

# Remove the user directive from nginx.conf
sed -i.bak '/user  nginx;/d' /etc/nginx/nginx.conf

# Print the contents of the default.conf file for debugging
echo "Contents of /etc/nginx/conf.d/default.conf:"
cat /etc/nginx/conf.d/default.conf

# Start nginx
exec nginx -g 'daemon off;'