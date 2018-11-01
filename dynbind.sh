#!/bin/bash

#Configurable variables
DOMAIN='thegrid.trenton.io'
A_TO_MATCH='zuse.trenton.io'
DNS_TO_USE='1.1.1.1'
ZONE_FILE="/var/named/${DOMAIN}"
#
ACTUAL_IPADDRESS=$(dig @${DNS_TO_USE} +short ${A_TO_MATCH})


if grep -vq "${ACTUAL_IPADDRESS}\;DYN ${ZONE_FILE}"
then
  ## Only mess with these if there's actually a new IP
  CURRENT_SERIAL=$(grep \;serial ${ZONE_FILE} |  grep -Po [0-9]{10})
  CURRENT_SERIAL_DATE=$(echo ${CURRENT_SERIAL} | head -c 8)
  CURRENT_SERIAL_VERSION=$(echo ${CURRENT_SERIAL} | tail -c 2)
  CURRENT_IPADDRESS=$(grep -Po '([0-2]{0,1}[0-9]{1,2}\.){3}[0-2]{0,1}[0-9]{1,2}\;DYN' ${ZONE_FILE} | cut -d \; -f 1 | sort -u | head -n1)
  ACTUAL_DATE=$(date +%Y%m%d)

  #Update DNS Entries
  sed -i s/${CURRENT_IPADDRESS}/${ACTUAL_IPADDRESS}/ ${ZONE_FILE}
  
  #Serial logic
  if [ ${CURRENT_SERIAL_DATE} -eq ${ACTUAL_DATE} ]
  then
    NEW_SERIAL_VERSION=$(printf '%02d' $((CURRENT_SERIAL_VERSION + 1)))
    NEW_SERIAL=${ACTUAL_DATE}${NEW_SERIAL_VERSION}

    
    #Update Serial
    sed -i.${CURRENT_SERIAL}.bak s/${CURRENT_SERIAL}/${NEW_SERIAL}/ ${ZONE_FILE}
  else
    NEW_SERIAL="${ACTUAL_DATE}00"
    #Update Serial
    sed -i s/${CURRENT_SERIAL}/${NEW_SERIAL}/ ${ZONE_FILE}
  fi

    # Reload named

  if /sbin/named-checkzone ${DOMAIN} ${ZONE_FILE}
  then
    /sbin/rndc reload
  else
    mv ${ZONE_FILE}.${CURRENT_SERIAL}.bak ${ZONE_FILE}
  fi
fi