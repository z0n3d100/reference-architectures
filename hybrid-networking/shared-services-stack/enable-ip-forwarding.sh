#!/bin/bash
bash -c "echo net.ipv4.ip_forward=1 >> /etc/sysctl.conf"
sysctl -p /etc/sysctl.conf

echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts

sudo iptables -F
sudo iptables -t nat -F
sudo iptables -X

iptables -t nat -A POSTROUTING -o eth0 -p tcp -j SNAT --to-source $1

iptables -A FORWARD -i eth0 -o eth0 -p tcp --syn -j ACCEPT 
iptables -A FORWARD -p tcp --syn -j ACCEPT 

service ufw stop
service ufw start