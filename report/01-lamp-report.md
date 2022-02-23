# Enterprise Linux Lab Report

- Student name: Yves Masscho
- Github repo: <https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git>

Adding a LAMP-stack to the pu001 server.

## Test plan

Telkens wordt het commando + verwachte output getoond in de block code.

###### Apache
1. We kijken of de service httpd actief en enabled is.
```
[vagrant@pu001 ~]$ systemctl --type=service | grep httpd
httpd.service                      loaded active running The Apache HTTP Server
```
```
[vagrant@pu001 ~]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Tue 2020-12-15 18:52:30 UTC; 1 day 16h ago
     Docs: man:httpd(8)
           man:apachectl(8)
  Process: 6854 ExecStop=/bin/kill -WINCH ${MAINPID} (code=exited, status=0/SUCCESS)
 Main PID: 6857 (httpd)
   Status: "Total requests: 0; Current requests/sec: 0; Current traffic:   0 B/sec"
   CGroup: /system.slice/httpd.service
           ├─6857 /usr/sbin/httpd -DFOREGROUND
           ├─6858 /usr/sbin/httpd -DFOREGROUND
           ├─6859 /usr/sbin/httpd -DFOREGROUND
           ├─6860 /usr/sbin/httpd -DFOREGROUND
           ├─6861 /usr/sbin/httpd -DFOREGROUND
           └─6862 /usr/sbin/httpd -DFOREGROUND
```
2. We kijken of het IP-adres+subnet juist is (203.0.113.10/24)
```
[vagrant@pu001 ~]$ ip a l eth1
3: eth1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 08:00:27:c8:e6:93 brd ff:ff:ff:ff:ff:ff
    inet 203.0.113.10/24 brd 203.0.113.255 scope global noprefixroute eth1
       valid_lft forever preferred_lft forever
    inet6 fe80::a00:27ff:fec8:e693/64 scope link
       valid_lft forever preferred_lft forever
```
3. Laat de firewall http en https toe?
```
[vagrant@pu001 ~]$ sudo firewall-cmd --list-all | grep http
  services: ssh dhcpv6-client http https
```
4. Luistert de service op de juiste poorten? (tcp: 80 en 443)
```
[vagrant@pu001 ~]$ sudo ss -tlpn | grep httpd
tcp    LISTEN     0      128      :::80                   :::*                   users:(("httpd",pid=6862,fd=4),("httpd",pid=6861,fd=4),("httpd",pid=6860,fd=4),("httpd",pid=6859,fd=4),("httpd",pid=6858,fd=4),("httpd",pid=6857,fd=4))
tcp    LISTEN     0      128      :::443                  :::*                   users:(("httpd",pid=6862,fd=6),("httpd",pid=6861,fd=6),("httpd",pid=6860,fd=6),("httpd",pid=6859,fd=6),("httpd",pid=6858,fd=6),("httpd",pid=6857,fd=6))
```
5. surfen naar `http(s)://203.0.113.10` => Geeft de Apache testpagina weer.

###### MariaDB

7. Is MariaDB active en enabled?
```
[vagrant@pu001 ~]$ systemctl status mariadb
● mariadb.service - MariaDB 10.4.17 database server
   Loaded: loaded (/usr/lib/systemd/system/mariadb.service; enabled; vendor preset: disabled)
  Drop-In: /etc/systemd/system/mariadb.service.d
           └─migrated-from-my.cnf-settings.conf
   Active: active (running) since Tue 2020-12-15 18:52:31 UTC; 1 day 16h ago
     Docs: man:mysqld(8)
           https://mariadb.com/kb/en/library/systemd/
  Process: 6941 ExecStartPost=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
  Process: 6895 ExecStartPre=/bin/sh -c [ ! -e /usr/bin/galera_recovery ] && VAR= ||   VAR=`cd /usr/bin/..; /usr/bin/galera_recovery`; [ $? -eq 0 ]   && systemctl set-environment _WSREP_START_POSITION=$VAR || exit 1 (code=exited, status=0/SUCCESS)
  Process: 6893 ExecStartPre=/bin/sh -c systemctl unset-environment _WSREP_START_POSITION (code=exited, status=0/SUCCESS)
 Main PID: 6909 (mysqld)
   Status: "Taking your SQL requests now..."
   CGroup: /system.slice/mariadb.service
           └─6909 /usr/sbin/mysqld
```

