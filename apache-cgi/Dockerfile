FROM httpd:2.4.49

# Enable CGI module
RUN sed -i 's/#LoadModule cgid_module/LoadModule cgid_module/' /usr/local/apache2/conf/httpd.conf && \
    sed -i 's/#LoadModule cgi_module/LoadModule cgi_module/' /usr/local/apache2/conf/httpd.conf

# CRITICAL: Change the root directory from "Require all denied" to "Require all granted"
RUN sed -i '/<Directory \/>/,/<\/Directory>/s/Require all denied/Require all granted/' /usr/local/apache2/conf/httpd.conf

# Create CGI script
RUN mkdir -p /usr/local/apache2/cgi-bin && \
    printf '#!/bin/bash\necho "Content-Type: text/plain"\necho ""\necho "CGI Script Running"\necho "Server: $(hostname)"\n' > /usr/local/apache2/cgi-bin/test.cgi && \
    chmod +x /usr/local/apache2/cgi-bin/test.cgi

# Breadcrumb: maintenance script referencing the old CGI server
RUN printf '#!/bin/bash\n# Maintenance script - sync status pages between servers\n# The old CGI server at shellshock.widgetcorp.local:9013 still handles\n# user info lookups via /cgi-bin/user.cgi and /cgi-bin/status.cgi\n# Both accept custom headers for filtering — legacy design choice\n#\n# curl http://shellshock.widgetcorp.local:9013/cgi-bin/status.cgi\n# curl http://shellshock.widgetcorp.local:9013/cgi-bin/user.cgi\n' > /opt/sync-status.sh && \
    chmod 755 /opt/sync-status.sh

# Web content
RUN echo '<html><body><h1>Widget Corp - Web Server</h1><p>Apache HTTP Server</p></body></html>' > /usr/local/apache2/htdocs/index.html

EXPOSE 80
