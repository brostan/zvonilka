#!/bin/bash

echo "Ждем запуска контейнера..."
sleep 8

echo "Настраиваем SSL конфигурацию Nginx..."
docker exec docker-web-1 bash -c 'cat > /etc/nginx/sites-available/default << '"'"'EOF'"'"'
server {
    listen 80;
    listen [::]:80;
    server_name zvonilka.duckdns.org;

    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name zvonilka.duckdns.org;

    ssl_certificate /etc/letsencrypt/live/zvonilka.duckdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/zvonilka.duckdns.org/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    root /usr/share/jitsi-meet;
    index index.html;

    location ~ ^/([^/]+)/\$ {
        rewrite ^/(.*)\$ / break;
    }

    location / {
        ssi on;
        try_files \$uri \$uri/ /index.html;
    }

    location /xmpp-websocket {
        proxy_pass http://prosody:5280/xmpp-websocket;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        tcp_nodelay on;
    }

    location /http-bind {
        proxy_pass http://prosody:5280/http-bind;
        proxy_set_header Host \$host;
    }

    location /external_api.js {
        alias /usr/share/jitsi-meet/libs/external_api.min.js;
    }

    location ~ ^/(libs|css|static|images|fonts|lang|sounds|connection_optimization|\\.well-known)/(.*)\$ {
        add_header '"'"'Access-Control-Allow-Origin'"'"' '"'"'*'"'"';
    }
}
EOF
'

echo "Проверяем конфигурацию Nginx..."
docker exec docker-web-1 nginx -t

if [ $? -eq 0 ]; then
    echo "Перезагружаем Nginx..."
    docker exec docker-web-1 nginx -s reload
    echo "✓ SSL успешно настроен!"
else
    echo "✗ Ошибка в конфигурации Nginx"
    exit 1
fi
