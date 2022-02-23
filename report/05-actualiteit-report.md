# Enterprise Linux Lab Report

- Student name: Yves Masscho
- Github repo: <https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git>

Installing OS Hardening & Fail2ban on the servers as a security measure.
Checking the setup with Lynis and seeing if we can edit even further.
Updating hashing algorythm to ensure better security

## Disclaimer

Het is niet dat ik deze opdracht heb laten liggen tot het einde, ik heb door verschuivingen op het werk (overnemen rol van vertrekkende teamlead) minder tijd gehad. Het was wel altijd mijn bedoeling om richting security te gaan in deze actualiteitsopdracht en heb na lang zoeken voor deze rol(len) + na afloop van het afwerken van de hele opstelling om alles nog eens door Lynis te laten controleren.

## Test plan

1. `sudo chage -l USER` toont de volgende waarden rechts, in plaats van never:

```
Password expires                                        : Feb 15, 2021
Minimum number of days between password change          : 3
Maximum number of days between password change          : 30
```

2. Verschillende ssh-pogingen met een verkeerd paswoord tonen in de logfile van Fail2Ban dat een IP geband werd. Bijvoorbeeld:
```
2021-01-16 19:01:49,938 fail2ban.filter         [22429]: INFO    [sshd] Found 203.0.113.1 - 2021-01-16 19:01:49
2021-01-16 19:02:19,375 fail2ban.filter         [22429]: INFO    [sshd] Found 203.0.113.1 - 2021-01-16 19:02:19
2021-01-16 19:02:19,876 fail2ban.actions        [22429]: NOTICE  [sshd] Ban 203.0.113.1
2021-01-16 19:02:49,961 fail2ban.actions        [22429]: NOTICE  [sshd] Unban 203.0.113.1
```

## Procedure/Documentation

#### OS Hardening

1. De rol **OS Hardening Collection** is een verzameling van een aantal tools die via ansible bepaalde aanpassingen doen met beveiliging in het achterhoofd. We kiezen in deze opstelling voor de **os-hardening**-rol. De mysql-rol, de ssh-rol en de nginx-rol laten we achterwege.  


2. Los van de instellingen die we gaan kiezen doet os-hardening het volgende:
```
    Removes unused yum repositories and enables GPG key-checking
    Removes packages with known issues
    Configures pam for strong password checks
    Installs and configures auditd
    Disables core dumps via soft limits
    sets a restrictive umask
    Configures execute permissions of files in system paths
    Hardens access to shadow and passwd files
    Disables unused filesystems
    Disables rhosts
    Configures secure ttys
    Configures kernel parameters via sysctl
    Enables selinux on EL-based systems
    Removes SUIDs and GUIDs
    Configures login and passwords of system accounts
```

3. We installeren de rollen en laten op de verschillende servers nog eens de acceptatietests lopen om te zien of daar al niets foutloopt. Alle testen slagen nog.

4. We stellen de maximum password age in op 30 dagen. De minimumtijd om je paswoord te veranderen (na een verandering) is 3 dagen. Het aantal login-attempts stellen we in op 3, daarna volgt een tijdelijke lockout. Die lockout stellen we in op 5 minuten (300 seconden). Dit zijn vooral strictere opties dan diegene die in de rol als default staan.

5. We testen of de paswoorden nu wel degelijk een andere policy hebben met `sudo chage -l USER`. De expiration staat op never. Dit is dus niet in orde. 
```
[vagrant@pu001 ~]$ sudo chage -l yves
Last password change                                    : Jan 16, 2021
Password expires                                        : never
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 0
Maximum number of days between password change          : 99999
Number of days of warning before password expires       : 7
```

6. Ik probeer om de rol OS Hardening te laten lopen voor rh-base zodat de policies ingesteld worden voor het aanmaken van de users. Dit zorgt er inderdaad voor dat de veranderingen OK zijn.
```
[vagrant@pu001 ~]$ sudo chage -l yves
Last password change                                    : Jan 16, 2021
Password expires                                        : Feb 15, 2021
Password inactive                                       : never
Account expires                                         : never
Minimum number of days between password change          : 3
Maximum number of days between password change          : 30
```

#### Fail2Ban

