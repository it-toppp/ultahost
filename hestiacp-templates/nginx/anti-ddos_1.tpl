server {
    listen      %ip%:%proxy_port%;
    server_name %domain_idn% %alias_idn%;
  
    error_log  /var/log/%web_system%/domains/%domain%.error.log error;

    include %home%/%user%/conf/web/%domain%/nginx.hsts.conf*;

    location / {
        limit_conn addr 8;
        limit_req zone=two burst=14 delay=7;
        proxy_pass      https://%ip%:%web_port%;
    }
        
    location ~* ^.+\.(%proxy_extensions%)$ {
            root           %sdocroot%;
            access_log     /var/log/%web_system%/domains/%domain%.log combined;
            access_log     /var/log/%web_system%/domains/%domain%.bytes bytes;
            expires        max;
            try_files      $uri @fallback;
    }

    location /error/ {
        alias   %home%/%user%/web/%domain%/document_errors/;
    }

    location @fallback {
        proxy_pass      https://%ip%:%web_port%;
    }

    location ~ /\.(?!well-known\/) {
       deny all;
       return 404;
    }

    proxy_hide_header Upgrade;

    include %home%/%user%/conf/web/%domain%/nginx.conf_*;
}
