#!/bin/bash
# Set up Gitea with admin user and repo

GITEA_URL="http://gitea:3000"

echo "[*] Waiting for Gitea to start..."
for i in $(seq 1 60); do
    if curl -sf "$GITEA_URL" > /dev/null 2>&1; then
        echo "[+] Gitea is responding"
        break
    fi
    sleep 5
done

sleep 10

# Create admin user
echo "[*] Creating admin user..."
curl -sf -X POST "$GITEA_URL/user/sign_up" \
    -d "user_name=widgetadmin&password=${GITEA_ADMIN_PASSWORD}&retype=${GITEA_ADMIN_PASSWORD}&email=admin@widgetcorp.local" 2>/dev/null

sleep 5

# Create internal-deploy repo with flag
echo "[*] Creating internal-deploy repo..."
curl -sf -X POST "$GITEA_URL/api/v1/user/repos" \
    -H "Content-Type: application/json" \
    -u "widgetadmin:${GITEA_ADMIN_PASSWORD}" \
    -d '{"name":"internal-deploy","description":"Widget Corp deployment scripts","private":false,"auto_init":true,"default_branch":"main"}' 2>/dev/null

sleep 3

# Plant flag in deploy config
echo "[*] Planting flag..."
FLAG_CONTENT=$(printf '# Widget Corp Production Deployment Keys\n# CONFIDENTIAL — DO NOT SHARE\n\n## AWS Production\nAWS_ACCESS_KEY=AKIA3EXAMPLE7WIDGETX\nAWS_SECRET_KEY=%s\n\n## Database Master\nDB_MASTER_HOST=rds.widgetcorp.internal\nDB_MASTER_PASS=Pr0d_DB_2026!\n\n## VPN Gateway\nVPN_PSK=WidgetCorpVPN_S3cret!\n' "$FLAG_GITEA" | base64 -w 0)
curl -sf -X POST "$GITEA_URL/api/v1/repos/widgetadmin/internal-deploy/contents/production-keys.env" \
    -H "Content-Type: application/json" \
    -u "widgetadmin:${GITEA_ADMIN_PASSWORD}" \
    -d "{\"content\":\"$FLAG_CONTENT\",\"message\":\"Add production keys\"}" 2>/dev/null

sleep 2

# Add a README
README_CONTENT=$(printf '# Internal Deploy\n\nDeployment scripts and credentials for Widget Corp production infrastructure.\n\n## WARNING\nThis repo contains production secrets. Access is restricted to DevOps team.\n\n## Contents\n- production-keys.env — AWS, DB, and VPN credentials\n- deploy-blog.sh — WordPress deployment\n- deploy-app.sh — Tomcat WAR deployment\n\n## Access\nContact mary.chen@widgetcorp.local for access requests.\n' | base64 -w 0)
curl -sf -X PUT "$GITEA_URL/api/v1/repos/widgetadmin/internal-deploy/contents/README.md" \
    -H "Content-Type: application/json" \
    -u "widgetadmin:${GITEA_ADMIN_PASSWORD}" \
    -d "{\"content\":\"$README_CONTENT\",\"message\":\"Update README\",\"sha\":\"$(curl -sf "$GITEA_URL/api/v1/repos/widgetadmin/internal-deploy/contents/README.md" -u "widgetadmin:${GITEA_ADMIN_PASSWORD}" | python3 -c "import sys,json;print(json.load(sys.stdin).get('sha',''))" 2>/dev/null)\"}" 2>/dev/null

echo "[+] Gitea setup complete"
