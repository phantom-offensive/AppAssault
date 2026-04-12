#!/bin/bash
# Wait for Joomla and its DB to be ready

echo "[*] Waiting for Joomla DB..."
for i in $(seq 1 60); do
    if curl -sf http://joomla/ > /dev/null 2>&1; then
        echo "[+] Joomla is responding"
        break
    fi
    sleep 5
done

sleep 30

# Wait for MySQL to be ready
echo "[*] Waiting for Joomla MySQL..."

for i in $(seq 1 30); do
    if mysql -h joomla-db -u joomla_user -p"${JOOMLA_DB_PASSWORD}" joomla -e "SELECT 1" > /dev/null 2>&1; then
        echo "[+] MySQL is ready"
        break
    fi
    sleep 5
done

# Breadcrumb: add internal notes table with Gitea reference
mysql -h joomla-db -u joomla_user -p"${JOOMLA_DB_PASSWORD}" joomla << SQL 2>/dev/null
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
