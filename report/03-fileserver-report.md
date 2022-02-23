# Enterprise Linux Lab Report

- Student name: Yves Masscho
- Github repo: <https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git>

Setting up a server for filesharing with Samba and ftp.

## Test plan

1. Is de smb-service actief?

```
[vagrant@pr011 ~]$ systemctl status smb
● smb.service - Samba SMB Daemon
   Loaded: loaded (/usr/lib/systemd/system/smb.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-01-18 21:06:30 UTC; 10min ago
     Docs: man:smbd(8)
           man:samba(7)
           man:smb.conf(5)
 Main PID: 12035 (smbd)
   Status: "smbd: ready to serve connections..."
   CGroup: /system.slice/smb.service
           ├─12035 /usr/sbin/smbd --foreground --no-process-group
           ├─12037 /usr/sbin/smbd --foreground --no-process-group
           └─12038 /usr/sbin/smbd --foreground --no-process-group

Warning: Journal has been rotated since unit was started. Log output is incomplete or unavailable.
```

2. Is vsftpd actief?

```
[vagrant@pr011 ~]$ systemctl status vsftpd
● vsftpd.service - Vsftpd ftp daemon
   Loaded: loaded (/usr/lib/systemd/system/vsftpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-01-18 21:06:30 UTC; 11min ago
  Process: 12098 ExecStart=/usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf (code=exited, status=0/SUCCESS)
 Main PID: 12099 (vsftpd)
   CGroup: /system.slice/vsftpd.service
           ├─12099 /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
           ├─12452 /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf
           └─12457 /usr/sbin/vsftpd /etc/vsftpd/vsftpd.conf

```

3. Zitten ftp en samba in de firewall rules?

```
[vagrant@pr011 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: eth0 eth1
  sources:
  services: ssh dhcpv6-client samba ftp
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

4. Kan ik met user and inloggen via het hostsysteem? Kan ik in de directory sales gaan (mag niet)? Kan ik in de directory technical gaan?

```
C:\Users\Yves>ftp 172.16.128.11
Connected to 172.16.128.11.
220 (vsFTPd 3.0.2)
200 Always in UTF8 mode.
User (172.16.128.11:(none)): anc
331 Please specify the password.
Password:
230 Login successful.
ftp> dir
200 PORT command successful. Consider using PASV.
150 Here comes the directory listing.
drwxrwx---    2 0        1004            6 Jan 18 21:06 it
drwxrwx---    2 0        1001            6 Jan 18 21:06 management
drwxrwxr-x    2 0        1005            6 Jan 18 21:06 public
drwxrwx---    2 0        1003            6 Jan 18 21:06 sales
drwxrwxr-x    2 0        1002            6 Jan 18 21:06 technical
226 Directory send OK.
ftp: 325 bytes received in 0.01Seconds 46.43Kbytes/sec.
ftp> cd sales
550 Failed to change directory.
ftp> cd technical
250 Directory successfully changed.
```

5. Vanaf nu testen we met FileZilla. Kan ik als user anc een file plaatsen in technical? Kan ik de filenaam veranderen?
```
Status:	Logged in
Status:	Retrieving directory listing...
Status:	Directory listing of "/srv/shares" successful
Status:	Connecting to 172.16.128.11:21...
Status:	Connection established, waiting for welcome message...
Status:	Insecure server, it does not support FTP over TLS.
Status:	Logged in
Status:	Starting upload of C:\Zilla\backup-exam.sh
Status:	File transfer successful, transferred 2.145 bytes in 1 second
```
```
Status:	Renaming '/srv/shares/technical/backup-exam.sh' to '/srv/shares/technical/backdown-exam.sh'
```

6. Kan ik met een managementuser die file van naam veranderen (getest met elenaa, moet negatief resultaat geven) en meteen ook checken of ik de directory technical kan zien (positief)?
```
Status:	Directory listing of "/srv/shares/technical" successful
Status:	Renaming '/srv/shares/technical/backdown-exam.sh' to '/srv/shares/technical/backdown-mondeling.sh'
Command:	RNFR backdown-exam.sh
Response:	350 Ready for RNTO.
Command:	RNTO backdown-mondeling.sh
Response:	550 Rename failed.
```

## Procedure/Documentation

####Samba

1. Nog voor we aan Samba beginnen moeten we eerst de users aanmaken voor ons systeem zelf. Dit gebeurt via de reeds geinstalleerde rol rh-base. We maken de users aan, voorlopig zonder groups. Een stukje uit /etc/passwd: 

```
yves:x:1001:1005:Administrator:/home/yves:/bin/bash
stevenh:x:1002:1006::/home/stevenh:/bin/bash
stevenv:x:1003:1007::/home/stevenv:/bin/bash
leend:x:1004:1008::/home/leend:/bin/bash
svena:x:1005:1009::/home/svena:/bin/bash
nehirb:x:1006:1010::/home/nehirb:/bin/bash
alexanderd:x:1007:1011::/home/alexanderd:/bin/bash
krisv:x:1008:1012::/home/krisv:/bin/bash
benoitp:x:1009:1013::/home/benoitp:/bin/bash
anc:x:1010:1014::/home/anc:/bin/bash
elenaa:x:1011:1015::/home/elenaa:/bin/bash
evyt:x:1012:1016::/home/evyt:/bin/bash
christophev:x:1013:1017::/home/christophev:/bin/bash
stefaanv:x:1014:1018::/home/stefaanv:/bin/bash
```

We testen of we op het systeem kunnen veranderen van user met een fout en een juist paswoord. 
```
[evyt@pu001 vagrant]$ su stefaanv
Password:
su: Authentication failure
[evyt@pu001 vagrant]$ su stefaanv
Password:
              ___   ___  _
 _ __  _   _ / _ \ / _ \/ |
