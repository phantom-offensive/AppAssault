#!/bin/bash
# Set up GitLab CE — plant flag and breadcrumb files via API

GITLAB_URL="http://gitlab"

echo "[*] Waiting for GitLab to start (this takes 3-5 minutes)..."
for i in $(seq 1 120); do
    HTTP_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "$GITLAB_URL" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "[+] GitLab is responding (HTTP $HTTP_CODE)"
        break
    fi
    sleep 10
done

sleep 30

# Get OAuth token
echo "[*] Getting API token..."
TOKEN=""
for i in $(seq 1 15); do
    TOKEN=$(curl -sf -X POST "$GITLAB_URL/oauth/token" \
        -d "grant_type=password&username=root&password=${GITLAB_ROOT_PASSWORD}" 2>/dev/null | \
        python3 -c "import sys,json;print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)
    if [ -n "$TOKEN" ] && [ "$TOKEN" != "" ] && [ "$TOKEN" != "None" ]; then
        echo "[+] Got OAuth token"
        break
    fi
    sleep 10
done

if [ -z "$TOKEN" ] || [ "$TOKEN" = "None" ] || [ "$TOKEN" = "" ]; then
    echo "[-] Could not get token, trying session cookie..."
    CSRF=$(curl -sf -c /tmp/gl_cookies "$GITLAB_URL/users/sign_in" 2>/dev/null | \
        python3 -c "import sys,re;m=re.search(r'authenticity_token.*?value=\"([^\"]+)\"',sys.stdin.read());print(m.group(1) if m else '')" 2>/dev/null)

    if [ -n "$CSRF" ]; then
        curl -sf -b /tmp/gl_cookies -c /tmp/gl_cookies \
            -X POST "$GITLAB_URL/users/sign_in" \
            -d "authenticity_token=$(python3 -c "import urllib.parse;print(urllib.parse.quote('$CSRF'))")&user[login]=root&user[password]=${GITLAB_ROOT_PASSWORD}" 2>/dev/null

        TOKEN=$(curl -sf -b /tmp/gl_cookies -X POST "$GITLAB_URL/api/v4/users/1/personal_access_tokens" \
            -d "name=setup&scopes[]=api" 2>/dev/null | \
            python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

        if [ -n "$TOKEN" ] && [ "$TOKEN" != "None" ]; then
            echo "[+] Got personal access token via session"
        fi
    fi
fi

if [ -z "$TOKEN" ] || [ "$TOKEN" = "None" ] || [ "$TOKEN" = "" ]; then
    echo "[-] All auth methods failed."
    exit 0
fi

AUTH_HEADER="Authorization: Bearer $TOKEN"

# Create internal-secrets project with flag
echo "[*] Creating internal-secrets repo..."
curl -sf -X POST "$GITLAB_URL/api/v4/projects" \
    -H "$AUTH_HEADER" \
    -d "name=internal-secrets&visibility=private&initialize_with_readme=true" 2>/dev/null

sleep 5

# Plant flag
FLAG_B64=$(echo -n "$FLAG_GITLAB" | base64 -w 0)
curl -sf -X POST "$GITLAB_URL/api/v4/projects/1/repository/files/flag.txt" \
    -H "$AUTH_HEADER" \
    -d "branch=master&content=$FLAG_B64&encoding=base64&commit_message=Add+config" 2>/dev/null

# Create widget-deploy project with WordPress breadcrumb
echo "[*] Creating widget-deploy repo..."
curl -sf -X POST "$GITLAB_URL/api/v4/projects" \
    -H "$AUTH_HEADER" \
    -d "name=widget-deploy&visibility=internal&initialize_with_readme=true" 2>/dev/null

sleep 5

# Breadcrumb: deploy script with WP admin creds
DEPLOY_B64=$(printf '#!/bin/bash\n# Widget Corp Blog Deployment Script\n\nWP_URL="http://wordpress.widgetcorp.local:9001"\nWP_ADMIN="admin"\nWP_PASS="%s"\n\necho "[*] Deploying to WordPress at $WP_URL..."\ncurl -u "$WP_ADMIN:$WP_PASS" "$WP_URL/xmlrpc.php" \\\n    -H "Content-Type: text/xml" \\\n    -d "<?xml version=\\"1.0\\"?><methodCall><methodName>wp.getPosts</methodName></methodCall>"\n\necho "[+] Blog deployment complete"\n' "$WP_ADMIN_PASSWORD" | base64 -w 0)
curl -sf -X POST "$GITLAB_URL/api/v4/projects/2/repository/files/deploy-blog.sh" \
    -H "$AUTH_HEADER" \
    -d "branch=master&content=$DEPLOY_B64&encoding=base64&commit_message=Add+blog+deploy" 2>/dev/null

# Infrastructure map
INFRA_B64=$(printf '# Widget Corp Infrastructure Map\n\n## Web Services\n- WordPress Blog: http://wordpress.widgetcorp.local:9001 (public-facing)\n- Joomla CMS: http://joomla.widgetcorp.local:9002 (marketing site)\n\n## DevOps\n- Gitea: http://gitea.widgetcorp.local:9003 (legacy repos - migrating to GitLab)\n- Jenkins: http://jenkins.widgetcorp.local:9005 (CI/CD)\n- GitLab: http://gitlab.widgetcorp.local:9006 (primary SCM)\n\n## Monitoring\n- Splunk: http://splunk.widgetcorp.local:9007\n\n## Internal\n- Tomcat App Server: http://tomcat.widgetcorp.local:9004\n- phpMyAdmin: http://phpmyadmin.widgetcorp.local:9014\n- LDAP Directory: ldap://ldap.widgetcorp.local:9015\n' | base64 -w 0)
curl -sf -X POST "$GITLAB_URL/api/v4/projects/2/repository/files/INFRASTRUCTURE.md" \
    -H "$AUTH_HEADER" \
    -d "branch=master&content=$INFRA_B64&encoding=base64&commit_message=Add+infra+map" 2>/dev/null

echo "[+] GitLab setup complete"
