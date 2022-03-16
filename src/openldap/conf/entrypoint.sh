#!/bin/bash
echo "starting the ldap server..."

#create the ini file
  echo "[ldap]">/etc/odbc.ini.tmp
  echo "Description = MySQL Connector for LDAP">>/etc/odbc.ini.tmp
  echo "Driver = MySQL Unicode">>/etc/odbc.ini.tmp
  echo "Database = ${DB_NAME}">>/etc/odbc.ini.tmp
  echo "Server = ${DB_HOST}">>/etc/odbc.ini.tmp
  echo "User = ${DB_USER}">>/etc/odbc.ini.tmp
  echo "Password = ${DB_PASS}">>/etc/odbc.ini.tmp
  echo "Port = ${DB_PORT}">>/etc/odbc.ini.tmp
  rm -f /etc/odbc.ini
  mv /etc/odbc.ini.tmp /etc/odbc.ini

  cp /opt/openldap/conf/etc_openldap_slapd.conf /etc/openldap/slapd.conf.tmp
  PASSWDEN=$(/usr/sbin/slappasswd -h {SSHA} -s ${LDAP_ADMIN_PASSWORD})
  echo "suffix                \"${LDAP_BASEDN}\"">>/etc/openldap/slapd.conf.tmp
  echo "rootdn                \"${LDAP_ADMIN_DN}\"">>/etc/openldap/slapd.conf.tmp
  echo "rootpw                ${PASSWDEN}">>/etc/openldap/slapd.conf.tmp
  echo "# SQL configuration">>/etc/openldap/slapd.conf.tmp
  echo "dbname ${DB_NAME}">>/etc/openldap/slapd.conf.tmp
  echo "dbuser ${DB_USER}">>/etc/openldap/slapd.conf.tmp
  echo "dbpasswd ${DB_PASS}">>/etc/openldap/slapd.conf.tmp
  echo "has_ldapinfo_dn_ru no">>/etc/openldap/slapd.conf.tmp
  echo "subtree_cond \"ldap_entries.dn LIKE CONCAT('%',?)\"">>/etc/openldap/slapd.conf.tmp
  echo "insentry_stmt   \"INSERT INTO ldap_entries (dn,oc_map_id,parent,keyval) VALUES (?,?,?,?)\"">>/etc/openldap/slapd.conf.tmp
  rm -f /etc/openldap/slapd.conf
  mv /etc/openldap/slapd.conf.tmp /etc/openldap/slapd.conf

/opt/openldap/servers/slapd/slapd -d 5 -h 'ldap:/// ldapi:///' -f /etc/openldap/conf/slapd.conf
echo "ldap server started."

echo "FOR INIT, load SQLs in the ./conf/*.sql, or execute in container: "
echo "mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/backsql_create.sql"
echo "mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/testdb_create.sql"
echo "mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/testdb_data.sql"
echo "mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/testdb_metadata.sql"

# make sure the "sleep infinity" in Dockerfile is executed.
exec "$@"