###### Wordpress
8. Surfen naar `http(s)://203.0.113.10/wordpress` geeft de installatiepagina weer van wordpress.

## Procedure/Documentation

**06/12/2020**

###### A. Begin en Apache

1. Na het opzoeken van de nodige of nuttige rollen kom ik uit op de volgende rollen: bertvv.httpd, bertvv.mariadb, bertvv.wordpress. Even kon ik geen rollen toevoegen via het script vanop het hostsysteem. Workaround: rol toevoegen na VM opgestart is en via de VM de rol installeren. Een andere oplossing was `dos2unix site.yml` te runnen in de map. Had te maken met regeleindes die niet compatibel waren.

2. We kijken of httpd runt of zelfs bestaat:
```
[vagrant@pu001 vagrant]$ systemctl status httpd
Unit httpd.service could not be found.
```
3. We voegen de rol bertvv.httpd toe en doen een provision van de VM. We checken opnieuw de status. Dit verliep dus vrij vlekkeloos.
```
[vagrant@pu001 vagrant]$ systemctl status httpd
httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2020-12-06 13:41:13 UTC; 17s ago
```
4. Volgende to do: instellingen httpd controleren en juistzetten. Uit de video troubleshooting weet ik alvast dat http en https moeten toegevoegd worden in de firewall.
- `sudo firewall-cmd --list-all` => nog geen http of https bij services
- `sudo ss -tulpn | grep httpd` => TCP op poort 80 en 443: lijkt in orde.
We zetten bij rhbase_firewall_allow_services http en https: bij provision loopt het fout bij https. 
```
failed: [pu001] (item=-http -https).
``` 
- We vergelijken met andere file: probleem gevonden => een yaml syntax-fout. Er moet een spatie tussen het streepje en https. Nieuwe provision = OK. `sudo firewall-cmd --list-all` => http en https added. Met `ip a` gecheckt of het IP adres klopt: OK 203.0.113.10

5. Via de host surfen we naar http://203.0.113.10/ en https://203.0.113.10/ = OK. Wel cert error met https.
```
apachectl configtest
AH00558: httpd: Could not reliably determine the server's fully qualified domain name, using 127.0.1.1. Set the 'ServerName' directive globally to suppress this message
Syntax OK 
```
- Dit wordt volgens mij gefixt bij de opzet van de zonebestanden in de DNS-opdracht.


###### B. MariaDB
6.  We gaan er voorlopig even vanuit dat httpd goed loopt, indien niet keren we hier later op terug. `systemctl status mariadb` => nog niets gevonden. We voegen bertvv.mariadb in site.yml en installeren die via het script. Een provision en opnieuw `systemctl status mariadb` => Active: active (running). We runnen voor de eerste keer de test (1), resultaten hieronder.

###### C. Wordpress
7. rol bertvv.wordpress uit comment halen, rol installeren en provision. Test (2).

###### **09/12/2020**

###### D. Wordpress + MariaDB integratie

8. Toegevoegd aan pu001.yml = mariadb_databases & root password, test (3)
9. Toegevoegd aan pu001.yml = wordpress user, database en password, mariadb user, test (4). 
10. Probleem: user heeft geen write rechten. Kleine fout gevonden: typo in mariadb password, Evil_Corp => Evil_corp. Test (5)
11. Protip: als je een paswoordfout vindt en aanpast, zorg dat ze overal aangepast is. Ook voor wordpress dus password aangepast naar Evil_**c**orp. Test (6)

###### **17/12/2020**

12. Als laatste stap moeten we een certificaat aanmaken voor onze webpagina. We volgen de installatiehandleiding van de CentOS-wiki. Deze certificaten plaatsen we vervolgens in de gedeelde map /vagrant en via daar plaatsen we ze in de permanente map ansible/files/. De laatste test (7) geeft alles correct terug.
We krijgen wel nog via de browser:
```
NET::ERR_CERT_AUTHORITY_INVALID
```

