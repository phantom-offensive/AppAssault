#!/bin/bash
echo "[*] Waiting for LDAP server..."
for i in $(seq 1 60); do
    if ldapsearch -x -H ldap://openldap:389 -D "cn=admin,dc=widgetcorp,dc=local" -w "${LDAP_ADMIN_PASSWORD}" -b "dc=widgetcorp,dc=local" -s base > /dev/null 2>&1; then
        echo "[+] LDAP is ready"
        break
    fi
    sleep 3
done

sleep 10
echo "[*] Adding organizational units..."

ldapadd -c -x -H ldap://openldap:389 -D "cn=admin,dc=widgetcorp,dc=local" -w "${LDAP_ADMIN_PASSWORD}" << 'EOF' 2>/dev/null
dn: ou=People,dc=widgetcorp,dc=local
objectClass: organizationalUnit
ou: People

dn: ou=Groups,dc=widgetcorp,dc=local
objectClass: organizationalUnit
ou: Groups

dn: ou=ServiceAccounts,dc=widgetcorp,dc=local
objectClass: organizationalUnit
ou: ServiceAccounts
EOF

sleep 3
echo "[*] Adding users..."

for attempt in 1 2 3; do
    ldapadd -c -x -H ldap://openldap:389 -D "cn=admin,dc=widgetcorp,dc=local" -w "${LDAP_ADMIN_PASSWORD}" << EOF 2>/dev/null && break
dn: cn=admin.jenkins,ou=ServiceAccounts,dc=widgetcorp,dc=local
objectClass: inetOrgPerson
cn: admin.jenkins
sn: Jenkins
givenName: Admin
mail: jenkins@widgetcorp.local
uid: admin.jenkins
userPassword: ${JENKINS_ADMIN_PASSWORD}
description: Jenkins CI/CD admin account - ${FLAG_LDAP}

dn: cn=svc.deploy,ou=ServiceAccounts,dc=widgetcorp,dc=local
objectClass: inetOrgPerson
cn: svc.deploy
sn: Deploy
givenName: Service
mail: deploy@widgetcorp.local
uid: svc.deploy
userPassword: ${LDAP_PASS_DEPLOY}
description: Deployment bot - pushes to GitLab (gitlab.widgetcorp.local:9006)

dn: cn=john.smith,ou=People,dc=widgetcorp,dc=local
objectClass: inetOrgPerson
cn: john.smith
sn: Smith
givenName: John
mail: j.smith@widgetcorp.local
uid: john.smith
userPassword: ${LDAP_PASS_JOHN}
title: Senior Developer

dn: cn=mary.chen,ou=People,dc=widgetcorp,dc=local
objectClass: inetOrgPerson
cn: mary.chen
sn: Chen
givenName: Mary
mail: m.chen@widgetcorp.local
uid: mary.chen
userPassword: ${LDAP_PASS_MARY}
title: DevOps Lead

dn: cn=david.wilson,ou=People,dc=widgetcorp,dc=local
objectClass: inetOrgPerson
cn: david.wilson
sn: Wilson
givenName: David
mail: d.wilson@widgetcorp.local
uid: david.wilson
userPassword: ${LDAP_PASS_DAVID}
title: IT Administrator
description: Has admin access to all systems
EOF
    echo "[-] User add attempt $attempt failed, retrying..."
    sleep 5
done

# Enable anonymous read access
echo "[*] Enabling anonymous read access..."
ldapmodify -x -H ldap://openldap:389 -D "cn=admin,dc=widgetcorp,dc=local" -w "${LDAP_ADMIN_PASSWORD}" << 'EOF' 2>/dev/null
dn: olcDatabase={1}mdb,cn=config
changetype: modify
replace: olcAccess
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth manage by * break
olcAccess: {1}to attrs=userPassword,shadowLastChange by self write by dn="cn=admin,dc=widgetcorp,dc=local" write by anonymous auth by * none
olcAccess: {2}to * by anonymous read by users read by self write by * read
EOF

# Verify
echo "[*] Verifying with admin bind..."
COUNT=$(ldapsearch -x -H ldap://openldap:389 -D "cn=admin,dc=widgetcorp,dc=local" -w "${LDAP_ADMIN_PASSWORD}" -b "dc=widgetcorp,dc=local" "(objectClass=person)" cn 2>/dev/null | grep -c "^cn:")
echo "[+] Found $COUNT users (admin bind)"

ANON_COUNT=$(ldapsearch -x -H ldap://openldap:389 -b "dc=widgetcorp,dc=local" "(objectClass=person)" cn 2>/dev/null | grep -c "^cn:")
echo "[+] Found $ANON_COUNT users (anonymous bind)"

echo "[+] LDAP seed complete"
