server {
  listen 80; # public server port
  listen 443 ssl;

  server_name socket.example.com www.socket.example.com;
  server_tokens off;
  include /etc/nginx/mime.types;

  ssl_certificate /etc/letsencrypt/live/socket.example.com/fullchain.pem; # managed by Certbot
  ssl_certificate_key /etc/letsencrypt/live/socket.example.com/privkey.pem; # managed by Certbot

  include /etc/letsencrypt/options-ssl-nginx.conf;
  ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

  if ($server_port = 80) { set $https_redirect 1; }
  if ($host ~ '^www\.') { set $https_redirect 1; }
  if ($https_redirect = 1) { return 301 https://socket.example.com$request_uri; }

  # FOR EMBED
  add_header X-Frame-Options "SAMEORIGIN";
  add_header X-XSS-Protection "1; mode=block";
  add_header X-Content-Type-Options "nosniff";
  add_header Strict-Transport-Security "max-age=31536000; includeSubdomains;";
  add_header Referrer-Policy "no-referrer-when-downgrade";

  client_body_buffer_size 25M;
  client_max_body_size 25M;

  gzip on;
  gzip_vary on;
  gzip_static on;
  gzip_min_length 1000;
  gzip_buffers 32 16k;
  gzip_comp_level 6;
  gzip_proxied any;
  gzip_types application/atom+xml application/javascript application/json application/rss+xml application/vnd.ms-fontobject application/x-web-app-manifest+json application/xhtml+xml application/xml font/opentype image/svg+xml image/x-icon text/css text/plain text/x-component;

  location / {
    proxy_pass http://127.0.0.1:5757/; # EXAMPLE
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  }
}
