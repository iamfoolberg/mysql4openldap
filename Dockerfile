FROM ubuntu:bionic-20220301
ENV DB_NAME=ldap DB_HOST=192.168.2.100 DB_PORT=3306 DB_USER=ldap DB_PASS=ldap \
      LDAP_BASEDN=dc=example,dc=com \
      LDAP_ADMIN_DN=cd=admin,dc=example,dc=com \
      LDAP_ADMIN_PASSWORD=passme
COPY ./src/ /opt/
WORKDIR /opt/openldap
RUN chmod a+x /opt/openldap/conf/entrypoint.sh \
   && mkdir /etc/openldap && mv /opt/openldap/etc_odbcinst.ini /etc/odbcinst.ini \
   && cp /opt/openldap/conf/etc_openldap_slapd.conf /etc/openldap/slapd.conf \
   && apt-get update \
   && apt-get install -y unixodbc make gcc libmysqlclient-dev unixodbc-dev groff ldap-utils mysql-client nano wget

RUN wget https://dev.mysql.com/get/Downloads/Connector-ODBC/8.0/mysql-connector-odbc-8.0.11-linux-ubuntu18.04-x86-64bit.tar.gz \
   && tar -xvzf mysql-connector-odbc-8.0.11-linux-ubuntu18.04-x86-64bit.tar.gz \
   && rm mysql-connector-odbc-8.0.11-linux-ubuntu18.04-x86-64bit.tar.gz \
   && cd mysql-connector-odbc-8.0.11-linux-ubuntu18.04-x86-64bit \
   && cp lib/libmyodbc8* /usr/lib/x86_64-linux-gnu/odbc/ \
   && cd .. \
   && echo "[ldap]">/etc/odbc.ini \
   && echo "Description = MySQL Connector for LDAP">>/etc/odbc.ini \
   && echo "Driver = MySQL Unicode">>/etc/odbc.ini \
   && echo "Database = ${DB_NAME}">>/etc/odbc.ini \
   && echo "Server = ${DB_HOST}">>/etc/odbc.ini \
   && echo "User = ${DB_USER}">>/etc/odbc.ini \
   && echo "Password = ${DB_PASS}">>/etc/odbc.ini \
   && echo "Port = ${DB_PORT}">>/etc/odbc.ini \
   && wget https://mirror-hk.koddos.net/OpenLDAP/openldap-release/openldap-2.6.1.tgz -O openldap-2.6.1.tgz \
   && tar -zxvf openldap-2.6.1.tgz -C ./ \
   && rm openldap-2.6.1.tgz \
   && mv ./openldap-2.6.1/* ./ \
   && ./configure --prefix=/usr --exec-prefix=/usr --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc --datadir=/usr/share --localstatedir=/var --mandir=/usr/share/man --infodir=/usr/share/info --enable-sql --disable-bdb --disable-ndb --disable-hdb \
   && make depend \
   && make \
   && make install \
   && PASSWDEN=$(/usr/sbin/slappasswd -h {SSHA} -s ${LDAP_ADMIN_PASSWORD}) \
   && echo "suffix                \"${LDAP_BASEDN}\"">>/etc/openldap/slapd.conf \
   && echo "rootdn                \"${LDAP_ADMIN_DN}\"">>/etc/openldap/slapd.conf \
   && echo "rootpw                ${PASSWDEN}">>/etc/openldap/slapd.conf \
   && echo "# SQL configuration">>/etc/openldap/slapd.conf \
   && echo "dbname ${DB_NAME}">>/etc/openldap/slapd.conf \
   && echo "dbuser ${DB_USER}">>/etc/openldap/slapd.conf \
   && echo "dbpasswd ${DB_PASS}">>/etc/openldap/slapd.conf \
   && echo "has_ldapinfo_dn_ru no">>/etc/openldap/slapd.conf \
   && echo "subtree_cond \"ldap_entries.dn LIKE CONCAT('%',?)\"">>/etc/openldap/slapd.conf \
   && echo "insentry_stmt   \"INSERT INTO ldap_entries (dn,oc_map_id,parent,keyval) VALUES (?,?,?,?)\"">>/etc/openldap/slapd.conf \
   && cp /etc/openldap/slapd.conf /opt/openldap/conf/ \
   && cp /etc/odbc.ini /opt/openldap/conf/
#   && mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/backsql_create.sql \
#   && mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/testdb_create.sql \
#   && mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/testdb_data.sql \
#   && mysql -h${DB_HOST} -P ${DB_PORT} -u ${DB_USER} -p${DB_PASS} ${DB_NAME}< /opt/openldap/conf/dbmysql/testdb_metadata.sql

EXPOSE 389
VOLUME ["/opt/openldap/conf"]
ENTRYPOINT ["/opt/openldap/conf/entrypoint.sh"]
CMD ["sleep", "infinity"]
