# Enterprise Linux Laboverslag - Troubleshooting

- Student: Yves Masscho
- Klasgroep: TIN-TILE (Afstandsleren)

## Instructies

- Schrijf een gedetailleerd verslag verderop in dit document
- Gebruik correcte Markdown! Gebruik waar mogelijk "fenced code blocks" ipv screenshots voor commando's en hun uitvoer, transcript van de terminal, ...
- De verschillende fasen in de bottom-up troubleshooting-strategie worden besproken in een aparte subsectie (hoofding van niveau 3, starten met `###`) met de naam van de fase als titel.
- Elke stap is in detail beschreven:
    - Wat je precies test en het verwachte resultaat
    - Het commando (incl. opties en argumenten) waarmee je de test uitvoert, of het absolute pad naar het te controleren configuratiebestand
    - Als de uitvoer van de test verschilt van wat je verwacht, wat is de oorzaak?
    - Beschrijf hoe je deze fout opgelost hebt ahv exacte commando's en/of wijzigingen aan configuratiebestanden
- Beschrijf ook het eindresultaat, de toestand van de VM op het einde van de sessie.
    - Wat heb je gerealiseerd en wat werkt eventueel nog niet?
    - Kopieer en plak een transcript van het uitvoeren van de acceptatietests.
    - Voeg een screenshot bij van wat je ziet als je toegang probeert te krijgen tot de service vanaf het fysieke systeem.
- Verwijder deze instructies uit je verslag.

## Verslag

### Fase 1: Link Layer

1. We testen de kabels met ```ip link```. Dit lijkt voor alle drie de VM's in orde.

2. De kabels zijn ook telkens aangesloten in VirtualBox zelf.

3. Ik stel voor het gemak het toetsenbord in op azerty met ```sudo localectl -set-x11-keymap be``` en zet de NAT-router uit voor de VM workstation.

### Fase 2: Network Layer

4. De **workstation** heeft geen IP adres - ```ip a```. Maar in network-scripts/ifcfg-enp0s en ook in de opdracht zien we dat dit via DHCP moet gebeuren. Dit stellen we dus in op de DHCP-server. Dit wordt aangepakt in een andere laag.

5. Op **server** is het IP-adres niet correct. Dit is 172.20.0.101 maar we passen aan naar 172.20.0.2 in network-scripts/ifcfg-enp0s8. We restarten het netwerk met ```systemctl restart network```.  ```ip a``` toont nu een correct IP-adres.

6. Op **router** klopt het subnet niet voor het internal network.
```
vagrant@Router:~$ show interfaces
Codes: S - State, L - Link, u - Up, D - Down, A - Admin Down
Interface        IP Address                        S/L  Description
---------        ----------                        ---  -----------
eth0             10.0.2.15/24                      u/u  WAN
eth1             172.20.0.254/8                    u/u  LAN
                 172.20.0.254/24
lo               127.0.0.1/8                       u/u
                 ::1/128
```
 7. Dit passen we aan als volgt:
```
vagrant@Router# delete interfaces ethernet eth1 address 172.20.0.254/8
[edit]
vagrant@Router# commit
[edit]
vagrant@Router# save
Saving configuration to '/config/config.boot'...
Done
```
8. Het IP adres is aangepast. ip a geeft:
```
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:ff:f5:e7 brd ff:ff:ff:ff:ff:ff
    inet 172.20.0.254/24 brd 172.20.0.255 scope global eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:feff:f5e7/64 scope link
       valid_lft forever preferred_lft forever

```

9. Met ```ip r``` zien we dat de default gateways goed ingesteld staan. Momentele heeft workstation nog geen DG.

10. Zowel op router en server is een externe DNS query mogelijk.
```
vagrant@Router:~$ nslookup hogent.be
Server:    172.20.0.254
Address 1: 172.20.0.254

Name:      hogent.be
Address 1: 193.190.173.132 net-173-node-133.hogent.be
```

```
[vagrant@server ~]$ dig hogent.be

; <<>> DiG 9.11.4-P2-RedHat-9.11.4-26.P2.el7_9.3 <<>> hogent.be
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 62535
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;hogent.be.                     IN      A

;; ANSWER SECTION:
hogent.be.              948     IN      A       193.190.173.132

;; Query time: 19 msec
;; SERVER: 10.0.2.3#53(10.0.2.3)
;; WHEN: Tue Jan 19 20:16:04 UTC 2021
;; MSG SIZE  rcvd: 54

```

