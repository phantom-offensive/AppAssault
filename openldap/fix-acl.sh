#!/bin/bash
# Wait for slapd to be fully initialized
sleep 15
ldapmodify -Y EXTERNAL -H ldapi:/// << 'EOF' 2>/dev/null
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
olcAccess: {1}to attrs=userPassword,shadowLastChange by self write by dn="cn=admin,dc=widgetcorp,dc=local" write by anonymous auth by * read
olcAccess: {2}to * by anonymous read by users read by self write by * read
EOF
echo "[+] Anonymous read ACL applied"
# Keep running (osixia expects services to stay alive)
sleep infinity
