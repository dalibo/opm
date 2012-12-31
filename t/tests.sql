-- to execute as postgres superuser
\timing off
\t on

\set admincluster postgres

\set dbfactory pgfactory
\set ownerfactory pgfactory
\set adminfactory pgf_admins
\set userfactory user1

DROP DATABASE IF EXISTS :dbfactory;
CREATE DATABASE :dbfactory;

\c :dbfactory

-- SET client_min_messages TO WARNING;

/* manual cleanup */
DROP ROLE IF EXISTS "acc1";
DROP ROLE IF EXISTS "acc2";
DROP ROLE IF EXISTS "user1";
DROP ROLE IF EXISTS "user2";
DROP ROLE IF EXISTS "user3";
DROP ROLE IF EXISTS "userN";
DROP ROLE IF EXISTS pgf_roles;
DROP ROLE IF EXISTS pgf_admins;
DROP ROLE IF EXISTS pgfactory;


TRUNCATE public.roles CASCADE;

SELECT '====Install pgfactory and wh_nagios====';
CREATE EXTENSION pgfactory_core;
CREATE EXTENSION hstore;
CREATE EXTENSION wh_nagios;

SELECT '====Create some fake services====';
INSERT INTO services (hostname, warehouse, service) VALUES ('barbapapa1', 'wh_nagios', 'Service1');
INSERT INTO services (hostname, warehouse, service) VALUES ('barbapapa2', 'wh_nagios', 'Service1');
INSERT INTO services (hostname, warehouse, service) VALUES ('barbapapa2', 'wh_nagios', 'Service2');

-- normal tests
SET ROLE :adminfactory;

SELECT '=====Create account acc1 & acc2=====';
SELECT * FROM create_account('acc1');
SELECT * FROM create_account('acc2');

SELECT '=====Create users user1(acc1), user2(acc2) and userN(acc1, acc2)=====';
SELECT * FROM create_user('user1', 'password1', '{acc1}');
SELECT * FROM create_user('user3', 'password1', '{acc1}');
SELECT * FROM create_user('user2', 'password2', '{acc2}');
SELECT * FROM create_user('userN', 'passwordN', '{acc1, acc2}');

SELECT '====Grant user1 to access service id=1====';
SELECT * FROM grant_service(1, 'user1');

SELECT '====Roles réels====';
\du

SELECT '====From API====';
SELECT * FROM public.list_users();

-- security tests

SELECT '====Table public.roles: permission denied====';
SELECT * FROM public.roles;

SELECT '====Table public.services: permission denied====';
SELECT * FROM public.services;

SELECT '====What admin sees====';
SELECT * FROM public.list_services();

\c :dbfactory :userfactory;

SELECT '====What user1 sees====';
SELECT * FROM public.list_services();

SELECT * FROM wh_nagios.hub;

--SET ROLE :adminfactory;
\c :dbfactory :admincluster;

-- cleanup
SELECT '====Cleanup====';

SELECT drop_account('acc1');
SELECT drop_account('acc2');

SET ROLE :admincluster;

DROP EXTENSION wh_nagios;
DROP EXTENSION pgfactory_core;
