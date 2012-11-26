-- to execute as postgres superuser
\timing off
\t on

\set dbfactory pgfactory
\set ownerfactory pgfactory
\set adminfactory pgf_admins

\c :dbfactory

-- SET client_min_messages TO WARNING;

DROP ROLE IF EXISTS "acc1";
DROP ROLE IF EXISTS "acc2";
DROP ROLE IF EXISTS "user1";
DROP ROLE IF EXISTS "user2";
DROP ROLE IF EXISTS "userN";

TRUNCATE public.roles CASCADE;

-- normal tests
SET ROLE :adminfactory;

SELECT '=====Create account acc1 & acc2=====';
SELECT * FROM create_account('acc1');
SELECT * FROM create_account('acc2');

SELECT '=====Create users user1(acc1), user2(acc2) and userN(acc1, acc2)=====';
SELECT * FROM create_user('user1', 'password1', '{acc1}');
SELECT * FROM create_user('user2', 'password2', '{acc2}');
SELECT * FROM create_user('userN', 'passwordN', '{acc1, acc2}');

SELECT '====Roles réels====';
\du

SELECT '====From API====';
SELECT * FROM public.list_users();

-- security tests

SELECT '====Table public.roles: permission denied====';
SELECT * FROM public.roles;

-- cleanup
SELECT '====Cleanup====';

SET ROLE postgres;

DROP ROLE IF EXISTS "acc1";
DROP ROLE IF EXISTS "acc2";
DROP ROLE IF EXISTS "user1";
DROP ROLE IF EXISTS "user2";
DROP ROLE IF EXISTS "userN";

TRUNCATE public.roles CASCADE;
