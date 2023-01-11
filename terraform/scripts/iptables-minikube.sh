
```
sudo iptables -t nat -A PREROUTING -p tcp --dport 15012 -j DNAT --to-destination 172.18.2.2:15012
sudo iptables -t nat -A PREROUTING -p tcp --dport 15017 -j DNAT --to-destination 172.18.2.2:15017
#sudo iptables -t nat -A POSTROUTING -o lima0 -p tcp --dport 15017 -d 172.18.2.2 -j MASQUERADE
#sudo iptables -t nat -A POSTROUTING -o lima0 -p tcp --dport 15012 -d 172.18.2.2 -j MASQUERADE
#or sudo iptables -t nat -A PREROUTING -p tcp --dport 15012 -j DNAT --to-destination 172.18.2.1:443 -s 192.168.105.3
sudo iptables -A FORWARD -i lima0 -p tcp --dport 15012 -d 172.18.2.2  -j ACCEPT
sudo iptables -A FORWARD -i lima0 -p tcp --dport 15017 -d 172.18.2.2  -j ACCEPT
```