| '_ \| | | | | | | | | | |
| |_) | |_| | |_| | |_| | |
| .__/ \__,_|\___/ \___/|_|
|_|
```
Dit werkt perfect.

2. We koppelen elke user aan zijn groep en ook aan public. We doen dit ook voor onze eigen user.

```
[vagrant@pu001 ~]$ groups stefaanv
stefaanv : stefaanv technical public
[vagrant@pu001 ~]$ groups yves
yves : yves wheel it public
```

3. We installeren de rol `bertvv.samba`. Zonder enige vars in te vullen zorgt dit er reeds voor dat de nmblookup, smbclient commands zijn geinstalleerd. Ook de Samba service loopt en is enabled, idem voor Winbind.

4. We stellen in dat Samba door de firewall mag.

5. We maken nu de users opnieuw aan voor Samba. De paswoorden komen in plaintext terecht in de file. We stellen ook de netbiosnaam in op files.

6. We maken de shares aan met de juiste read en/of write toegangen. Map to guest gaat op never. Printshare off. We laten de testen eens lopen (1). De testen voor Samba specifiek lijken te lukken na wat kleine typfoutjes en een verkeerde write access weg te werken. 

#### vsftpd

7. We installeren de rol `bertvv.vsftpd` en laten ftp door de firewall gaan.

8. We stellen in dat anonieme users niet kunnen inloggen, lokale wel. (Alleen de combinatie van deze twee doen de test slagen).

9. We stellen de extra permissions in voor alle shares. We laten de testen eens lopen (2). De testen laten we lopen met de admin_user en admin_pasword in comment, want daar loopt iets fout.

10. Voor de shares waar public geen read-rechten heeft lopen de tests fout. Het zowel toevoegen van alle groepen met permission "---" of alleen public met "---" verandert hier niets aan.

11. Na wat testen/troubleshooten haal ik alle special permissions weg. Even vanaf nul beginnen. De fout bij management wordt weggewerkt door aan de samba-share de directory mode toe te voegen. Ook bij Sales in IT zorgt ervoor dat de fout, ten minste voor de gewone users, niet meer voorkomt. Voor de management-users lijkt dit nog niet ok (dit zie ik doordat elenaa en niet alexanderd de fout veroorzaakt). Test (3).

12. Na het door te hebben dat de fout dus bij de ACL's lag (ook provision deed weinig bij het updaten van de extra permissions) ben ik op Teams gaan kijken. Ik had de rol geïnstalleerd via ansible galaxy. Het was echter die vanop github die de ACL's juist aanmaakte. Aangepast. Alles werkt. Test (4).

13. Update 17/01: probleem met admin user opgelost, paswoord geupdate en probleem verholpen. Alle acceptatietests runnen nu zonder het admindeel in vsftpd in comment te moeten zetten. Ook heb ik de users van all naar pr011 verplaatst, dit voor oa performantieredenen.

## Test report

Test 1:
```
Running test /vagrant/test/pr011/samba.bats
 ✓ The ’nmblookup’ command should be installed
 ✓ The ’smbclient’ command should be installed
 ✓ The Samba service should be running
 ✓ The Samba service should be enabled at boot
 ✓ The WinBind service should be running
 ✓ The WinBind service should be enabled at boot
 ✓ The SELinux status should be ‘enforcing’
 ✓ Samba traffic should pass through the firewall
 ✓ Check existence of users
 ✓ Checks shell access of users
 ✓ Samba configuration should be syntactically correct
 ✓ NetBIOS name resolution should work
 ✓ read access for share ‘public’
 ✓ write access for share ‘public’
 ✓ read access for share ‘management’
 ✓ write access for share ‘management’
 ✓ read access for share ‘technical’
 ✓ write access for share ‘technical’
 ✓ read access for share ‘sales’
 ✓ write access for share ‘sales’
 ✓ read access for share ‘it’
 ✓ write access for share ‘it’
