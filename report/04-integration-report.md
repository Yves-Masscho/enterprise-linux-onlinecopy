# Enterprise Linux Lab Report

- Student name: Yves Masscho
- Github repo: <https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git>

Making the environment work together, setting up DHCP.

## Test plan

1. Heeft de host een IP-adres dat past bij a. de range van niet gekende toestellen? en b. het reserved ip *.66 bij het gekende toestel(/mac-adres)?
```
[user66@localhost ~]$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether ca:fe:c0:ff:ee:00 brd ff:ff:ff:ff:ff:ff
    inet 172.16.128.66/16 brd 172.16.255.255 scope global dynamic noprefixroute enp0s3
       valid_lft 43103sec preferred_lft 43103sec
    inet6 fe80::b8a2:da94:8ca4:b09e/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever

3: enp0s8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 08:00:27:bb:69:7c brd ff:ff:ff:ff:ff:ff
    inet 172.16.0.2/16 brd 172.16.255.255 scope global dynamic noprefixroute enp0s8
       valid_lft 14303sec preferred_lft 14303sec
    inet6 fe80::a7a4:94cf:a741:4dd9/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

2. Is de gateway correct?

```
[user66@localhost ~]$ ip r
default via 172.16.255.254 dev enp0s3 proto dhcp metric 100 
default via 172.16.255.254 dev enp0s8 proto dhcp metric 101 
172.16.0.0/16 dev enp0s3 proto kernel scope link src 172.16.128.66 metric 100 
172.16.0.0/16 dev enp0s8 proto kernel scope link src 172.16.0.2 metric 101 
```
3. Is de subnetmask correct? (Selectie gemaakt in onderstaande output)

```
[user66@localhost ~]$ ifconfig

enp0s3: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.128.66  netmask 255.255.0.0  broadcast 172.16.255.255

enp0s8: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.16.0.2  netmask 255.255.0.0  broadcast 172.16.255.255
```

4. Wordt de juiste DNS-server gebruikt? (Opnieuw selectie genomen uit output)

```
[user66@localhost ~]$ resolvectl status

Link 2 (enp0s3)                 
  Current DNS Server: 172.16.255.254           
         DNS Servers: 172.16.255.254           
          DNS Domain: ~.                       
                      avalon.lan               

Link 3 (enp0s8)
    DNSSEC supported: no                       
  Current DNS Server: 172.16.255.254           
         DNS Servers: 172.16.255.254           
          DNS Domain: ~.                       
                      avalon.lan  
```
5. Lukken de NS-lookups? (Reverse lookup lukt nog niet)
```
[user66@localhost ~]$ nslookup www.avalon.lan
Server:		127.0.0.53
Address:	127.0.0.53#53
Non-authoritative answer:
www.avalon.lan	canonical name = pu001.avalon.lan.
Name:	pu001.avalon.lan
Address: 203.0.113.10

[user66@localhost ~]$ nslookup files.avalon.lan
Server:		127.0.0.53
Address:	127.0.0.53#53
Non-authoritative answer:
files.avalon.lan	canonical name = pr011.avalon.lan.
Name:	pr011.avalon.lan
Address: 172.16.128.11

[user66@localhost ~]$ nslookup hogent.be
Server:		127.0.0.53
Address:	127.0.0.53#53
Non-authoritative answer:
Name:	hogent.be
Address: 193.190.173.132

[user66@localhost ~]$ nslookup 203.0.113.10
** server can't find 10.113.0.203.in-addr.arpa: NXDOMAIN

```

6. Is www.avalon.lan en het internet bereikbaar?

[Screenshot](04-Integration-Screenshot/WorkstationInternetTest.png)

7. Lukt het om aan de files-server te geraken?
```
[user66@localhost ~]$ ftp files.avalon.lan
Connected to files.avalon.lan (172.16.128.11).
220 (vsFTPd 3.0.2)
Name (files.avalon.lan:user66): anc
331 Please specify the password.
Password:
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> ls
227 Entering Passive Mode (172,16,128,11,58,197).
150 Here comes the directory listing.
drwxrwx---    2 0        1004            6 Jan 17 20:26 it
drwxrwx---    2 0        1001            6 Jan 17 20:26 management
drwxrwxr-x    2 0        1005            6 Jan 17 20:26 public
drwxrwx---    2 0        1003            6 Jan 17 20:26 sales
drwxrwxr-x    2 0        1002            6 Jan 17 20:26 technical
226 Directory send OK.
ftp> cd management
550 Failed to change directory.
ftp> cd public
250 Directory successfully changed.
```

## Procedure/Documentation

#### Router

1. We installeren een plugin in vagrant om VyOS te doen werken met `vagrant plugin install vagrant-vyos`.

2. De DNS wordt ingesteld om voor alles van het domein avalon.lan gebruik te maken van onze nameserver ns1/pr001. Alle andere requests worden geforward naar de DNS-server van Virtualbox/de ISP van Avalon.

3. De ingestelde NTP-servers worden gedelete. Om deze te weten te komen moet in de VM zelf `show system ntp server` worden ingegeven. Er zijn er drie, alle drie moeten ze weg. We voegen die toe voor België `be.pool.ntp.org`. Na een testrun zien we dat eerst de huidige time-zone moet gedelete worden. Ook de ingegeven tijdzone moet aangepast worden, is hoofdlettergevoelig.

4. We stellen de router interfaces in. Bij het booten en verder in de vagrantfile zie ik wel dat het instellen van de interface al gebeurt. De description stellen we in op hun respectievelijke namen.

5. We testen tussendoor eens de DNS. We gebruiken een server waarvoor we tijdelijk de NAT uitschakelen
```
[vagrant@pr001 ~]$ nslookup hogent.be 172.16.255.254
Server:         172.16.255.254
Address:        172.16.255.254#53

Non-authoritative answer:
Name:   hogent.be
Address: 193.190.173.132

[vagrant@pr001 ~]$ nslookup ns2.avalon.lan 172.16.255.254
Server:         172.16.255.254
Address:        172.16.255.254#53

ns2.avalon.lan  canonical name = pr002.avalon.lan.
Name:   pr002.avalon.lan
Address: 172.16.128.2
```
Beide query's lijken te lukken.

6. De volgende stap is NAT. Daar ik er niet zo thuis in ben (net 2&3 en proj2 nog niet gedaan) ga ik eerst de documentatie grondig lezen.
Na onderzoek stel ik de NAT in voor verkeer van internal naar zowel de DMZ als het internet. Hiermee lijkt voorlopig het deel van de router in orde te zijn. Next: DHCP.

#### DHCP

7. Ik stel pr003 in in de vagrant-hosts en de all.yml bestanden. Voor specifieke vars creëer ik ook pr003.yml en stel ik meteen dhcp in onder de firewall. Als gepaste rol kies ik voor bertvv.dhcp.

8. Volgens de documentatie en de gegeven informatie stel ik beide pools in voor de DHCP, ene voor known-clients en ene voor unknown-clients, met bijhorende range, DNS, gateway en lease time.

9. Ik creëer een Fedora workstation VM met 2 interfaces, waarvan eentje met een 'gekend' MAC-adres.

10. Dit toestel krijgt op de juiste manier de IP-adressen toegekend en heeft toegang tot de nodige diensten (zie testplan)

## Resources

https://github.com/bertvv/cheat-sheets/blob/master/docs/VyOS.md
https://www.cisco.com/c/en/us/support/docs/ip/network-address-translation-nat/26704-nat-faq-00.html
https://galaxy.ansible.com/bertvv/dhcp
https://github.com/bertvv/ansible-role-dhcp
https://linux.die.net/man/5/dhcpd.conf