## Test report

Test 1:

- Hier zitten volgens mij nog wat 'false positives/negatives' tussen. Output aangepast om in Markdown geen rare formatting te geven (vb dollartekens en backticks weggehaald)
```
 ✗ The necessary packages should be installed  
   (in test file /vagrant/test/pu001/lamp.bats, line 24)  
     rpm -q wordpress' failed  
   httpd-2.4.6-97.el7.centos.x86_64  
   MariaDB-server-10.4.17-1.el7.centos.x86_64  
   package wordpress is not installed  
 ✓ The Apache service should be running  
 ✓ The Apache service should be started at boot  
 ✓ The MariaDB service should be running  
 ✓ The MariaDB service should be started at boot  
 ✓ The SELinux status should be ‘enforcing’  
 ✓ Web traffic should pass through the firewall  
 ✗ Mariadb should have a database for Wordpress  
   (in test file /vagrant/test/pu001/lamp.bats, line 55)  
     mysql -uroot -p{mariadb_root_password} --execute 'show tables' {wordpress_database}' failed  
   ERROR 1049 (42000): Unknown database 'wp_db'  
 ✗ The MariaDB user should have write  
   (in test file /vagrant/test/pu001/lamp.bats, line 59)  
     mysql -u{wordpress_user} -p{wordpress_password} \' failed  
   ERROR 1698 (28000): Access denied for user 'mr_robot'@'localhost'  
 ✓ The website should be accessible through HTTP  
 ✓ The website should be accessible through HTTPS  
 ✗ The certificate should not be the default one  
   (in test file /vagrant/test/pu001/lamp.bats, line 90)  
     [ -z "(echo {output} | grep SomeOrganization)" ]' failed  
 ✗ The Wordpress install page should be visible under http://203.0.113.10/wordpress/  
   (in test file /vagrant/test/pu001/lamp.bats, line 94)  
     [ -n "(curl --silent --location http://{sut}/wordpress/ | grep 'titleWordPress')" ]' failed  
 ✓ MariaDB should not have a test database  
 ✓ MariaDB should not have anonymous users  
```
Test 2:
 - Na het installeren van wordpress geeft de eerste lijn het volgende weer:
```
 ✓ The necessary packages should be installed
```

Test 3:
```
✓ Mariadb should have a database for Wordpress
```
Test 4:
```
✓ The Wordpress install page should be visible under http://203.0.113.10/wordpress/
```
Test 5:
- Wordpress install page plots opnieuw niet meer zichtbaar (bleek typo te zijn, zie report)
```
- ✓ The MariaDB user should have write access to the database
```
Test 6:
- Enige fout die overblijft is :
```
 ✗ The certificate should not be the default one
  (in test file /vagrant/test/pu001/lamp.bats, line 90)
  `[ -z "(echo ${output} | grep SomeOrganization)" ]' failed
```
Test 7:
```
13 tests, 0 failures, 1 skipped
Running test /vagrant/test/pu001/lamp.bats
 ✓ The necessary packages should be installed
 ✓ The Apache service should be running
 ✓ The Apache service should be started at boot
 ✓ The MariaDB service should be running
 ✓ The MariaDB service should be started at boot
 ✓ The SELinux status should be ‘enforcing’
 ✓ Web traffic should pass through the firewall
 ✓ Mariadb should have a database for Wordpress
 ✓ The MariaDB user should have write access to the database
 ✓ The website should be accessible through HTTP
 ✓ The website should be accessible through HTTPS
 ✓ The certificate should not be the default one
 ✓ The Wordpress install page should be visible under http://203.0.113.10/wordpress/
 ✓ MariaDB should not have a test database
 ✓ MariaDB should not have anonymous users
```

## Resources

- docu Ansible Galaxy voor de rollen bertvv.httpd, bertvv.mariadb, bertvv.wordpress
- video troubleshooting (voor het firewall gedeelte)
- https://wiki.centos.org/HowTos/Https
