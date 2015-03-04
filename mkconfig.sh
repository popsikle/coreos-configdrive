#!/bin/bash
if [ "$#" -ne 3 ]; then
  echo "Usage : $0 shortname domainname template"
  exit 1
fi

SHORTNAME=$1
DOMAIN=$2
TEMPLATE=$3


mkdir -p $1/openstack/latest

# Generate the cloud config
(echo "<% shortname=\"${SHORTNAME}\"; domainname=\"${DOMAIN}\"; %>" && cat user_data.${TEMPLATE}.erb) | erb > ${SHORTNAME}/openstack/latest/user_data
sed -i '1{/^$/d}' ${SHORTNAME}/openstack/latest/user_data

# Copy any supporting files we need (like the oem stuff)
cp -dpr oem ${SHORTNAME}/

# Copy our custom install script
cp -dpr install.sh ${SHORTNAME}/install.sh
chmod 755 ${SHORTNAME}/*.sh

# Remove the old ISO if any
rm -rf ${SHORTNAME}.iso
mkisofs -R -V config-2 -o ${SHORTNAME}.iso ${SHORTNAME}