11. Pingen van router naar server en omgekeerd lukt.

### Fase 3: Transport Layer

12. **server** httpd is running. dnsmasq en dhcpd niet.
```
[vagrant@server ~]$ systemctl status dnsmasq
● dnsmasq.service - DNS caching server.
   Loaded: loaded (/usr/lib/systemd/system/dnsmasq.service; enabled; vendor preset: disabled)
   Active: inactive (dead)
[vagrant@server ~]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; disabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-01-19 19:13:52 UTC; 1h 7min ago
     Docs: man:httpd(8)
           man:apachectl(8)
 Main PID: 6208 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/httpd.service
           ├─6208 /usr/sbin/httpd -DFOREGROUND
           ├─6210 /usr/sbin/httpd -DFOREGROUND
           ├─6211 /usr/sbin/httpd -DFOREGROUND
           ├─6212 /usr/sbin/httpd -DFOREGROUND
           ├─6213 /usr/sbin/httpd -DFOREGROUND
           └─6214 /usr/sbin/httpd -DFOREGROUND
[vagrant@server ~]$ systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: inactive (dead)
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
``` 

13. We pogen deze op te starten (enabled zijn ze al).

```
[vagrant@server ~]$ sudo systemctl start httpd
[vagrant@server ~]$ sudo systemctl start dnsmasq
```
14. We doen opnieuw een statusrun.
OK
```
[vagrant@server ~]$ systemctl status dnsmasq
● dnsmasq.service - DNS caching server.
   Loaded: loaded (/usr/lib/systemd/system/dnsmasq.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-01-19 20:23:21 UTC; 10s ago
 Main PID: 7395 (dnsmasq)
   CGroup: /system.slice/dnsmasq.service
           └─7395 /usr/sbin/dnsmasq -k
```
NIET OK
```
[vagrant@server ~]$ systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: inactive (dead)
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
```
De journals zeggen het volgende: 
```
Jan 19 20:42:25 server dhcpd[7972]: No subnet declaration for enp0s3 (10.0.2.15).
Jan 19 20:42:25 server dhcpd[7972]: ** Ignoring requests on enp0s3.  If this is not what
Jan 19 20:42:25 server dhcpd[7972]:    you want, please write a subnet declaration
Jan 19 20:42:25 server dhcpd[7972]:    in your dhcpd.conf file for the network segment
Jan 19 20:42:25 server dhcpd[7972]:    to which interface enp0s3 is attached. **
```

15. Port check (maar nog niet voor httpd). DNS ziet er goed uit, http ontbreekt nog port 443.

```
[vagrant@server ~]$ sudo ss -tulpn | grep dnsmasq
udp    UNCONN     0      0         *:53                    *:*                   users:(("dnsmasq",pid=7395,fd=4))
udp    UNCONN     0      0        :::53                   :::*                   users:(("dnsmasq",pid=7395,fd=6))
tcp    LISTEN     0      5         *:53                    *:*                   users:(("dnsmasq",pid=7395,fd=5))
tcp    LISTEN     0      5        :::53                   :::*                   users:(("dnsmasq",pid=7395,fd=7))
[vagrant@server ~]$ sudo ss -tulpn | grep http
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=6214,fd=4),("httpd",pid=6213,fd=4),("httpd",pid=6212,fd=4),("httpd",pid=6211,fd=4),("httpd",pid=6210,fd=4),("httpd",pid=6208,fd=4))

```

16. We voegen 443 toe in /etc/httpd/conf/httpd.conf. We restarten de service. Nieuwe check OK:
```
[vagrant@server conf]$ sudo ss -tulpn | grep http
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=7883,fd=4),("httpd",pid=7882,fd=4),("httpd",pid=7881,fd=4),("httpd",pid=7880,fd=4),("httpd",pid=7879,fd=4),("httpd",pid=7878,fd=4))
tcp    LISTEN     0      128      :::443                  :::*                   users:(("httpd",pid=7883,fd=6),("httpd",pid=7882,fd=6),("httpd",pid=7881,fd=6),("httpd",pid=7880,fd=6),("httpd",pid=7879,fd=6),("httpd",pid=7878,fd=6))
```

