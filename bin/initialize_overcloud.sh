#!/bin/bash

OVERCLOUD_NAME=${1:-overcloud}
TEMPLATE_DIR=`mktemp -d`
DEFAULT_PARAMETERS=overcloud-resource-registry-puppet.yaml
USER_PARAMETERS=environments/deployment_parameters.yaml

source /home/stack/stackrc

cd $TEMPLATE_DIR
swift download overcloud $DEFAULT_PARAMETERS
swift download overcloud $USER_PARAMETERS

function parameter_value_from_file {
    PARAM=$1
    FILE=$2
    PARAM_GREP="^  ${PARAM}: "
    PARAM_VALUE_UNPARSED=`grep "$PARAM_GREP" $FILE`
    PARAM_VALUE=${PARAM_VALUE_UNPARSED#*:}
    echo $PARAM_VALUE
}

function parameter_value {
    PARAM=$1
    PARAM_VALUE=`parameter_value_from_file $PARAM $TEMPLATE_DIR/$USER_PARAMETERS`

    if [ -z "$PARAM_VALUE" ]; then
	PARAM_VALUE=`parameter_value_from_file $PARAM $TEMPLATE_DIR/$DEFAULT_PARAMETERS`
    fi

    echo $PARAM_VALUE
}

KEYSTONE_IP=`heat output-show $OVERCLOUD_NAME KeystoneAdminVip | tr -d '"'`
PUBLIC_IP=`heat output-show $OVERCLOUD_NAME PublicVip | tr -d '"'`
KEYSTONE_URL=`heat output-show $OVERCLOUD_NAME KeystoneURL`
OVERCLOUD_IP=`python -c "from six.moves.urllib.parse import urlparse; print urlparse($KEYSTONE_URL).hostname"`
OVERCLOUD_ENDPOINT=`echo $KEYSTONE_URL | tr -d '"'`

# set it to the same as overcloud_ip if empty
[  -z "$KEYSTONE_IP" ] && KEYSTONE_IP=$OVERCLOUD_IP

# get service passwords
OVERCLOUD_ADMIN_PASSWORD=`parameter_value AdminPassword`
OVERCLOUD_ADMIN_TOKEN=`parameter_value AdminToken`
OVERCLOUD_CEILOMETER_PASSWORD=`parameter_value CeilometerPassword`
OVERCLOUD_CINDER_PASSWORD=`parameter_value CinderPassword`
OVERCLOUD_GLANCE_PASSWORD=`parameter_value GlancePassword`
OVERCLOUD_HEAT_PASSWORD=`parameter_value HeatPassword`
OVERCLOUD_NEUTRON_PASSWORD=`parameter_value NeutronPassword`
OVERCLOUD_NOVA_PASSWORD=`parameter_value NovaPassword`
OVERCLOUD_SWIFT_PASSWORD=`parameter_value SwiftPassword`

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

# cleanup
rm -f $ENDPOINTS_FILE
rm -rf $TEMPLATE_DIR
