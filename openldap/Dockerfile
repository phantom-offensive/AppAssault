FROM osixia/openldap:1.5.0

ENV LDAP_ORGANISATION="Widget Corp"
ENV LDAP_DOMAIN="widgetcorp.local"
ENV LDAP_BASE_DN="dc=widgetcorp,dc=local"
ENV LDAP_ADMIN_PASSWORD="admin123"
ENV LDAP_TLS="false"
ENV LDAP_REMOVE_CONFIG_AFTER_SETUP="false"
ENV LDAP_READONLY_USER="true"
ENV LDAP_READONLY_USER_USERNAME="readonly"
ENV LDAP_READONLY_USER_PASSWORD="readonly123"
ENV LDAP_RFC2307BIS_SCHEMA="true"

# Add seed data as bootstrap LDIF
COPY bootstrap.ldif /container/service/slapd/assets/config/bootstrap/ldif/custom/50-seed.ldif

# Append ACL fix to the slapd startup.sh so it runs after slapd initializes
# The startup.sh runs BEFORE slapd starts, so we need to modify the process.sh
# to apply ACLs AFTER slapd is running
COPY fix-acl.sh /fix-acl.sh
RUN chmod +x /fix-acl.sh

# Modify process.sh to run fix-acl.sh in background after slapd starts
RUN sed -i '/exec \/usr\/sbin\/slapd/i \/fix-acl.sh \&' /container/service/slapd/process.sh