17. We doen een firewall check.
```
[vagrant@server ~]$ sudo firewall-cmd --list-all
public (default, active)
  interfaces: enp0s3 enp0s8
  sources:
  services: dhcp dhcpv6-client dns http ssh
  ports:
  masquerade: no
  forward-ports:
  icmp-blocks:
  rich rules:
```
18. https ontbreekt, we voegen dit toe + reload.
```
[vagrant@server ~]$ sudo firewall-cmd --add-service https --permanent
[vagrant@server ~]$ sudo firewall-cmd --reload
[vagrant@server ~]$ sudo firewall-cmd --list-all | grep https
  services: dhcp dhcpv6-client dns http https ssh
```

### Fase 4: Application Layer

19. Bovenstaand zien we problemen met een paar config files. We passen eerst de /etc/hosts aan en we reloaden.
```
172.20.0.101    server server.linuxlab.lan www.linuxlab.lan
172.20.0.254  gateway router gateway.linuxlab.lan router.linuxlab.lan
127.0.0.1     localhost localhost.localdomain localhost4 localhost4.localdomain4
::1           localhost localhost.localdomain localhost6 localhost6.localdomain6
```
wordt
```
172.20.0.2    server server.linuxlab.lan www.linuxlab.lan
172.20.0.254  gateway router gateway.linuxlab.lan router.linuxlab.lan
127.0.0.1     localhost localhost.localdomain localhost4 localhost4.localdomain4
::1           localhost localhost.localdomain localhost6 localhost6.localdomain6
```

20. dhcpd.conf 
```

# dhcpd.conf -- linuxlab.lan

authoritative;

subnet 172.20.0.0 netmask 255.255.255.0 {
  range 172.20.0.2 172.20.0.253;

  option domain-name "linuxlab.lan";
  option routers 192.168.0.1;
  option domain-name-servers 10.0.2.3;

  default-lease-time 14400;
  max-lease-time 21600;
}

```
wordt
```
# dhcpd.conf -- linuxlab.lan

authoritative;

subnet 172.20.0.0 netmask 255.255.255.0 {
  range 172.20.0.101 172.20.0.253;

  option domain-name "linuxlab.lan";
  option routers 172.20.0.254;
  option domain-name-servers 172.20.0.2;

  default-lease-time 14400;
  max-lease-time 21600;
}
```

21. Een restart van dhcpd is succesvol. We negeren de warnings voor de NAT interface.
```
[vagrant@server etc]$ sudo systemctl restart dhcpd
[vagrant@server etc]$
[vagrant@server etc]$ sudo systemctl status dhcpd
● dhcpd.service - DHCPv4 Server Daemon
   Loaded: loaded (/usr/lib/systemd/system/dhcpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2021-01-19 20:55:20 UTC; 20s ago
     Docs: man:dhcpd(8)
           man:dhcpd.conf(5)
 Main PID: 8042 (dhcpd)
   Status: "Dispatching packets..."
   CGroup: /system.slice/dhcpd.service
           └─8042 /usr/sbin/dhcpd -f -cf /etc/dhcp/dhcpd.conf -user dhcpd -group dhcpd --no-pid

Jan 19 20:55:20 server dhcpd[8042]: Sending on   LPF/enp0s8/08:00:27:7c:f4:b5/172.20.0.0/24
Jan 19 20:55:20 server dhcpd[8042]:
Jan 19 20:55:20 server dhcpd[8042]: No subnet declaration for enp0s3 (10.0.2.15).
Jan 19 20:55:20 server dhcpd[8042]: ** Ignoring requests on enp0s3.  If this is not what
Jan 19 20:55:20 server dhcpd[8042]:    you want, please write a subnet declaration
Jan 19 20:55:20 server dhcpd[8042]:    in your dhcpd.conf file for the network segment
Jan 19 20:55:20 server dhcpd[8042]:    to which interface enp0s3 is attached. **
Jan 19 20:55:20 server dhcpd[8042]:
Jan 19 20:55:20 server dhcpd[8042]: Sending on   Socket/fallback/fallback-net
Jan 19 20:55:20 server systemd[1]: Started DHCPv4 Server Daemon.
```

22. De host krijgt al het juiste ip adres en kan een extern/intern ip queryen -> Screenshot 1

## Eindresultaat

Alle acceptance tests zijn geslaagd -> Screenshot 2

## Referenties

https://github.com/bertvv/cheat-sheets/blob/master/docs/VyOS.md
https://linux.die.net/man/5/dhcpd.conf