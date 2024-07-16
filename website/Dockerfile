# Use an official nginx image as a base
FROM nginx:alpine

# Copy the website files into the container
COPY . /usr/share/nginx/html

# Copy the nginx configuration file
COPY default.conf /etc/nginx/conf.d/default.conf

# Copy a shell script to configure and run nginx
COPY run_nginx.sh /run_nginx.sh
RUN chmod +x /run_nginx.sh

# Ensure nginx can write to all necessary directories
RUN chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d
RUN touch /var/run/nginx.pid && \
    chown -R nginx:nginx /var/run/nginx.pid

# Expose the port
EXPOSE $PORT

# Start NGINX using the shell script
CMD ["/bin/sh", "-c", "/run_nginx.sh"]