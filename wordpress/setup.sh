#!/bin/bash
# Wait for WordPress to be ready then configure it
echo "[*] Waiting for WordPress..."
for i in $(seq 1 60); do
    if curl -sf http://wordpress/ > /dev/null 2>&1; then
        echo "[+] WordPress is ready"
        break
    fi
    sleep 5
done

# Install WordPress
echo "[*] Installing WordPress..."
curl -sf "http://wordpress/wp-admin/install.php?step=2" \
    -d "weblog_title=Widget+Corp+Blog&user_name=admin&admin_password=${WP_ADMIN_PASSWORD}&admin_password2=${WP_ADMIN_PASSWORD}&admin_email=admin@widgetcorp.local&blog_public=0&pw_weak=1" \
    2>/dev/null || true

sleep 2

# Fix WordPress URL to use localhost:9001
echo "[*] Fixing WordPress URL..."
for i in $(seq 1 30); do
    if mysql -h wordpress-db -u wp_user -p"${WP_DB_PASSWORD}" wordpress -e "UPDATE wp_options SET option_value='http://localhost:9001' WHERE option_name IN ('siteurl','home');" 2>/dev/null; then
        echo "[+] WordPress URL set to http://localhost:9001"
        break
    fi
    sleep 3
done

# Create a private post with the flag
curl -sf -u "admin:${WP_ADMIN_PASSWORD}" \
    "http://wordpress/xmlrpc.php" \
    -H "Content-Type: text/xml" \
    -d "<?xml version=\"1.0\"?><methodCall><methodName>wp.newPost</methodName><params><param><value><int>1</int></value></param><param><value><string>admin</string></value></param><param><value><string>${WP_ADMIN_PASSWORD}</string></value></param><param><value><struct><member><name>post_title</name><value><string>Internal Security Notes</string></value></member><member><name>post_content</name><value><string>Security audit completed. Reference: ${FLAG_WORDPRESS}. All findings remediated except media upload handler.</string></value></member><member><name>post_status</name><value><string>private</string></value></member></struct></value></param></params></methodCall>" \
    2>/dev/null || true

sleep 1

# Breadcrumb: DB management notes referencing phpMyAdmin
curl -sf -u "admin:${WP_ADMIN_PASSWORD}" \
    "http://wordpress/xmlrpc.php" \
    -H "Content-Type: text/xml" \
    -d "<?xml version=\"1.0\"?><methodCall><methodName>wp.newPost</methodName><params><param><value><int>1</int></value></param><param><value><string>admin</string></value></param><param><value><string>${WP_ADMIN_PASSWORD}</string></value></param><param><value><struct><member><name>post_title</name><value><string>DB Maintenance Reminder</string></value></member><member><name>post_content</name><value><string>Remember to clean up old revisions in the database. Use phpMyAdmin at http://phpmyadmin.widgetcorp.local:9014 to access the DB directly. Same MySQL root creds as wp-config.php. Also need to check the Tomcat deployment configs - the app server at port 9004 has been acting up.</string></value></member><member><name>post_status</name><value><string>draft</string></value></member></struct></value></param></params></methodCall>" \
    2>/dev/null || true

# Breadcrumb: Tomcat deployment notes
echo "[*] Adding internal notes to DB..."
curl -sf -u "admin:${WP_ADMIN_PASSWORD}" \
    "http://wordpress/xmlrpc.php" \
    -H "Content-Type: text/xml" \
    -d "<?xml version=\"1.0\"?><methodCall><methodName>wp.newPost</methodName><params><param><value><int>1</int></value></param><param><value><string>admin</string></value></param><param><value><string>${WP_ADMIN_PASSWORD}</string></value></param><param><value><struct><member><name>post_title</name><value><string>Tomcat Deployment Creds</string></value></member><member><name>post_content</name><value><string>Tomcat Manager at port 9004. Default creds still active: tomcat/tomcat. AJP connector exposed on port 9009. Filed as SEC-2026-003.</string></value></member><member><name>post_status</name><value><string>draft</string></value></member></struct></value></param></params></methodCall>" \
    2>/dev/null || true

echo "[+] WordPress setup complete"
