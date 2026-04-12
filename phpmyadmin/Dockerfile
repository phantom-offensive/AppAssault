FROM phpmyadmin/phpmyadmin:4.8.1

# CVE-2018-12613 — LFI via target parameter
# Relax open_basedir to allow LFI to reach session files and /proc
RUN sed -i 's|open_basedir = /www/:/tmp/:/etc/phpmyadmin/|open_basedir = /www/:/tmp/:/etc/phpmyadmin/:/sessions/:/proc/|' /etc/php.ini
