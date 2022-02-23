# Cheat sheets and checklists

- Student name: Yves Masscho
- Github repo: https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git

## Basic commands

###### System services
| Task                                         | Command                   |
| :---                                         | :---                      |
| **services** |
| check service | `systemctl status mariadb`
| start, stop, restart | `systemctl start NAME`, `systemctl stop NAME`, `systemctl restart NAME`
| start at boot, don't start at boot | `systemctl enable NAME`, `systemctl disable NAME`
| start at boot plus start now |  `systemctl enable --now NAME`
| **list stuff** | 
| all |`systemctl --type=service`
| running | `systemctl --state=running`
| failed | `systemctl --failed`
| **SELinux** 
| Check status | `sestatus`
| Disable (but please don't) | `setenforce 0`
| See list of booleans | `getsebool -a`
| See filtered list of booleans | `getsebool -a grep http`
| check file contexts | `ls -Z /var/www/html`
| change context | `chcon`
| example chcon | `chcon -t httpd_sys_content_t test.php`|
| restore default context | `restorecon`
| example restorecon | `restorecon -R /var/www/`
| get all booleans | `getsebool -a`
| get all booleans for http | `getsebool -a | grep http`
| set boolean | `setsebool`
| example set boolean | `setsebool -P httpd_can_network_connect_db 1`
|| `-P` = Permanent / `1` inwisselbaar met `on`
| **Samba**



###### Network
| Task                                         | Command                   |
| :---                                         | :---                      |
| Query IP-adress(es) | `ip a`
| NIC Status | `ip link` (up/down)
| for specific device| `ip a show dev em1`
| routing info|  `ip route`
| dns config te vinden in |  `/etc/resolv.conf`
| configs te vinden in |  `/etc/sysconfig/network-scripts/ifcfg-*`
| **ports/sockets** 
| show server sockets | `ss -l`, `--listening`
| show TCP sockets | `ss -t`, `--tcp`
| show UDP sockets | `ss -u`, `--udp`
| show port numbers (instdof service names) | `ss -n`, `--numeric`
| show process | `ss -p`, `--processes`
| **firewall** 
| list all zones | `firewall-cmd --get-zones`
| current active zone | `firewall-cmd --get-active-zones`
| add interface to active zone | `firewall-cmd --add-interface=IFACE`
| show current rules | `firewall-cmd --list-all`
| Allow predefined service | `firewall-cmd --add-service=http`
| List predefined services | `firewall-cmd --get-services`
| Allow a port | `firewall-cmd --add-port=8080/tcp`
| reload rules |  `firewall-cmd --reload`
| block all traffic, undo panic mode | `firewall-cmd --panic-on`, `firewall-cmd --panic-off`
| do something permanent | `ARGS --permanent`, dan reload

##Troubleshooting

- Algemene tips: backup config files `cp httpd.conf httpd.orig`
- Verschillen checken `diff httpd.conf httpd.orig` of `diff httpd.*`
- Voor dns: probeer in dit geval wel als root te werken
- `journalctl -f` of specifieker `journalctf -f -l -u SERVICE`
- Test regelmatig, ping, ...
- validate config file syntax
- reload service after config change

## A. Link Layer
1. Test the cables
2. Check NIC
3. Check virtual network adapter settings
4. `ip link` => NO CARRIER = no cable
5. ping from host

## B. Network Layer

1. Is my subnet correct?
2. Is the IP-adress correct? `ip a`
3. Is the router/default gateway correct? (voor elke interface) `ip r -n`
4. Is a DNS-server available? `cat /etc/resolv.conf`
5. Is the interface (ifcfg-eth0 etc) set to onboot? check `/etc/sysconfig/network-scripts/`
6. ONBOOT=YES?
7. Restart network after change? `sudo systemctl restart network`
8. Luistert de DNS-server zowel naar UDP als TCP? uitzoeken hoe te fixen
9. Heb ik DHCP of fixed IP? (bootproto)
10. Na elke wijziging = `systemctl restart network`

###### 1. Common causes (DHCP)
- NO IP = DHCP Unreachable, DHCP won't give address
- 169.254.x.x: no DHCP offer, link local address
- unexpected subnet: bad config op eigen systeem

###### 2. Common causes (fix IP)
- unexpected subnet: check config
- correct IP but 'network unreachable': check network mask. All hosts on netw must have same NM

###### 3. IP Route
- Default gateway OK?
- Correct Subnet? 
- Check config
- 10.0.2.2 = simulated

###### 4. DNS
- `cat /etc/resolv.conf`
- nameserver aanwezig?
- correct IP nameserver?
- 10.0.2.3 = simulated
1. ping between hosts
2. ping DG, ping DNS
3. ping outside
4. use dig or nslookup, add your dns server IP as third argument to use it

###### 5. Routing outside network
1. curl icanhazip.com
2. tracepath icanhazip.com

-ping naar dg
-ping van eigen pc naar host
-dns hogent.be nakijken nslookup

## C. Transport Layer

1. **Service running?**
- `systemctl status SERVICE`
- Check if running but also if enabled!
- all services: `systemctl list-units --type=service`
- all services include non active: `systemctl list-units --type=service --all`  

2. **Correct port/interface?**
- `sudo ss -tulpn`
- use show sockets
- t = tcp, u : udp, l = listeners, n = portnumbers, p = processes
- edit config and restart service  
**DNS**
- `ss ulpn | grep named`
- check 'listen on port'. Should be port **53** and set to any in `/etc/named.conf`
- check 'allow query' in `/etc/named.conf`
- check transfer = any or acl in `/etc/named.conf`

3. **Firewall settings**
- `sudo firewall-cmd --list-all`
- `sudo firewall-cmd --add-service SERVICE --permanent`
- `sudo firewall-cmd --reload`
- alle mogelijke services: `firewall-cmd --get-services`  

## D. Application Layer
1. Know your applications!  
2. Check specific log files, eg `journalctl -f -u httpd.service`
3. Check latest log files `journalctl -f`
4. Check service specific log files
5. Check SELinux (see SELinux above)
6. Check file context (see SELinux above)  
**DNS**
7. use `rndc querylog`
8. use `named-checkconfig` for config file check
8. recursion check
9. use `named-checkzone domein.com /var/named/domein.com` for zone file check
10. Zone file location `/var/named`
10. check if everything is dotted correctly. FQDN ends with dot!
11. Updated zone file? Increment serial!
12. Reverse lookup reversed correctly? 
13. Files named correctly? Files linked correctly?
14. Nameservers present in all zone files? SOA?
15. Is web mapped to www?
16. Is the mapping a CNAME?
17. Kloppen de IP adressen in de zone files?

#### For other checks and info see hand written notes

###### Sources and resources
- Slides les: https://hogenttin.github.io/elnx-syllabus/
- bertvv's network troubleshooting guide: https://bertvv.github.io/linux-network-troubleshooting/
- les 4 troubleshooting
- les DNS, BIND, DNS troubleshooting
- les Samba