FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 curl \
    && rm -rf /var/lib/apt/lists/*

# Enable CGI
RUN a2enmod cgi

# Create vulnerable CGI scripts that pass headers to bash eval
RUN mkdir -p /usr/lib/cgi-bin && \
    printf '#!/bin/bash\necho "Content-Type: text/plain"\necho ""\n# VULN: Evaluates User-Agent header unsafely (Shellshock simulation)\nif [ -n "$HTTP_USER_AGENT" ]; then\n  eval "UA=$HTTP_USER_AGENT" 2>/dev/null\nfi\necho "System Status: OK"\necho "Hostname: $(hostname)"\necho "Date: $(date)"\necho "Uptime: $(uptime)"\necho "User-Agent: $HTTP_USER_AGENT"\n' > /usr/lib/cgi-bin/status.cgi && \
    chmod +x /usr/lib/cgi-bin/status.cgi

RUN printf '#!/bin/bash\necho "Content-Type: text/html"\necho ""\necho "<html><body><h2>User Info</h2><pre>"\necho "User: $(whoami)"\necho "ID: $(id)"\n# VULN: Directly executes command from X-Custom header\nif [ -n "$HTTP_X_CUSTOM" ]; then\n  eval "$HTTP_X_CUSTOM" 2>&1\nfi\necho "</pre></body></html>"\n' > /usr/lib/cgi-bin/user.cgi && \
    chmod +x /usr/lib/cgi-bin/user.cgi

# Breadcrumb: backup config referencing Joomla
RUN printf '# Widget Corp CMS Database Backup Config\n# Joomla marketing site: http://joomla.widgetcorp.local:9002\n# DB Host: joomla-db\n# DB Name: joomla\n# DB User: joomla_user\n#\n# NOTE: The Joomla REST API might still be publicly accessible\n# Filed ticket JRA-445 to restrict this — still open\n' > /opt/cms-backup.conf && \
    chmod 644 /opt/cms-backup.conf

# Web content
RUN echo '<html><body><h1>Widget Corp - Legacy Server</h1><p>Internal monitoring system</p><p><a href="/cgi-bin/status.cgi">System Status</a></p><p><a href="/cgi-bin/user.cgi">User Info</a></p></body></html>' > /var/www/html/index.html

EXPOSE 80
