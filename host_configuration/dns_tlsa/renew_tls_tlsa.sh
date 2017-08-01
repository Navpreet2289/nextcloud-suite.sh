#!/bin/bash
set -e
#certbot certonly --duplicate --redirect --hsts --webroot --dry-run \
#  -w /home/letsencrypt/ -d pad.selfhosted.xyz \
#                        -d selfhosted.xyz \
#                        -d server0.selfhosted.xyz \
#			-d shop.selfhosted.xyz \
#			-d sip.selfhosted.xyz \
#			-d social.selfhosted.xyz \
#			-d xmpp.selfhosted.xyz \
#			-d blog.selfhosted.xyz \
#			-d cctv.selfhosted.xyz \
#			-d cloud.selfhosted.xyz \
#			-d irc.selfhosted.xyz \
#			-d search.selfhosted.xyz \
#			-d office.selfhosted.xyz \
#			-d maps.selfhosted.xyz \
#			-d media.selfhosted.xyz \
#			-d openveganarchism.selfhosted.xyz \
#			-d piwik.selfhosted.xyz \
#  -w /var/www/mail/rc/  -d webmail.selfhosted.xyz \
#  -w /usr/share/dokuwiki/ -d wiki.selfhosted.xyz \
#  -w /var/www/mail/ -d mail.selfhosted.xyz \
# --dry-run \

certpath="/etc/letsencrypt/live/selfhosted.xyz/cert.pem"
chainpath="/etc/letsencrypt/live/selfhosted.xyz/chain.pem"
fullchainpath="/etc/letsencrypt/live/selfhosted.xyz/fullchain.pem"
keypath="/etc/letsencrypt/live/selfhosted.xyz/privkey.pem"
zonefile='/etc/bind/db.selfhosted.xyz'
domain="selfhosted"
tld="xyz"
oldhash="$(cat "$zonefile" | grep "${domain}"."${tld}" | grep TLSA | tail -n 1 | awk ' { print $7 } ')"

# for libreoffice-online
looluser="lool"
loolgroup="lool"
saveNginx(){
    mkdir -p /tmp/nginx_enabled_conf_files/
    mv /etc/nginx/sites-enabled/* /tmp/nginx_enabled_conf_files/
}

installAcmeChallengeConfiguration(){
cat <<EOF > /etc/nginx/snippets/letsencryptauth.conf
location /.well-known/acme-challenge {
    alias /etc/letsencrypt/webrootauth/.well-known/acme-challenge;
    location ~ /.well-known/acme-challenge/(.*) {
    add_header Content-Type application/jose+json;
    }
}
EOF

cat <<EOF > /etc/nginx/sites-enabled/default
server {
    listen 80 default_server;
    root /etc/letsencrypt/webrootauth;
    include snippets/letsencryptauth.conf;
}
EOF
service nginx reload
sleep 1
}

getCerts(){
certbot certonly --duplicate --redirect --hsts --staple-ocsp --webroot -w /etc/letsencrypt/webrootauth -d selfhosted.xyz -d www.selfhosted.xyz -d server0.selfhosted.xyz -d analytics.selfhosted.xyz -d blog.selfhosted.xyz -d cctv.selfhosted.xyz -d cloud.selfhosted.xyz -d irc.selfhosted.xyz -d maps.selfhosted.xyz -d media.selfhosted.xyz -d office.selfhosted.xyz -d openveganarchism.selfhosted.xyz -d piwik.selfhosted.xyz -d pad.selfhosted.xyz -d search.selfhosted.xyz -d shop.selfhosted.xyz -d social.selfhosted.xyz -d sip.selfhosted.xyz -d useritsecurity.selfhosted.xyz -d xmpp.selfhosted.xyz -d webmail.selfhosted.xyz -d wiki.selfhosted.xyz -d mail.selfhosted.xyz
}

#basepath="/etc/letsencrypt/live/${domain}"
#length=${#basepath}
#totlength=$(($length+5))

installNewCerts(){
    # here we are assuming that the path ending is on the form selfhosted.xyz-XXXX
    newcertdir="/etc/letsencrypt/live/"$(ls -l /etc/letsencrypt/live/ | tail -n 1 | awk ' {print $9} ')""
    ln -s -f $newcertdir/cert.pem $certpath
    ln -s -f $newcertdir/chain.pem $chainpath
    ln -s -f $newcertdir/fullchain.pem $fullchainpath
    ln -s -f $newcertdir/privkey.pem $keypath
#    echo "installed new certs"
}
# certpath=/etc/letsencrypt/live/selfhosted.xyz/cert.pem
# chainpath=/etc/letsencrypt/live/selfhosted.xyz/chain.pem
# fullchainpath=/etc/letsencrypt/live/selfhosted.xyz/fullchain.pem
# keypath=/etc/letsencrypt/live/selfhosted.xyz/privkey.pem
updateDNSSec(){
    newhash=$(tlsa_rdata $fullchainpath 3 1 1 | grep "3 1 1" | awk ' { print $4 } ')
    sed -i "s/$oldhash/$newhash/g" "${zonefile}"
    zone=""${domain}"."${tld}""
    zonesigner.sh "${zone}" "${zonefile}"
    systemctl restart bind9
}
restoreNginx(){
mv /tmp/nginx_enabled_conf_files/* /etc/nginx/sites-enabled/
}
updateLoolCerts(){
    cp /etc/letsencrypt/live/selfhosted.xyz/cert.pem /opt/online/etc/mykeys/cert1.pem
    cp /etc/letsencrypt/live/selfhosted.xyz/privkey.pem /opt/online/etc/mykeys/privkey1.pem    
    cp /etc/letsencrypt/live/selfhosted.xyz/fullchain.pem /opt/online/etc/mykeys/fullchain1.pem
    cp /etc/letsencrypt/live/selfhosted.xyz/chain.pem /opt/online/etc/mykeys/chain1.pem
    chown -R ${looluser}:${loolgroup} /opt/online/etc/mykeys/
}
restartWebServer(){
    systemctl restart nginx
}

main(){
    saveNginx
    installAcmeChallengeConfiguration
    getCerts
    installNewCerts
    updateDNSSec
    restoreNginx
    updateLoolCerts
    restartWebServer
}
main
