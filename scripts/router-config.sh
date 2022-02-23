#!/bin/vbash
source /opt/vyatta/etc/functions/script-template

configure

# Fix for error "INIT: Id "TO" respawning too fast: disabled for 5 minutes"
delete system console device ttyS0

#
# Basic settings
#
set system host-name 'router'
#set service ssh port '22'

#
# IP settings
#

#eth0 WAN link - NAT
set interfaces ethernet eth0 address dhcp
set interfaces ethernet eth0 description "WAN link"

#eth1 DMZ - Virtualbox Host-Only Ethernet Adapter #4
set interfaces ethernet eth1 address 203.0.113.254/24
set interfaces ethernet eth1 description "DMZ"

#eth2 internal - Virtualbox Host-Only Ethernet Adapter #3
set interfaces ethernet eth2 address 172.16.255.254/16
set interfaces ethernet eth2 description "internal"

#
# Network Address Translation
#

# traffic van internal naar WAN
set nat source rule 100 outbound-interface 'eth0'
set nat source rule 100 source address '172.16.0.0/16'
set nat source rule 100 translation address 'masquerade'

# traffic van internal naar DMZ
set nat source rule 200 outbound-interface 'eth1'
set nat source rule 200 source address '172.16.0.0/16'
set nat source rule 200 translation address 'masquerade'

#
# Time => Synchronise clock
#

delete system ntp server 0.pool.ntp.org
delete system ntp server 1.pool.ntp.org
delete system ntp server 2.pool.ntp.org
set system ntp server be.pool.ntp.org

delete system time-zone UTC
set system time-zone Europe/Brussels

#
# Domain Name Service
#

set service dns forwarding domain avalon.lan server 172.16.128.1 #opzoekingen voor *.avalon.lan
set service dns forwarding name-server 10.0.2.3 #alle andere opzoekingen
set service dns forwarding listen-on 'eth1' #DMZ
set service dns forwarding listen-on 'eth2' #Internal


# Make configuration changes persistent
commit
save

# Fix permissions on configuration
sudo chown -R root:vyattacfg /opt/vyatta/config/active

# vim: set ft=sh
