pgFactory
=========

Overview
--------


Prerequisites
-------------

The versions showed have been tested, it may work with older versions

* Perl 5.10
* Mojolicious 2.98
* Mojolicious::Plugin::I18N 
* PostgreSQL 9.2
* A CGI/Perl webserver

Install
-------

A PostgreSQL database with a a superuser. Create pgfactory_core and
extensions needed (for instance wh_nagios);


Install other prerequisites: Mojolicious is available on CPAN and
sometimes packages, for example the package in Debian is
`libmojolicious-perl`

Copy `pgfactory.conf-dist` to `pgfactory.conf` and edit it.

To quickly run the UI, do not activate `rewrite` in the config (this
is Apache rewrite rules when run as a CGI) and start the morbo
webserver inside the source directory:

	morbo script/pg_factory

It will output what is printed to STDOUT/STDOUT in the code in the
term. The web pages are available on http://localhost:3000/

To run the UI with Apache, here is an example using CGI:

	<VirtualHost *:80>
		ServerAdmin webmaster@example.com
		ServerName pgfactory.example.com
		DocumentRoot /var/www/pg_factory/public/
	
		<Directory /var/www/pg_factory/public/>
			AllowOverride None
			Order allow,deny
			allow from all
			IndexIgnore *
	
			RewriteEngine On
			RewriteBase /
			RewriteRule ^$ pg_factory.cgi [L]
			RewriteCond %{REQUEST_FILENAME} !-f
			RewriteCond %{REQUEST_FILENAME} !-d
			RewriteRule ^(.*)$ pg_factory.cgi/$1 [L]
		</Directory>
	
		ScriptAlias /pg_factory.cgi /var/www/pg_factory/script/pg_factory
		<Directory /var/www/pg_factory/script/>
			AddHandler cgi-script .cgi
			Options +ExecCGI
			AllowOverride None
			Order allow,deny
			allow from all
			SetEnv MOJO_MODE production
			SetEnv MOJO_MAX_MESSAGE_SIZE 4294967296
		</Directory>
	
		ErrorLog ${APACHE_LOG_DIR}/pg_factory_error.log
		# Possible values include: debug, info, notice, warn, error, crit,
		# alert, emerg.
		LogLevel warn
	
		CustomLog ${APACHE_LOG_DIR}/pg_factory_access.log combined
	</VirtualHost>

