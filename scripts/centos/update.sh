#!/bin/bash
yum clean dbcache
rpm --rebuilddb
yum update -y

yum install -y db4-devel libXpm-devel libicu-devel openldap-devel freetds-devel unixODBC-devel postgresql-devel pspell-devel net-snmp-devel libtidy-devel httpd-devel bzip2-devel libc-client-devel freetype-devel gmp-devel libjpeg-devel krb5-devel libmcrypt-devel libpng-devel openssl-devel t1lib-devel mhash-devel libxml2-devel libxslt-devel
