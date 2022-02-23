# Enterprise Linux Lab Report

- Student name: Yves Masscho
- Github repo: <https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git>

Describe the goals of the current iteration/assignment in a short sentence.

## Test plan

1. Is de BIND-service running?

```
[vagrant@pr001 ~]$ systemctl status named
● named.service - Berkeley Internet Name Domain (DNS)
   Loaded: loaded (/usr/lib/systemd/system/named.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-01-18 21:39:24 UTC; 2min 32s ago
  Process: 10947 ExecReload=/bin/sh -c /usr/sbin/rndc reload > /dev/null 2>&1 || /bin/kill -HUP $MAINPID (code=exited, status=0/SUCCESS)
  Process: 10913 ExecStart=/usr/sbin/named -u named -c ${NAMEDCONF} $OPTIONS (code=exited, status=0/SUCCESS)
  Process: 10911 ExecStartPre=/bin/bash -c if [ ! "$DISABLE_ZONE_CHECKING" == "yes" ]; then /usr/sbin/named-checkconf -z "$NAMEDCONF"; else echo "Checking of zone files is disabled"; fi (code=exited, status=0/SUCCESS)
 Main PID: 10915 (named)
   CGroup: /system.slice/named.service
           └─10915 /usr/sbin/named -u named -c /etc/named.conf
```

2. Zit dns in de firewall rules?

```
[vagrant@pr001 ~]$ sudo firewall-cmd --list-all | grep dns
  services: ssh dhcpv6-client dns
```

2. Kan ik vanop de host ns1 queryen met het volgende:
- forward lookup
- reverse lookup
```
C:\Users\Yves>nslookup mail.avalon.lan 172.16.128.1
Server:  pr001.avalon.lan
Address:  172.16.128.1

Name:    pu002.avalon.lan
Address:  203.0.113.20
Aliases:  mail.avalon.lan


C:\Users\Yves>nslookup 172.16.128.3 172.16.128.1
Server:  pr001.avalon.lan
Address:  172.16.128.1

Name:    pr003.avalon.lan
Address:  172.16.128.3
```
2. Kan ik vanop de host ns2 queryen met het volgende:
- forward lookup
- reverse lookup
```
C:\Users\Yves>nslookup www.avalon.lan 172.16.128.2
Server:  pr002.avalon.lan
Address:  172.16.128.2

Name:    pu001.avalon.lan
Address:  203.0.113.10
Aliases:  www.avalon.lan

C:\Users\Yves>nslookup 172.16.128.11 172.16.128.2
Server:  pr002.avalon.lan
Address:  172.16.128.2

Name:    pr011.avalon.lan
Address:  172.16.128.11
```

**TO DO**

## Procedure/Documentation

1. Allereerst heb ik in site.yml de rol bertvv.rh-base bij all gezet, dit om dit niet voor elke machine te moeten herhalen.

2. Ik voeg pr001 en pr002 toe in vagrant-hosts.yml met de bijhorende ip-adressen en netmasks. Ook in site.yml werden de twee machines toegevoegd met beide de rol bertvv.bind. In de map host_vars voeg ik alvast 2 lege yml-files toe voor de twee, wel met de juiste headers. Een eerste keer proberen de machine up te krijgen zonder vars zorgt voor volgende error. Er is dus wat prep-werk aan de orde nog voor de VM zelf kan beginnen draaien.

```
TASK [bertvv.bind : Check whether `primaries` was set for each zone] ***********
failed: [pr001] (item=example.com) => {"ansible_loop_var": "item", "assertion": "item.primaries is defined", "changed": false, "evaluated_to": false, "item": {"hostmaster_email": "hostmaster", "name": "example.com", "networks": ["10.0.2"]}, "msg": "Assertion failed"}
```

3. In pr001.yml heb ik analoog de documentatie van bertvv.bind (gezien er heel wat moet ingesteld staan om een functionele VM te hebben) de volgende dingen toegevoegd: Allow query & listen beide: any. De mail server toegevoegd met preference 10. De hosts toegevoegd met hun IP en aliasen. Create reverse zones op true gezet (maar dit weer eruitgehaald gezien de default true is). Ik heb meteen ook dns toegelaten als service op de firewall.

4. Bij een nieuwe vagrant up zien we een klassieke fout opduiken: puntjes vergeten na FQDN (bij de nameservers). Dit wil ook zeggen dat we evengoed de avalon.lan kunnen laten vallen. Ik koos voor deze tweede optie. We laten de eerste keer de testen lopen (1). Alleen de mailserver faalt.

