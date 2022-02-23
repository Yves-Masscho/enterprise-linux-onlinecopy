# Enterprise Linux Lab Report

- Student name: Yves Masscho
- Github repo: <https://github.com/HoGentTIN/elnx-2021-sme-Yves-Masscho.git>

Setting up the basics for the first server: pu001

## Test plan

1. Kijken of SELinux enforced is: `getenforce`
Verwachte output: 
```
Enforcing
```
2. Kijken of de firewall actief en enabled is: `systemctl status firewalld`
In de output zoeken we naar 'enabled' en 'active':
```
 Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Tue 2020-12-15 18:52:32 UTC; 1min 58s ago
```
3. Om te kijken of alle packages zijn geinstalleerd runnen we de voorziene test voor deze VM. Indien je dit toch wil checken kan je `rpm -qa | grep PACKAGE` gebruiken waar je package vervangt door het gevraagde item.
```
[vagrant@pu001 ~]$ rpm -qa | grep git
net-tools-2.0-0.24.20131004git.el7.x86_64
linux-firmware-20180911-69.git85c5d90.el7.noarch
git-1.8.3.1-23.el7_8.x86_64
crontabs-1.11-6.20121102git.el7.noarch
[vagrant@pu001 ~]$ rpm -qa | grep yum
yum-utils-1.1.31-50.el7.noarch
yum-3.4.3-161.el7.centos.noarch
yum-metadata-parser-1.1.4-10.el7.x86_64
yum-plugin-fastestmirror-1.1.31-50.el7.noarch
```

4. Om je user te controleren: `getent passwd yves`. Verwachte output is je user en Administrator
```
yves:x:1001:1001:Administrator:/home/yves:/bin/bash
```

## Procedure/Documentation

###### A. First steps **15/11/2020**

1. Allereerst heb ik de rol bertvv.rh-base toegevoegd in de site.yml file en het script deze rol laten toevoegen.
`./scripts/role-deps.sh`

2. De VM opstarten geeft een **error**. Later zien we dat dit te fixen valt met een workaround in de rol bertvv: 
```
TASK [bertvv.rh-base : include_tasks] fatal: [pu001]: FAILED! => {"reason": "couldn't resolve module/action 'ansible.posix.firewalld'. This often indicates a misspelling, missing collection, or incorrect module path.\n\nThe error appears to be in '/vagrant/ansible/roles/bertvv.rh-base/tasks/security.yml': line 33, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: Security | Make sure basic services can pass through firewall\n  ^ here\n"}
```

3. Ik heb hier even op getroubleshoot, toen ik nog niet wist dat er een workaround was.
```
sudo systemctl status firewalld
- firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: failed (Result: timeout) since Sun 2020-11-15 16:35:03 UTC; 15s ago
     Docs: man:firewalld(1)
  Process: 11500 ExecStart=/usr/sbin/firewalld --nofork --nopid $FIREWALLD_ARGS (code=exited, status=0/SUCCESS)
 Main PID: 11500 (code=exited, status=0/SUCCESS)
Nov 15 16:33:33 pu001 systemd[1]: Starting firewalld - dynamic firewall daemon...
Nov 15 16:35:03 pu001 systemd[1]: firewalld.service start operation timed out. Terminating.
Nov 15 16:35:03 pu001 systemd[1]: Failed to start firewalld - dynamic firewall daemon.
Nov 15 16:35:03 pu001 systemd[1]: Unit firewalld.service entered failed state.
Nov 15 16:35:03 pu001 systemd[1]: firewalld.service failed.

sudo systemctl stop firewalld
sudo pkill -f firewalld
sudo systemctl start firewalld
sudo systemctl status firewalld

- firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: active (running) since Sun 2020-11-15 16:39:08 UTC; 14s ago
     Docs: man:firewalld(1)
 Main PID: 11823 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─11823 /usr/bin/python -Es /usr/sbin/firewalld --nofork --nopid

- Dit lost het probleem voor de test niet op... Waarom niet? Should be enabled and running.

sudo systemctl enable firewalld

- Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
```

4. Ik heb de nodige rhbase_install_packages toegevoegd aan ansible/group_vars/all.yml en vagrant/host_vars/pu001.yml aangemaakt, voorlopig leeg.


```
to do: 
1. firewall enabling automatiseren in ansible of zoeken waar het probleem zit (want dit zou eigenlijk WEL moeten ok zijn)
2. waarom is SELinux not 'Enforcing'?
3. Admin user bert + SSH key installed for bert
```

###### B. Opvolging **29/11/2020**

1. Het firewalld problemen werd verholpen door te kijken op Teams bij Errata en de workaround toe te passen. SELinux to Enforcing probleem is hierdoor ook verholpen.
2. User ~~bert~~ yves toegevoegd met adminrechten.
3. password hash en ssh-key toegevoegd


## Test report

###### first test (15/11)
```
Running test /vagrant/test/common.bats  
 ✗ SELinux should be set to 'Enforcing'  
   (in test file /vagrant/test/common.bats, line 7)  
     [ 'Enforcing' = $(getenforce) ] failed  
 ✗ Firewall should be enabled and running  
   (in test file /vagrant/test/common.bats, line 11)  
     systemctl is-active firewalld.service' failed with status 3  
   unknown  
 ✓ EPEL repository should be available  
 ✓ Bash-completion should have been installed  
 ✓ bind-utils should have been installed  
 ✓ Git should have been installed  
 ✓ Nano should have been installed  
 ✓ Tree should have been installed  
 ✓ Vim-enhanced should have been installed  
 ✓ Wget should have been installed  
 ✗ Admin user bert should exist  
   (in test file /vagrant/test/common.bats, line 51)  
     `getent passwd ${admin_user}' failed with status 2  
 ✗ An SSH key should have been installed for bert  
   (in test file /vagrant/test/common.bats, line 58)  
     `[ -f "${keyfile}" ]' failed  
 - Custom /etc/motd should have been installed (skipped)  
```
 ###### Second test after firewall troubleshooting (15/11)
```
 Running test /vagrant/test/common.bats  
 ✗ SELinux should be set to 'Enforcing'  
   (in test file /vagrant/test/common.bats, line 7)  
     [ 'Enforcing' = $(getenforce) ]' failed  
 ✓ Firewall should be enabled and running
 ✓ EPEL repository should be available  
 ✓ Bash-completion should have been installed  
 ✓ bind-utils should have been installed  
 ✓ Git should have been installed  
 ✓ Nano should have been installed  
 ✓ Tree should have been installed  
 ✓ Vim-enhanced should have been installed  
 ✓ Wget should have been installed  
 ✗ Admin user bert should exist  
   (in test file /vagrant/test/common.bats, line 51)  
     `getent passwd ${admin_user}' failed with status 2  
 ✗ An SSH key should have been installed for bert  
   (in test file /vagrant/test/common.bats, line 58)  
     `[ -f "${keyfile}" ]' failed  
 - Custom /etc/motd should have been installed (skipped)  
```
 ###### Final test (29/11)
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
```


## Resources

- video-opname les02
- https://www.linode.com/docs/guides/introduction-to-firewalld-on-centos/
- https://stackoverflow.com/questions/36467658/failed-to-start-firewalld-on-centos-7/50544307
- https://galaxy.ansible.com/bertvv/rh-base
- Teams Errata