#!/bin/bash
yum -y install httpd
systemctl enable httpd
systemctl start httpd
curl "https://raw.githubusercontent.com/fabianschmauder/cgn-aws-22-3-friday-challanges/main/22-09-30_S3-CLI-Actions/index.html" > /var/www/html/index.html