```

Test 2:
```
Running test /vagrant/test/pr011/vsftp.bats
 ✓ VSFTPD service should be running
 ✓ VSFTPD service should be enabled at boot
 ✓ The ’curl’ command should be installed
 ✓ The SELinux status should be ‘enforcing’
 ✓ FTP traffic should pass through the firewall
 ✓ VSFTPD configuration should be syntactically correct
 ✓ Anonymous user should not be able to see shares
 ✓ read access for share ‘public’
 ✓ write access for share ‘public’
 ✗ read access for share ‘management’
   (from function `assert_no_read_access' in file test/pr011/vsftp.bats, line 48,
    in test file test/pr011/vsftp.bats, line 171)
     `assert_no_read_access  management alexanderd    alexanderd' failed
 ✓ write access for share ‘management’
 ✓ read access for share ‘technical’
 ✓ write access for share ‘technical’
 ✗ read access for share ‘sales’
   (from function `assert_no_read_access' in file test/pr011/vsftp.bats, line 48,
    in test file test/pr011/vsftp.bats, line 246)
     `assert_no_read_access  sales      alexanderd    alexanderd' failed
 ✓ write access for share ‘sales’
 ✗ read access for share ‘it’
   (from function `assert_no_read_access' in file test/pr011/vsftp.bats, line 48,
    in test file test/pr011/vsftp.bats, line 284)
     `assert_no_read_access  it         alexanderd    alexanderd' failed
 ✓ write access for share ‘it’
```

Test 3:
```
Running test /vagrant/test/pr011/vsftp.bats
 ✓ VSFTPD service should be running
 ✓ VSFTPD service should be enabled at boot
 ✓ The ’curl’ command should be installed
 ✓ The SELinux status should be ‘enforcing’
 ✓ FTP traffic should pass through the firewall
 ✓ VSFTPD configuration should be syntactically correct
 ✓ Anonymous user should not be able to see shares
 ✓ read access for share ‘public’
 ✓ write access for share ‘public’
 ✓ read access for share ‘management’
 ✓ write access for share ‘management’
 ✓ read access for share ‘technical’
 ✓ write access for share ‘technical’
 ✗ read access for share ‘sales’
   (from function `assert_read_access' in file /vagrant/test/pr011/vsftp.bats, line 36,
    in test file /vagrant/test/pr011/vsftp.bats, line 249)
     `assert_read_access     sales      elenaa        elenaa' failed with status 9
 ✓ write access for share ‘sales’
 ✗ read access for share ‘it’
   (from function `assert_read_access' in file /vagrant/test/pr011/vsftp.bats, line 36,
    in test file /vagrant/test/pr011/vsftp.bats, line 287)
     `assert_read_access     it         elenaa        elenaa' failed with status 9
 ✓ write access for share ‘it’

```

Test 4:
```
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
Running test /vagrant/test/pr011/samba.bats
 ✓ The ’nmblookup’ command should be installed
 ✓ The ’smbclient’ command should be installed
 ✓ The Samba service should be running
 ✓ The Samba service should be enabled at boot
 ✓ The WinBind service should be running
 ✓ The WinBind service should be enabled at boot
 ✓ The SELinux status should be ‘enforcing’
 ✓ Samba traffic should pass through the firewall
 ✓ Check existence of users
 ✓ Checks shell access of users
 ✓ Samba configuration should be syntactically correct
 ✓ NetBIOS name resolution should work
 ✓ read access for share ‘public’
 ✓ write access for share ‘public’
 ✓ read access for share ‘management’
 ✓ write access for share ‘management’
 ✓ read access for share ‘technical’
 ✓ write access for share ‘technical’
 ✓ read access for share ‘sales’
 ✓ write access for share ‘sales’
 ✓ read access for share ‘it’
 ✓ write access for share ‘it’

22 tests, 0 failures
Running test /vagrant/test/pr011/vsftp.bats
 ✓ VSFTPD service should be running
 ✓ VSFTPD service should be enabled at boot
 ✓ The ’curl’ command should be installed
 ✓ The SELinux status should be ‘enforcing’
 ✓ FTP traffic should pass through the firewall
 ✓ VSFTPD configuration should be syntactically correct
 ✓ Anonymous user should not be able to see shares
 ✓ read access for share ‘public’
 ✓ write access for share ‘public’
 ✓ read access for share ‘management’
 ✓ write access for share ‘management’
 ✓ read access for share ‘technical’
 ✓ write access for share ‘technical’
 ✓ read access for share ‘sales’
 ✓ write access for share ‘sales’
 ✓ read access for share ‘it’
 ✓ write access for share ‘it’

17 tests, 0 failures
```

## Resources

- Video les 7
- https://github.com/bertvv/ansible-role-samba
- https://github.com/bertvv/ansible-role-vsftpd
- https://www.samba.org/samba/docs/using_samba/