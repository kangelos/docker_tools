FROM centos:centos6
EXPOSE 80

RUN yum -y update && \
	yum -y install epel-release 

RUN yum -y install mod_php

COPY index.php /var/www/html/index.php

COPY dockerstart.bash /root/start.sh
#ENTRYPOINT /root/start.sh

ENTRYPOINT ["/usr/sbin/apachectl", "-D", "FOREGROUND"]
