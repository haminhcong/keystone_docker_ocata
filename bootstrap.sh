HTTP="http"
KEYSTONE_DB_ROOT_PASSWD=$KEYSTONE_DB_ROOT_PASSWD_IF_REMOTED

sed -i 's|KEYSTONE_DB_PASSWD|'"$KEYSTONE_DB_PASSWD"'|g' /keystone.sql
mysql -uroot -p$KEYSTONE_DB_ROOT_PASSWD -h $KEYSTONE_DB_HOST -P $KEYSTONE_DB_PORT < /keystone.sql

# Update keystone.conf
sed -i "s/KEYSTONE_DB_PASSWORD/$KEYSTONE_DB_PASSWD/g" /etc/keystone/keystone.conf
sed -i "s/KEYSTONE_DB_PORT/$KEYSTONE_DB_PORT/g" /etc/keystone/keystone.conf
sed -i "s/KEYSTONE_DB_HOST/$KEYSTONE_DB_HOST/g" /etc/keystone/keystone.conf
sed -i "s/KEYSTONE_TOKEN_EXPRIATION_TIME/$KEYSTONE_TOKEN_EXPRIATION_TIME/g" /etc/keystone/keystone.conf
cat /etc/keystone/keystone.conf
# Start memcached
/usr/bin/memcached -u root & >/dev/null || true

# Populate keystone database
su -s /bin/sh -c 'keystone-manage db_sync' keystone

keystone-manage credential_setup --keystone-user keystone --keystone-group keystone

# Bootstrap keystone
keystone-manage bootstrap --bootstrap-username admin \
		--bootstrap-password $KEYSTONE_ADMIN_PASSWORD \
		--bootstrap-project-name admin \
		--bootstrap-role-name admin \
		--bootstrap-service-name keystone \
		--bootstrap-admin-url "$HTTP://$HOSTNAME:35357/v3" \
		--bootstrap-public-url "$HTTP://$HOSTNAME:5000/v3" \
		--bootstrap-internal-url "$HTTP://$HOSTNAME:5000/v3"

# Write openrc to disk
cat > /root/openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${KEYSTONE_ADMIN_PASSWORD}
export OS_AUTH_URL=$HTTP://${HOSTNAME}:35357/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF

echo "127.0.0.1 $HOSTNAME" >> /etc/hosts
# Configure Apache2
echo "ServerName $HOSTNAME" >> /etc/apache2/apache2.conf
apache2ctl -D FOREGROUND
