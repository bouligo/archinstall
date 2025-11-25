mkdir -p /mnt/etc/NetworkManager/system-connections

cat <<EOT >> /mnt/etc/NetworkManager/Hotspot.nmconnection
[connection]
id=Hotspot
uuid=18a8f47d-e1b1-4df5-bcba-70b4e0538b3e
type=wifi
autoconnect=true
#interface-name=<...>

[wifi]
mode=ap
ssid=IG

[wifi-security]
group=ccmp;
key-mgmt=wpa-psk
pairwise=ccmp;
proto=rsn;
psk=Iamanotsogoodpasswordsorry

[ipv4]
method=shared

[ipv6]
addr-gen-mode=default
method=ignore

[proxy]
EOT
