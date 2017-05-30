#!/bin/bash
#set -e
# -------------------------------------------------------- #
#
# Dependencies: zonesigner.sh tlsa_rdata from https://github.com/shuque/tlsa_rdata
#
# Just fill in these fields and run the script with:
# chmod u+x renew_tls_tlsa.sh && ./renew_tls_tlsa.sh
domain="selfhosted.xyz"
tld="xyz"
subdomains=(www server0 analytics blog cctv cloud irc maps media office openveganarchism piwik pad search shop social sip useritsecurity xmpp webmail wiki mail)
tls_services=(postfix dovecot loolwsd coturn etherpad-lite bind9 nginx)
# -------------------------------------------------------- #

cert="/etc/letsencrypt/live/"${domain}"."${tld}"/cert.pem"
chain="/etc/letsencrypt/live/"${domain}"."${tld}"/chain.pem"
fullchain="/etc/letsencrypt/live/"${domain}"."${tld}"/fullchain.pem"
privkey="/etc/letsencrypt/live/"${domain}"."${tld}"/privkey.pem"

loolcertsdir="/opt/online/etc/mykeys/"
loolcert=""${loolcertsdir}"cert1.pem"
loolchain=""${loolcertsdir}"chain1.pem"
loolfullchain=""${loolcertsdir}"fullchain1.pem"
loolprivkey=""${loolcertsdir}"privkey1.pem"

zonefile="/etc/bind/db."${domain"."${tld}""
oldhash="$(cat "$zonefile" | grep "${domain}"."${tld}" | grep TLSA | tail -n 1 | awk ' { print $7 } ')"

# for fucky libreoffice-online certs in /opt/online/etc/mykeys/* which are copies of LE-certs.
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
    command="certbot certonly --duplicate --redirect --hsts --staple-ocsp --webroot -w /etc/letsencrypt/webrootauth -d ${domain}.${tld}"
    for subdomain in "${subdomains[@]}" ; do
	command+=" -d ${subdomain}.${domain}.${tld}"
    done
    sh -c command
}

#basepath="/etc/letsencrypt/live/${domain}"
#length=${#basepath}
#totlength=$(($length+5))

installNewCerts(){
    # here we are assuming that the path ending is on the form "${domain}"."${tld}"-XXXX
    newcertdir="/etc/letsencrypt/live/"$(ls -l /etc/letsencrypt/live/ | tail -n 1 | awk ' {print $9} ')""
    ln -s -f $newcertdir/cert.pem $cert
    ln -s -f $newcertdir/chain.pem $chain
    ln -s -f $newcertdir/fullchain.pem $fullchain
    ln -s -f $newcertdir/privkey.pem $privkey
    echo "installed new certs"
}
updateDNSSec(){
    newhash=$(tlsa_rdata $fullchain 3 1 1 | grep "3 1 1" | awk ' { print $4 } ')
    sed -i "s/$oldhash/$newhash/g" "${zonefile}"
    zone=""${domain}"."${tld}""
    zonesigner.sh "${zone}" "${zonefile}"
}
restoreNginx(){
mv /tmp/nginx_enabled_conf_files/* /etc/nginx/sites-enabled/
}
updateLoolCerts(){
    cp "${cert}" "${loolcert}"
    cp "${chain}" "${loolchain}" 
    cp "${fullchain}" "${loolfullchain}"
    cp "${privkey}" "${loolprivkey}" 
    chown -R ${looluser}:${loolgroup} $loolcertspath
}
refreshServices(){
    # Sometimes software
    # to restart to load the new ones.
    for service in "${tls_services[@]}" ; do
	systemctl restart "${service}"
    done
}

main(){
    saveNginx
    installAcmeChallengeConfiguration
    getCerts
    installNewCerts
    updateDNSSec
    restoreNginx
    updateLoolCerts
    refreshServices
}
main

# Deprecated

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