7. Ik had eerst voor bovenstaande rol gekozen omdat die redelijk up-to-date is. De **Fail2Ban** rol die ik vond was al een tijd niet geupdate. Maar na wat onderzoek en lezen is het wel nog steeds een rol die werkt op de huidige omgeving, daarom implementeer ik deze ook in mijn setup. We voegen deze rol toe in onze bestanden. Gezien alleen onze webserver te bereiken is vanuit de buitenwereld zal deze rol geconfigureerd worden op pu001 en in bijhorende files.

8. Ik stel voor ssh en ftp een custom logfile in, de max retry voor beide staan op twee. De bantime op 10 seconden om te testen.

9. We testen een ssh login met user anc en proberen 3 keer een fout paswoord. De naam in de vars moet sshd zijn, ssh werkt niet.
```
$ ssh anc@203.0.113.10
anc@203.0.113.10's password:
Permission denied, please try again.
anc@203.0.113.10's password:
Connection reset by 203.0.113.10 port 22

```
Log:
```
2021-01-16 19:01:49,938 fail2ban.filter         [22429]: INFO    [sshd] Found 203.0.113.1 - 2021-01-16 19:01:49
2021-01-16 19:02:19,375 fail2ban.filter         [22429]: INFO    [sshd] Found 203.0.113.1 - 2021-01-16 19:02:19
2021-01-16 19:02:19,876 fail2ban.actions        [22429]: NOTICE  [sshd] Ban 203.0.113.1
2021-01-16 19:02:49,961 fail2ban.actions        [22429]: NOTICE  [sshd] Unban 203.0.113.1
```

10. We stellen voor de live omgeving de bantime op 10 minuten. Custom logfiles werden uit de opstelling gehaald omdat de logs toch in de algemene file terechtkomen.

#### Lynis

11. Eens de hele omgeving werkt, zal hieronder de bijzondere delen van de Lynis-scan worden gezet met indien mogelijks acties om de configuratie te verbeteren. Onderstaand zet ik de warnings en suggesties waar ik daadwerkelijk mee aan de slag kan.

Voor:
```
 Lynis security scan details:

  Hardening index : 71 [##############      ]
```

###### Een aantal suggesties van Lynis en hun oplossingen:

**Warnings**

12. Warning 1
```
  ! No GPG signing option found in yum.conf [PKGS-7387]
      https://cisofy.com/lynis/controls/PKGS-7387/
```
oplossing:
```
rhbase_repo_gpgcheck: true
```

**Suggestions**

13. Suggestie 1

```
  * Harden the system by installing at least one malware scanner, to perform periodic file system scans [HRDN-7230]
    - Solution : Install a tool like rkhunter, chkrootkit, OSSEC
      https://cisofy.com/lynis/controls/HRDN-7230/
```
oplossing: installeren van rootkithunter
```
rhbase_install_packages: # voor alle VMs, specifics niet in all zetten
...
  - rkhunter
```
14. Suggestie 2
```
  * Install Apache mod_evasive to guard webserver against DoS/brute force attempts [HTTP-6640]
      https://cisofy.com/lynis/controls/HTTP-6640/
```
Dit wordt reeds opgevangen door fail2ban.

15. Na:
```
 Lynis security scan details:

  Hardening index : 74 [##############      ]
```

#### Verdere aanpassingen naar security toe:

16. Aanpassen encryptie van het huidige MD-5 naar SHA-256. Voor kortere strings is deze de performatere keuze boven SHA-512 terwijl die nog steeds voor voldoende security zorgt, beter dan MD-5.

```
  - name: stevenh
    groups:
      - management
      - public
    password: '$1$uNzDW.rh$2HNVrXEo5kubuouUha434/'
```
wordt
```
  - name: stevenh
    groups:
      - management
      - public
    password: '$5$Xrbi2B9QoKgO7gzF$F4uxSkm6W6kvhEEZGX3QgKTnqyu8.WhbN3UuWjQbR96'
```

## Resources

https://github.com/dev-sec/ansible-collection-hardening/tree/master/roles/os_hardening  

rhosts file security issue: https://docs.oracle.com/cd/E19683-01/816-4882/remotehowtoaccess-2/index.html  

https://www.fail2ban.org/wiki/index.php/Main_Page  

https://documentation.online.net/en/dedicated-server/tutorials/security/install-configure-fail2ban  

SSH brute force protection tutorial: https://www.youtube.com/watch?v=Z0cDqF6HAxs  