5. De mailserver faalde omdat de toekenning van de mailserver in de pr001.yml niet onder bind_zones werd gezet. Server ns1 lijkt hiermee goed ingesteld. Vervolgens stellen we ns2 in.

6. Ook in pr002.yml stel ik de firewall in om dns door te laten. Ook de allow query en listen stellen we in op any. We vullen onder bind_zones de naam in, de networks en de primary (ns1). We runnen de test op deze server (3).

7. De setup van deze twee servers verliep zeer vlot. Ik had BIND en DNS al onder de knie gekregen voor het troubleshootinglabo. De documentatie hiervoor is ook zeer straightforward.

## Test report

Test 1:
```
 ✗ Mail server lookup
   (from function `assert_mx_lookup' in file /vagrant/test/pr001/masterdns.bats, line 68,
    in test file /vagrant/test/pr001/masterdns.bats, line 158)
     `assert_mx_lookup 10 pu002' failed
```
Test 2:
```
[vagrant@pr001 vagrant]$ sudo ./test/runbats.sh
Running test /vagrant/test/common.bats
 ✓ SELinux should be set to 'Enforcing'
 ✓ Firewall should be enabled and running
 ✓ EPEL repository should be available
 ✓ Bash-completion should have been installed
 ✓ bind-utils should have been installed
 ✓ Git should have been installed
 ✓ Nano should have been installed
 ✓ Tree should have been installed
 ✓ Vim-enhanced should have been installed
 ✓ Wget should have been installed
 ✓ Admin user yves should exist
 ✓ An SSH key should have been installed for yves
 - Custom /etc/motd should have been installed (skipped)

13 tests, 0 failures, 1 skipped
Running test /vagrant/test/pr001/masterdns.bats
 ✓ The dig command should be installed
 ✓ The main config file should be syntactically correct
 ✓ The forward zone file should be syntactically correct
 ✓ The reverse zone files should be syntactically correct
 ✓ The service should be running
 ✓ Forward lookups public servers
 ✓ Forward lookups private servers
 ✓ Reverse lookups public servers
 ✓ Reverse lookups private servers
 ✓ Alias lookups public servers
 ✓ Alias lookups private servers
 ✓ NS record lookup
 ✓ Mail server lookup
```
Test 3 (pr002):
```
Installed Bats to /usr/local/bin/bats
Running test /vagrant/test/common.bats
 ✓ SELinux should be set to 'Enforcing'
 ✓ Firewall should be enabled and running
 ✓ EPEL repository should be available
 ✓ Bash-completion should have been installed
 ✓ bind-utils should have been installed
 ✓ Git should have been installed
 ✓ Nano should have been installed
 ✓ Tree should have been installed
 ✓ Vim-enhanced should have been installed
 ✓ Wget should have been installed
 ✓ Admin user yves should exist
 ✓ An SSH key should have been installed for yves
 - Custom /etc/motd should have been installed (skipped)

13 tests, 0 failures, 1 skipped
Running test /vagrant/test/pr002/slavedns.bats
 ✓ The dig command should be installed
 ✓ The main config file should be syntactically correct
 ✓ The server should be set up as a slave
 ✓ The server should forward requests to the master server
 ✓ There should not be a forward zone file
 ✓ The service should be running
 ✓ Forward lookups public servers
 ✓ Forward lookups private servers
 ✓ Reverse lookups public servers
 ✓ Reverse lookups private servers
 ✓ Alias lookups public servers
 ✓ Alias lookups private servers
 ✓ NS record lookup
 ✓ Mail server lookup

 14 tests, 0 failures
```

- nslookup van host via ns1
```
C:\Users\Yves>nslookup mail.avalon.lan 172.16.128.1
Server:  pr001.avalon.lan
Address:  172.16.128.1

Name:    pu002.avalon.lan
Address:  203.0.113.20
Aliases:  mail.avalon.lan


C:\Users\Yves>nslookup 172.16.128.3 172.16.128.1
Server:  pr001.avalon.lan
Address:  172.16.128.1

Name:    pr003.avalon.lan
Address:  172.16.128.3
```
- nslookup van host via ns2
```
C:\Users\Yves>nslookup www.avalon.lan 172.16.128.2
Server:  pr002.avalon.lan
Address:  172.16.128.2

Name:    pu001.avalon.lan
Address:  203.0.113.10
Aliases:  www.avalon.lan


C:\Users\Yves>nslookup 172.16.128.11 172.16.128.2
Server:  pr002.avalon.lan
Address:  172.16.128.2

Name:    pr011.avalon.lan
Address:  172.16.128.11
```


## Resources

- Documentation for bertvv.bind
- Documentation for Ansible skeleton by bertvv
