#!/bin/bash
# Joomla setup: wait for auto-install to complete, then seed exploit data

echo "[*] Waiting for Joomla to be installed and ready..."
for i in $(seq 1 90); do
    # Check if Joomla is installed by looking for the API endpoint (not the install wizard)
    STATUS=$(curl -sf -o /dev/null -w "%{http_code}" http://joomla/api/index.php/v1/config/application?public=true 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "[+] Joomla is installed and API is responding"
        break
    fi
    # Also check if configuration.php exists by seeing if we get redirected to install
    MAIN_STATUS=$(curl -sf -o /dev/null -w "%{http_code}" http://joomla/ 2>/dev/null)
    if [ "$MAIN_STATUS" = "200" ] && [ "$i" -gt 30 ]; then
        echo "[+] Joomla main page responding (attempt $i)"
        break
    fi
    echo "    Attempt $i/90 - HTTP status: $STATUS (API), $MAIN_STATUS (main) - waiting..."
    sleep 5
done

# Extra wait for DB to be fully ready
sleep 10

# Wait for MySQL to be ready
echo "[*] Waiting for Joomla MySQL..."
for i in $(seq 1 30); do
    if mysql --skip-ssl -h joomla-db -u joomla_user -p"${JOOMLA_DB_PASSWORD}" joomla -e "SELECT 1" > /dev/null 2>&1; then
        echo "[+] MySQL is ready"
        break
    fi
    sleep 5
done

# Breadcrumb: add internal notes table with Gitea reference
mysql --skip-ssl -h joomla-db -u joomla_user -p"${JOOMLA_DB_PASSWORD}" joomla << SQL 2>/dev/null
CREATE TABLE IF NOT EXISTS jml_widget_secrets (
    id INT PRIMARY KEY,
    secret_name VARCHAR(100),
    secret_value VARCHAR(200)
);
INSERT IGNORE INTO jml_widget_secrets VALUES
(1, 'db_root_password', '${FLAG_JOOMLA}'),
(2, 'backup_encryption_key', 'W1dg3tC0rp_B4ckup_2026!'),
(3, 'api_master_key', 'sk_live_widgetcorp_prod_x7k9m2');
CREATE TABLE IF NOT EXISTS widget_internal_notes (
    id INT PRIMARY KEY AUTO_INCREMENT,
    note_date DATE,
    author VARCHAR(100),
    subject VARCHAR(200),
    body TEXT
);
INSERT INTO widget_internal_notes (note_date, author, subject, body) VALUES
('2026-03-01', 'mary.chen', 'Code migration update',
 'We are migrating legacy repos from Gitea (http://gitea.widgetcorp.local:9003) to GitLab. Self-registration is still enabled on Gitea - need to disable ASAP. Admin account: widgetadmin'),
('2026-03-10', 'david.wilson', 'phpMyAdmin access',
 'Reminder: phpMyAdmin is at port 9014. Auto-login is configured with the WordPress DB root creds.'),
('2026-02-15', 'john.smith', 'Security audit findings',
 'Pentest report flagged several issues across our infrastructure. Multiple services running with default or weak credentials. See Jenkins for full report.');
SQL

echo "[+] Joomla setup complete"
