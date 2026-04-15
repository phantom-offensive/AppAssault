#!/bin/bash
# Background auto-installer for Joomla 4.2.7
# Spawns a background process, then hands off to the real entrypoint.

(
    DB_HOST="${JOOMLA_DB_HOST:-joomla-db}"
    DB_NAME="${JOOMLA_DB_NAME:-joomla}"
    DB_USER="${JOOMLA_DB_USER:-joomla_user}"
    DB_PASS="${JOOMLA_DB_PASSWORD}"
    DB_PREFIX="jml_"
    SITE_NAME="WidgetCorp Intranet"
    ADMIN_USER="admin"
    ADMIN_PASS='P@ssw0rd123'
    ADMIN_EMAIL="admin@widgetcorp.local"

    echo "[auto-install] Waiting for web server to be up..."
    for i in $(seq 1 120); do
        if curl -sf http://localhost/ > /dev/null 2>&1; then
            echo "[auto-install] Web server is up"
            break
        fi
        sleep 3
    done

    # Check if already installed
    if [ -s /var/www/html/configuration.php ]; then
        echo "[auto-install] Joomla already installed, skipping"
        exit 0
    fi

    echo "[auto-install] Waiting for MySQL..."
    for i in $(seq 1 60); do
        if php -r "try { new PDO('mysql:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS'); echo 'ok'; } catch(Exception \$e) { exit(1); }" 2>/dev/null; then
            echo "[auto-install] MySQL is ready"
            break
        fi
        sleep 3
    done

    # Wait a bit more for entrypoint to finish copying files
    sleep 5

    echo "[auto-install] Importing Joomla database schema..."

    # Import schema SQL files, replacing the default prefix #__ with our prefix
    for sqlfile in /var/www/html/installation/sql/mysql/base.sql \
                   /var/www/html/installation/sql/mysql/extensions.sql \
                   /var/www/html/installation/sql/mysql/supports.sql; do
        if [ -f "$sqlfile" ]; then
            echo "[auto-install] Importing $(basename $sqlfile)..."
            sed "s/#__/${DB_PREFIX}/g" "$sqlfile" | \
                php -r "
                    \$pdo = new PDO('mysql:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS');
                    \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
                    \$sql = file_get_contents('php://stdin');
                    \$pdo->exec(\$sql);
                    echo 'OK\n';
                " 2>&1
        fi
    done

    echo "[auto-install] Creating admin user..."
    # Hash the admin password using Joomla's bcrypt format
    PASS_HASH=$(php -r "echo password_hash('$ADMIN_PASS', PASSWORD_BCRYPT);")

    php -r "
        \$pdo = new PDO('mysql:host=$DB_HOST;dbname=$DB_NAME', '$DB_USER', '$DB_PASS');
        \$pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

        // Insert admin user
        \$stmt = \$pdo->prepare(\"INSERT INTO ${DB_PREFIX}users (id, name, username, email, password, block, sendEmail, registerDate, lastvisitDate, activation, params, lastResetTime, resetCount, otpKey, otep, requireReset, authProvider) VALUES (?, ?, ?, ?, ?, 0, 1, NOW(), NOW(), 0, '{}', NOW(), 0, '', '', 0, '')\");
        \$stmt->execute([42, 'Super User', '$ADMIN_USER', '$ADMIN_EMAIL', '$PASS_HASH']);

        // Map admin to Super Users group (group_id=8)
        \$pdo->exec(\"INSERT INTO ${DB_PREFIX}user_usergroup_map (user_id, group_id) VALUES (42, 8)\");

        echo 'Admin user created\n';
    " 2>&1

    echo "[auto-install] Writing configuration.php..."
    SECRET=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1)

    cat > /var/www/html/configuration.php << PHPEOF
<?php
class JConfig {
    public \$offline = false;
    public \$offline_message = 'This site is down for maintenance.<br>Please check back again soon.';
    public \$display_offline_message = 1;
    public \$offline_image = '';
    public \$sitename = '$SITE_NAME';
    public \$editor = 'tinymce';
    public \$captcha = '0';
    public \$list_limit = 20;
    public \$access = 1;
    public \$frontediting = 1;
    public \$dbtype = 'mysqli';
    public \$host = '$DB_HOST';
    public \$user = '$DB_USER';
    public \$password = '$DB_PASS';
    public \$db = '$DB_NAME';
    public \$dbprefix = '${DB_PREFIX}';
    public \$dbencryption = 0;
    public \$dbsslverifyservercert = false;
    public \$dbsslkey = '';
    public \$dbsslcert = '';
    public \$dbsslca = '';
    public \$dbsslcipher = '';
    public \$secret = '$SECRET';
    public \$gzip = false;
    public \$error_reporting = 'default';
    public \$helpurl = 'https://help.joomla.org/proxy?keyref=Help{major}{minor}:{keyref}&lang={langcode}';
    public \$tmp_path = '/tmp';
    public \$log_path = '/var/www/html/administrator/logs';
    public \$live_site = '';
    public \$force_ssl = 0;
    public \$offset = 'UTC';
    public \$lifetime = 15;
    public \$session_handler = 'database';
    public \$shared_session = false;
    public \$mailonline = true;
    public \$mailer = 'mail';
    public \$mailfrom = '$ADMIN_EMAIL';
    public \$fromname = '$SITE_NAME';
    public \$massmailoff = false;
    public \$sendmail = '/usr/sbin/sendmail';
    public \$smtpauth = false;
    public \$smtpuser = '';
    public \$smtppass = '';
    public \$smtphost = 'localhost';
    public \$smtpsecure = 'none';
    public \$smtpport = 25;
    public \$caching = 0;
    public \$cachetime = 15;
    public \$cache_handler = 'file';
    public \$cache_platformprefix = false;
    public \$cors = false;
    public \$cors_allow_headers = 'Content-Type,X-Joomla-Token';
    public \$cors_allow_methods = '';
    public \$cors_allow_origin = '*';
    public \$debug = false;
    public \$debug_lang = false;
    public \$debug_lang_const = true;
    public \$MetaDesc = 'WidgetCorp Intranet Portal';
    public \$MetaAuthor = true;
    public \$MetaVersion = false;
    public \$MetaRights = '';
    public \$robots = '';
    public \$sitename_pagetitles = 0;
    public \$sef = true;
    public \$sef_rewrite = false;
    public \$sef_suffix = false;
    public \$unicodeslugs = false;
    public \$feed_limit = 10;
    public \$feed_email = 'none';
    public \$cookie_domain = '';
    public \$cookie_path = '';
    public \$asset_id = 1;
    public \$behind_loadbalancer = false;
}
PHPEOF

    chown www-data:www-data /var/www/html/configuration.php
    chmod 644 /var/www/html/configuration.php

    # Remove installation directory so Joomla doesn't redirect to installer
    rm -rf /var/www/html/installation

    echo "[auto-install] Joomla auto-installation complete!"

) &

# Hand off to the original Joomla entrypoint
exec /entrypoint.sh "$@"
