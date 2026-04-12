FROM splunk/splunk:8.2.0

USER root

# Create a custom monitoring app
RUN mkdir -p /opt/splunk/etc/apps/widget_monitor/local && \
    printf '[script://./bin/status.sh]\ndisabled = false\nindex = main\ninterval = 60\nsourcetype = widget:status\n' > /opt/splunk/etc/apps/widget_monitor/local/inputs.conf && \
    mkdir -p /opt/splunk/etc/apps/widget_monitor/bin && \
    printf '#!/bin/bash\necho "status=ok host=$(hostname) date=$(date)"\n' > /opt/splunk/etc/apps/widget_monitor/bin/status.sh && \
    chmod +x /opt/splunk/etc/apps/widget_monitor/bin/status.sh && \
    printf '[install]\nbuild = 1\n\n[ui]\nis_visible = true\nlabel = Widget Corp Monitor\n\n[launcher]\nauthor = Widget Corp IT\ndescription = Internal monitoring app\nversion = 1.0.0\n' > /opt/splunk/etc/apps/widget_monitor/local/app.conf

# Breadcrumb: incident report mentioning legacy CGI servers
RUN mkdir -p /opt/splunk/etc/apps/widget_monitor/lookups && \
    printf '# Widget Corp - Legacy Server Inventory\n# These servers still run old CGI configurations\n# SECURITY RISK: Do NOT expose to internet\n#\n# Legacy Web Server (Apache): http://apache-cgi.widgetcorp.local:9012\n#   - Hosts internal status pages\n#   - TODO: Upgrade ASAP\n#\n# Legacy CGI Server (Bash): http://shellshock.widgetcorp.local:9013\n#   - Old monitoring CGI scripts\n#   - IT keeps postponing the upgrade\n#\n# Incident INC-2026-0142: Both servers flagged in last pentest\n# Status: OPEN - no remediation date set\n' > /opt/splunk/etc/apps/widget_monitor/lookups/legacy_servers.txt && \
    chmod 644 /opt/splunk/etc/apps/widget_monitor/lookups/legacy_servers.txt

# Startup script to inject flag + breadcrumbs into Splunk index after boot
# Reads FLAG and SPLUNK_PASSWORD from environment at runtime
RUN mkdir -p /opt/splunk/etc/apps/widget_monitor/appserver/static && \
    printf '#!/bin/bash\nsleep 60\ncurl -k -u "admin:$SPLUNK_PASSWORD" -X POST "https://localhost:8089/services/receivers/simple?index=main&sourcetype=widget_secrets" -d "SECURITY AUDIT LOG - Internal credentials dump detected. Investigation reference: $FLAG. Source: widget-monitor-app. Severity: CRITICAL." 2>/dev/null\ncurl -k -u "admin:$SPLUNK_PASSWORD" -X POST "https://localhost:8089/services/receivers/simple?index=main&sourcetype=widget_inventory" -d "ASSET INVENTORY: Legacy Web Server (Apache) at http://apache-cgi.widgetcorp.local:9012 - Status: UNPATCHED" 2>/dev/null\ncurl -k -u "admin:$SPLUNK_PASSWORD" -X POST "https://localhost:8089/services/receivers/simple?index=main&sourcetype=widget_inventory" -d "ASSET INVENTORY: Legacy CGI Server (Bash) at http://shellshock.widgetcorp.local:9013 - CGI scripts accept custom headers - Status: UNPATCHED" 2>/dev/null\necho "$FLAG" > /opt/splunk/flag.txt && chmod 644 /opt/splunk/flag.txt\n' > /opt/splunk/etc/apps/widget_monitor/bin/inject_data.sh && \
    chmod +x /opt/splunk/etc/apps/widget_monitor/bin/inject_data.sh

# Add the inject script as a scripted input that runs once at startup
RUN printf '\n[script://./bin/inject_data.sh]\ndisabled = false\nindex = main\ninterval = -1\nsourcetype = widget:setup\n' >> /opt/splunk/etc/apps/widget_monitor/local/inputs.conf

USER ansible
