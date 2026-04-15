FROM joomla:4.2.7-apache

COPY auto-install.sh /usr/local/bin/auto-install.sh
RUN chmod +x /usr/local/bin/auto-install.sh

ENTRYPOINT ["/usr/local/bin/auto-install.sh"]
CMD ["apache2-foreground"]
