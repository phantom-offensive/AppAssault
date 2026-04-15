FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    apache2 curl gcc libc6-dev make bison ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Download and compile bash 4.3 (vulnerable to CVE-2014-6271 Shellshock)
RUN curl -fsSL https://ftp.gnu.org/gnu/bash/bash-4.3.tar.gz -o /tmp/bash-4.3.tar.gz && \
    cd /tmp && tar xzf bash-4.3.tar.gz && \
    cd bash-4.3 && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    cp bash /bin/bash && \
    cd / && rm -rf /tmp/bash-4.3*

# Verify bash is vulnerable
RUN env x='() { :;}; echo VULNERABLE' bash -c "echo test" 2>&1 | grep -q VULNERABLE

# Enable CGI and ensure PATH includes /usr/bin for CGI scripts
RUN a2enmod cgi && \
    echo 'PassEnv PATH' >> /etc/apache2/apache2.conf

# Create CGI scripts - plain bash scripts.
# Shellshock triggers because Apache sets HTTP headers (like HTTP_USER_AGENT)
# as environment variables. Vulnerable bash parses function definitions
# embedded in env vars and executes trailing commands.
RUN mkdir -p /usr/lib/cgi-bin && \
    printf '#!/bin/bash\necho "Content-Type: text/plain"\necho ""\necho "System Status: OK"\necho "Hostname: $(hostname)"\necho "Date: $(date)"\necho "Uptime: $(uptime)"\necho "User-Agent: $HTTP_USER_AGENT"\n' > /usr/lib/cgi-bin/status.cgi && \
    chmod +x /usr/lib/cgi-bin/status.cgi

RUN printf '#!/bin/bash\necho "Content-Type: text/html"\necho ""\necho "<html><body><h2>User Info</h2><pre>"\necho "User: $(whoami)"\necho "ID: $(id)"\necho "</pre></body></html>"\n' > /usr/lib/cgi-bin/user.cgi && \
    chmod +x /usr/lib/cgi-bin/user.cgi

# Breadcrumb: backup config referencing Joomla
RUN printf '# Widget Corp CMS Database Backup Config\n# Joomla marketing site: http://joomla.widgetcorp.local:9002\n# DB Host: joomla-db\n# DB Name: joomla\n# DB User: joomla_user\n#\n# NOTE: The Joomla REST API might still be publicly accessible\n# Filed ticket JRA-445 to restrict this — still open\n' > /opt/cms-backup.conf && \
    chmod 644 /opt/cms-backup.conf

# Web content
RUN echo '<html><body><h1>Widget Corp - Legacy Server</h1><p>Internal monitoring system</p><p><a href="/cgi-bin/status.cgi">System Status</a></p><p><a href="/cgi-bin/user.cgi">User Info</a></p></body></html>' > /var/www/html/index.html

EXPOSE 80
