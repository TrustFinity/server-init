## Intro

This is a shell script for setting up Laravel Production environment on Ubuntu 14.04 system （ [Spinoff from](https://github.com/summerblue/laravel-ubuntu-init) ).

> [Link](https://phphub.org/topics/2814)

## Software list

* [Ubuntu Server 16]
* Git
* PHP 7.1
* Nginx
* MySQL
* Sqlite3
* Composer
* Node 6 (With Yarn, PM2, Bower, Grunt, and Gulp)
* Redis
* Memcached
* Beanstalkd

## Installation

1). Pull down the script

My Ubuntu 16.04

```
wget https://raw.githubusercontent.com/TrustFinity/server-init/master/deploy-16.sh -O deploy.sh
chmod +x deploy.sh
```

Ubuntu 14.04

```
wget https://raw.githubusercontent.com/TrustFinity/server-init/master/deploy.sh
chmod +x deploy.sh
```


2). Config MySQL password

`vi deploy.sh` edit your password:

```
# Configure
MYSQL_ROOT_PASSWORD="{{--Your Password--}}"
MYSQL_NORMAL_USER="estuser"
MYSQL_NORMAL_USER_PASSWORD="{{--Your Password--}}"
```

3). Start install

Run the shell script:

```
./deploy.sh
```

> Note: You must run as `root`.

It will finish installation with this message:

```
--
--
It's Done.
Mysql Root Password: xxxxxx
Mysql Normal User: xxxxxxx
Mysql Normal User Password: xxxxxx
--
--
```

## After installation

### 1. Web root permission

Nginx using `deploi` user, in order to have a correct permission, you should change the owner of the directory:

```
cd /data/www/{YOU PROJECT FOLDER NAME}
chown deploi:deploi -R ./
```

### 2. Add a site

Here is a Nginx config file template for Laravel Project, you should put it at `/etc/nginx/sites-enabled` folder.

For example `/etc/nginx/sites-enabled/phphub.org`:

```
server {
    listen 80;
    server_name {{---YOU-DOMAIN-NAME---}};
    root "{{---YOU-PROJECT-FOLDER---}}";

    index index.html index.htm index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log /data/log/nginx/{{---YOU-PROJECT-NAME---}}-access.log;
    error_log  /data/log/nginx/{{---YOU-PROJECT-NAME---}}-error.log error;

    sendfile off;

    client_max_body_size 100m;

    include fastcgi.conf;

    location ~ /\.ht {
        deny all;
    }

    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  $document_root$fastcgi_script_name;
        include        fastcgi_params;
    }
}
```

Restart Nginx when you done:

```
service nginx restart
```


