
## Project Overview
The goal is to write scripts that autoconfigures a "Netbox" or "Hostbox" with the following:
  * HostOS: Devuan for now, but might be Hyperbola later.
  * Host-network-layer: cjdns, gnunet, VPN with public ip. (including mesh auto-peering)
  * Host-firewall: iptables, ipset.
  * Host-DNS: BIND9 with DNSSec and automatic renewal of TLSA, SSHFP and OpenPGP records.
  * Host-rev-proxy: nginx sending requests to virtual machines.  
  * Virtual Machine 1: full email stack
    * either on a GuixSD system with OpenSMTPD, Dovecot, clamav, spamassasin.
    * or one of Devuan and Hyperbola using Postfix, Dovecot, spamassasin, clamav. 
  * Virtual Machine 2: Nextcloud suite
    * on a Debian system with: LibreOffice Online, Etherpad-lite, SpreedME (coturn turn-server)
    * or later on either Hyperbola, Devuan or GuixSD.
  * Virtual Machine 3: Dokuwiki
  * Virtual Machine 4: Opencart webstore
Ultimately, I would run everything on GuixSD and do this whole project by writing system declarations in Guile.

## libreoffice-install.sh
The libreoffice-install.sh was tested to work on Debian Testing with Nextcloud running with nginx, mariadb, and php7 with the following sources and commit versions:
  - LibreOffice Core commit=4c0040b6f1e3137e0d40aab09088c43214db3165 url=https://github.com/LibreOffice/core.git
  - Poco=poco-1.7.7-all.tar.gz url: http://pocoproject.org/releases/poco-1.7.7/poco-1.7.7-all.tar.gz
  - LibreOffice Online=91666d7cd354ef31344cdd88b57d644820dcd52c url=https://github.com/LibreOffice/online

It will install
  - LibreOffice Core in /opt/core
  - Poco in /opt/poco
  - LibreOffice Online in /opt/online
The LibreOffice Online web-socket daemon (loolwsd) will run on localhost:9980 which you can connect to from Nextcloud.

You can manage your service with systemctl start/stop/status loolwsd.service.

Enjoy!!!

### Prerequisites
  - A running NextCloud server (i.e. won't setup nginx configuration for you).
  - Valid letsencrypt certificates for your domain in /etc/letsencrypt/mydomain.tld/*

### Installation
After running ./libreoffice-online.sh you need to go to apps section in your Nextcloud admin page and enable the Collabora Online app. Then to Admin->Admin->Collabora Online and enter your url and port number. If you visit your cloud instance at https://nextcloud.mydomain.com you would enter https://nextcloud.mydomain.com:9980

Also, read the first run info dialog box and then the building process should mostly run on it's own.

You might need to go to /opt/online/loolwsd.xml and put a line like this there next to the other similar ones.
<host desc="Regex pattern of hostname to allow or deny." allow="true" cloud.mydomain.com

THE INSTALLATION WILL TAKE REALLY VERY LONG TIME SO BE PATIENT PLEASE!!! You may eventually see errors during the installation, just ignore them."
