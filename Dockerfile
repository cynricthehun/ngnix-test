FROM nginx

# Update our container with the latest updates
RUN apt-get update && apt-get upgrade --yes

# Remove the default configuration for nginx
COPY /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/backup_default.bak

# Copy the static html directory 
COPY static-html-directory /usr/share/nginx/html

# Copy ngnix configuration into conf.d
COPY nginx-configuration /etc/nginx/conf.d

# Expose port 80 
EXPOSE 80