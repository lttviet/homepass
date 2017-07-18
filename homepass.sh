#!/bin/bash
service stop hostapd

SLEEP_TIME=600
DB=/home/pi/homepass.db
CONFIG_FILE=/etc/hostapd/hostapd.conf

if [[ ! -e "$CONFIG_FILE" ]] ; then
  touch "$CONFIG_FILE"
fi

read -d '' query << EOF
SELECT mac, ssid
FROM aps
WHERE last_used < datetime('now', '-2 days') OR last_used IS NULL
ORDER BY random()
LIMIT 1;
EOF

result=$(sqlite3 "$DB" "$query")
resultArr=(${result//|/ })

MAC=${resultArr[0]}
SSID=${resultArr[1]}

if [[ -z "$MAC" ]] || [[ -z "$SSID" ]] ; then
  echo "missing MAC or SSID"
  exit 1
fi

sqlite3 "$DB" "UPDATE aps SET last_used = datetime('now') WHERE mac = '$MAC'"

cat > $CONFIG_FILE << EOF
ssid=$SSID
bssid=$MAC

interface=wlan0
driver=nl80211

hw_mode=g
channel=6
auth_algs=3
wpa=0
rsn_pairwise=CCMP
beacon_int=100

macaddr_acl=0

wmm_enabled=0
eap_reauth_period=360000000
EOF

echo "==========================================="
echo "SSID:" $SSID "- BSSID:" $MAC
echo "Time before next change:" $SLEEP_TIME "seconds"
echo "Current time:" $(date)
echo "==========================================="

service start hostapad
