# mysql4openldap
a simple docker for openLDAP uses the mysql backend

# build the image
```
sudo docker build -t berg/sqlldap:v1 .  
```

# test the iamge
```
docker volume create ldapconf

docker run -d \
        --name ldap         \
        --net mydockernet \
        -p 389:389            \
        -e 'DB_HOST=192.168.2.100'   \
        -e 'DB_PORT=3306'       \
        -e 'DB_NAME=ldap'   \
        -e 'DB_USER=ldap' \
        -e 'DB_PASS=ldap' \
        -e 'LDAP_BASEDN=dc=example,dc=com' \
        -e 'LDAP_ADMIN_DN=cn=admin,dc=example,dc=com' \
        -e 'LDAP_ADMIN_PASSWORD=passme' \
        --mount type=volume,source=ldapconf,destination=/opt/openldap/conf \
        berg/sqlldap:v1
```
```
docker exec -it ldap /bin/bash

ldapsearch -x -b "dc=example,dc=com"
```
## manual start the ldap service
```
/opt/openldap/servers/slapd/slapd -d 5 -h 'ldap:/// ldapi:///' -f /etc/openldap/conf/slapd.conf
```

## manual kill the service
```
ps

kill -INT THE-ID-OF-SLAPD
```
