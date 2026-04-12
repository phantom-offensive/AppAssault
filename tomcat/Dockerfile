FROM tomcat:9.0.30-jdk11

# Enable AJP connector
COPY server.xml /usr/local/tomcat/conf/server.xml

# Enable Manager app
RUN cp -r /usr/local/tomcat/webapps.dist/manager /usr/local/tomcat/webapps/manager && \
    cp -r /usr/local/tomcat/webapps.dist/host-manager /usr/local/tomcat/webapps/host-manager

# Weak credentials
RUN printf '<?xml version="1.0" encoding="UTF-8"?>\n<tomcat-users>\n  <role rolename="manager-gui"/>\n  <role rolename="manager-script"/>\n  <role rolename="admin-gui"/>\n  <user username="tomcat" password="tomcat" roles="manager-gui,manager-script,admin-gui"/>\n</tomcat-users>\n' > /usr/local/tomcat/conf/tomcat-users.xml

# Remove IP restrictions on Manager app
RUN printf '<?xml version="1.0" encoding="UTF-8"?>\n<Context antiResourceLocking="false" privileged="true">\n</Context>\n' > /usr/local/tomcat/webapps/manager/META-INF/context.xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<Context antiResourceLocking="false" privileged="true">\n</Context>\n' > /usr/local/tomcat/webapps/host-manager/META-INF/context.xml

# Web content
RUN mkdir -p /usr/local/tomcat/webapps/ROOT && \
    echo '<html><body><h1>Widget Corp - Internal Portal</h1><p>Tomcat Application Server</p></body></html>' > /usr/local/tomcat/webapps/ROOT/index.html

# Breadcrumb: monitoring config referencing Splunk
RUN mkdir -p /opt/widget-corp && \
    printf '# Widget Corp App Server Monitoring\n# All app server logs are forwarded to Splunk\n#\n# Splunk Dashboard: http://splunk.widgetcorp.local:9007\n# Creds: Check with IT team (they never changed the defaults...)\n#\n# Splunk forwarder config:\n# [tcpout]\n# defaultGroup = splunk-indexers\n# server = splunk.widgetcorp.local:9997\n' > /opt/widget-corp/monitoring.conf && \
    chmod 644 /opt/widget-corp/monitoring.conf

EXPOSE 8080 8009
