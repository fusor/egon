#!/bin/bash

source /home/stack/stackrc
source /home/stack/tripleo-overcloud-passwords

KEYSTONE_IP=`heat output-show overcloud KeystoneAdminVip | tr -d '"'`
PUBLIC_IP=`heat output-show overcloud PublicVip | tr -d '"'`
OVERCLOUD_ENDPOINT=`heat output-show overcloud KeystoneURL`
OVERCLOUD_IP=`python -c "from six.moves.urllib.parse import urlparse; print urlparse($OVERCLOUD_ENDPOINT).hostname"`
OVERCLOUD_ENDPOINT=`echo $OVERCLOUD_ENDPOINT | tr -d '"'`

# set it to the same as overcloud_ip if empty
[  -z "$KEYSTONE_IP" ] && KEYSTONE_IP=$OVERCLOUD_IP

# Write overcloudrc
su - stack -c cat > /home/stack/overcloudrc << EOF
export NOVA_VERSION=1.1
export COMPUTE_API_VERSION=1.1
export OS_USERNAME=admin
export OS_TENANT_NAME=admin
export OS_NO_CACHE=True
export OS_CLOUDNAME=overcloud
export no_proxy=$OVERCLOUD_IP
export OS_PASSWORD=$OVERCLOUD_ADMIN_PASSWORD
export OS_AUTH_URL=$OVERCLOUD_ENDPOINT
EOF

# source overcloudrc so that we're talking to the overcloud
source /home/stack/overcloudrc

# initialize overcloud keystone
su - stack -c "init-keystone -o $KEYSTONE_IP -t $OVERCLOUD_ADMIN_TOKEN \
    -e admin@example.com -p $OVERCLOUD_ADMIN_PASSWORD -u heat-admin \
    --public $PUBLIC_IP"

# Needed by ceilometer user in register-endpoint
if ! openstack role show ResellerAdmin; then
    openstack role create ResellerAdmin
fi

# Create service endpoints and optionally include Ceilometer for UI support
ENDPOINTS_FILE=$(mktemp)
cat > $ENDPOINTS_FILE << EOF
{
    "ceilometer": {"password": "$OVERCLOUD_CEILOMETER_PASSWORD"},
    "cinder":     {"password": "$OVERCLOUD_CINDER_PASSWORD"},
    "cinderv2":   {"password": "$OVERCLOUD_CINDER_PASSWORD"},
    "ec2":        {"password": "$OVERCLOUD_GLANCE_PASSWORD"},
    "glance":     {"password": "$OVERCLOUD_GLANCE_PASSWORD"},
    "heat":       {"password": "$OVERCLOUD_HEAT_PASSWORD"},
    "neutron":    {"password": "$OVERCLOUD_NEUTRON_PASSWORD"},
    "nova":       {"password": "$OVERCLOUD_NOVA_PASSWORD"},
    "novav3":     {"password": "$OVERCLOUD_NOVA_PASSWORD"},
    "swift":      {"password": "$OVERCLOUD_SWIFT_PASSWORD"},
    "horizon": {
        "port": "80",
        "path": "/dashboard/",
        "admin_path": "/dashboard/admin"
    }
}
EOF

# set up the endpoints
setup-endpoints -s $ENDPOINTS_FILE -r regionOne
rm -f $ENDPOINTS_FILE
