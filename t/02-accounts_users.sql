-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2014: Open PostgreSQL Monitoring Development Group

\unset ECHO
\i t/setup.sql

SELECT plan(104);

SELECT diag(E'\n==== Setup environnement ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION opm_core$$,
    'Create extension "opm_core"'
);

SELECT diag(E'\n==== Create somes accounts ====\n');

-- Creates account "acc1"
SELECT set_eq(
    $$SELECT * FROM create_account('acc1')$$,
    $$VALUES (2, 'acc1')$$,
    'Account "acc1" should be created.'
);

-- Role "acc1" exists ?
SELECT has_role('acc1', 'Role "acc1" should exist.');

-- Does "acc1" exists in table roles ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE rolname='acc1'$$,
    $$VALUES (2, 'acc1')$$,
    'Account "acc1" exists in public.roles.'
);

-- Is "acc1" member of opm_roles ?
SELECT is_member_of(
    'opm_roles',
    'acc1',
    'Account "acc1" should be a member of "opm_roles".'
);

-- Is "acc1" an opm role ?
SELECT set_eq(
    $$SELECT * FROM is_opm_role('acc1')$$,
    $$VALUES (true)$$,
    'Account "acc1" is an OPM role.'
);

-- Is "acc1" an account ?
SELECT set_eq(
    $$SELECT is_account('acc1')$$,
    $$VALUES (true)$$,
    'Account "acc1" is an account.'
);

-- Is "acc1" a user ?
SELECT set_eq(
    $$SELECT is_user('acc1')$$,
    $$VALUES (false)$$,
    'Account "acc1" is not a user.'
);

-- Creates account "acc2"
SELECT set_eq(
    $$SELECT * FROM create_account('acc2')$$,
    $$VALUES (3, 'acc2')$$,
    'Account "acc2" is created.'
);

-- Does "acc1" exists in table roles ?
SELECT has_role('acc2', 'Role "acc2" should exist.');

-- Role "acc2" exists ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE rolname='acc2'$$,
    $$VALUES (3, 'acc2')$$,
    'Account "acc2" should exists in public.roles.'
);

-- Is "acc2" member of opm_roles ?
SELECT is_member_of('opm_roles', 'acc2', 'Account "acc2" should be a member of "opm_roles".');

-- Is "acc2" an opm role ?
SELECT set_eq(
    $$SELECT * FROM is_opm_role('acc2')$$,
    $$VALUES (true)$$,
    'Account "acc2" is an OPM role.'
);

-- Is "acc2" an account ?
SELECT set_eq(
    $$SELECT is_account('acc2')$$,
    $$VALUES (true)$$,
    'Account "acc2" should be an account.'
);

-- Is "acc2" a user ?
SELECT set_eq(
    $$SELECT is_user('acc2')$$,
    $$VALUES ('f'::bool)$$,
    'Account "acc2" should not be a user.'
);

SELECT diag(E'\n==== Create somes users ====\n');

-- Creates user "u1" in acc1
SELECT set_eq(
    $$SELECT * FROM create_user('u1', 'pass1', '{acc1}')$$,
    $$VALUES (4, 'u1')$$,
    'User "u1" in account "acc1" should be created.'
);

-- Creates user "u2"
SELECT set_eq(
    $$SELECT * FROM create_user('u2', 'pass2', '{acc2}')$$,
    $$VALUES (5, 'u2')$$,
    'User "u2" in account "acc2" should be created.'
);

-- Creates user "u3"
SELECT set_eq(
    $$SELECT * FROM create_user('u3', 'pass3', '{acc1,acc2}')$$,
    $$VALUES (6, 'u3')$$,
    'User "u3" in accounts "acc1", acc2" should be created.'
);

-- Creates user "u4"
SELECT set_eq(
    $$SELECT * FROM create_user('u4', 'pass4', '{acc1,acc2}')$$,
    $$VALUES (7, 'u4')$$,
    'User "u4" in accounts "acc1, acc2" should be created.'
);

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (4, 'acc1', 'u1'),
        (6, 'acc1', 'u3'),
        (7, 'acc1', 'u4'),
        (5, 'acc2', 'u2'),
        (6, 'acc2', 'u3'),
        (7, 'acc2', 'u4')$$,
    'List all the users.'
);

-- Creates user "admin1"
SELECT set_eq(
    $$SELECT * FROM create_user('admin1', 'passadmin1', '{opm_admins}')$$,
    $$VALUES (8, 'admin1')$$,
    'User "admin1" in account "opm_admins" should be created.'
);

SELECT set_eq(
    $$SELECT * FROM is_admin('admin1')$$,
    $$VALUES (true)$$,
    'User "admin1" should be admin.'
);

SELECT set_eq(
    $$SELECT * FROM is_admin('u1')$$,
    $$VALUES (false)$$,
    'User "u1" should not be admin.'
);

SELECT set_eq(
    $$SELECT * FROM is_admin('not_a_user')$$,
    $$VALUES (NULL::boolean)$$,
    'User "not_a_user" should not exist.'
);

SELECT diag(E'\n==== Grant and revoke accounts ====\n');

SELECT set_eq(
    $$SELECT * FROM revoke_account('u1','acc1')$$,
    $$VALUES (FALSE)$$,
    'Account "acc1" shoud not be removed from user "u1": only 1 account.'
);

SELECT set_eq(
    $$SELECT * FROM grant_account('u1','acc2')$$,
    $$VALUES (TRUE)$$,
    'Account "acc2" shoud be added to user "u1".'
);

SELECT set_eq(
    $$SELECT * FROM revoke_account('u1','acc2')$$,
    $$VALUES (TRUE)$$,
    'Account "acc2" shoud be removed from user "u1".'
);

SELECT set_eq(
    $$SELECT * FROM revoke_account('u1','not_an_account')$$,
    $$VALUES (NULL::boolean)$$,
    'Function revoke_account should notice "not_an_account" does not exist.'
);

SELECT set_eq(
    $$SELECT * FROM revoke_account('not_a_user','acc2')$$,
    $$VALUES (NULL::boolean)$$,
    'Function revoke_account should notice "not_a_user" does not exist.'
);

SELECT set_eq(
    $$SELECT * FROM grant_account('u1','not_an_account')$$,
    $$VALUES (NULL::boolean)$$,
    'Function grant_account should notice "not_an_account" does not exist.'
);

SELECT set_eq(
    $$SELECT * FROM grant_account('not_a_user','acc2')$$,
    $$VALUES (NULL::boolean)$$,
    'Function grant_account should notice "not_a_user" does not exist.'
);

SELECT set_eq(
    $$SELECT * FROM grant_account('u2','opm_admins')$$,
    $$VALUES (TRUE)$$,
    '"u2" should be added to "opm_admins".'
);

SELECT set_eq(
    $$SELECT pg_has_role('u2','opm_admins','MEMBER WITH ADMIN OPTION')$$,
    $$VALUES (TRUE)$$,
    '"u2" should be able to add new admins.'
);

SELECT set_eq(
    $$SELECT * FROM revoke_account('u2','opm_admins')$$,
    $$VALUES (TRUE)$$,
    '"u2" should be removed from "opm_admins".'
);

SELECT set_eq(
    $$SELECT pg_has_role('u2','opm_admins','MEMBER')$$,
    $$VALUES (FALSE)$$,
    '"u2" should not be admin anymore.'
);

SELECT diag(E'\n==== functions list_users and list_accounts ====\n');

SELECT set_eq(
    $$SELECT * FROM list_users() WHERE rolname = 'admin1'$$,
    $$VALUES (8, 'opm_admins', 'admin1')$$,
    'Only list admin admin1.'
);

SELECT set_eq(
    $$SELECT * FROM list_users('acc1')$$,
    $$VALUES (4, 'acc1', 'u1'),
        (6, 'acc1', 'u3'),
        (7, 'acc1', 'u4')$$,
    'Only list users of account "acc1".'
);

-- Need to allow u3 to create temp tables for pgtap
SELECT lives_ok(
    format('GRANT TEMPORARY ON DATABASE %I TO u3', current_database()),
    'Grant TEMPORARY on current db to u3'
);

-- User should only see account/users member of their own account
-- u3 is in both accounts
SELECT lives_ok('SET SESSION AUTHORIZATION u3','Set session authorization to u3');
SELECT lives_ok('SET ROLE u3','Set role u3');

SELECT results_eq(
    $$SELECT current_user, session_user$$,
    $$VALUES ('u3'::name, 'u3'::name)$$,
    'Set session authorization to role u3.'
);

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (4, 'acc1', 'u1'),
        (6, 'acc1', 'u3'),
        (7, 'acc1', 'u4'),
        (5, 'acc2', 'u2'),
        (6, 'acc2', 'u3'),
        (7, 'acc2', 'u4')$$,
    'Only list users in the same account than u3.'
);

SELECT set_eq(
    $$SELECT * FROM list_accounts()$$,
    $$VALUES (2, 'acc1'),
        (3, 'acc2')$$,
    'Only list accounts of "u3".'
);

SELECT lives_ok(
    'RESET SESSION AUTHORIZATION',
    'Reset session authorization'
);

-- Revoke from u3 create temp tables
SELECT lives_ok(
    format('REVOKE TEMPORARY ON DATABASE %I FROM u3', current_database()),
    'Revoke TEMPORARY on current db from u3'
);

SELECT results_ne(
    $$SELECT current_user, session_user$$,
    $$VALUES ('u3'::name, 'u3'::name)$$,
    'Reset session authorization.'
);

--Need to allow u3 to create temp tables for pgtap
SELECT lives_ok(
    format('GRANT TEMPORARY ON DATABASE %I TO u1',current_database()),
    'Grant TEMPORARY on current db to u1'
);

-- User should only see account/users member of their own account
-- u1 is only in acc1.
SELECT lives_ok(
    'SET SESSION AUTHORIZATION u1',
    'Set session authorization u1'
);
SELECT lives_ok('SET ROLE u1','Set role u1');

SELECT results_eq(
    $$SELECT current_user, session_user$$,
    $$VALUES ('u1'::name, 'u1'::name)$$,
    'Set session authorization to role u1.'
);

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (4, 'acc1', 'u1'),
        (6, 'acc1', 'u3'),
        (7, 'acc1', 'u4')$$,
    'Only list users in the same account than u1.'
);

SELECT set_eq(
    $$SELECT * FROM list_accounts()$$,
    $$VALUES (2, 'acc1')$$,
    'Only list accounts of "u1".'
);

SELECT lives_ok(
    'RESET SESSION AUTHORIZATION',
    'Reset session authorization'
);
-- Revoke from u1 create temp tables
SELECT lives_ok(
    format('REVOKE TEMPORARY ON DATABASE %I FROM u1',current_database()),
    'Revoke TEMPORARY on current db from u1'
);

SELECT results_ne(
    $$SELECT current_user, session_user$$,
    $$VALUES ('u1'::name, 'u1'::name)$$,
    'Reset session authorization.'
);

-- User should only see account/users member of their own account
-- u1 is only in acc1.
SELECT lives_ok(
    'SET SESSION AUTHORIZATION admin1',
    'Set session authorization admin1'
);
SELECT lives_ok('SET ROLE admin1','Set role admin1');

SELECT results_eq(
    $$SELECT current_user, session_user$$,
    $$VALUES ('admin1'::name, 'admin1'::name)$$,
    'Set session authorization to role admin1.'
);

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (4, 'acc1', 'u1'),
        (6, 'acc1', 'u3'),
        (7, 'acc1', 'u4'),
        (5, 'acc2', 'u2'),
        (6, 'acc2', 'u3'),
        (7, 'acc2', 'u4'),
        (8, 'opm_admins', 'admin1')$$,
    'Admin can see all users.'
);

SELECT set_eq(
    $$SELECT * FROM list_accounts()$$,
    $$VALUES (1, 'opm_admins'),
        (2, 'acc1'),
        (3, 'acc2')$$,
    'Admin can see all accounts.'
);

SELECT lives_ok('RESET SESSION AUTHORIZATION','Reset session authorization');

SELECT results_ne(
    $$SELECT current_user, session_user$$,
    $$VALUES ('admin1'::name, 'admin1'::name)$$,
    'Reset session authorization.'
);

SELECT diag(E'\n==== functions list_servers, and grant_server and revoke_server ====\n');

SELECT set_eq(
    $$SELECT COUNT(*) FROM public.list_servers()$$,
    $$VALUES (0)$$,
    'Should not have any server present.'
);

SELECT lives_ok($$INSERT INTO public.servers (hostname) VALUES
    ('hostname1'),('hostname2')
    $$,
    'Insert two servers'
);

SELECT set_eq(
    $$SELECT * FROM public.list_servers()$$,
    $$VALUES (1,'hostname1',NULL),
    (2,'hostname2',NULL)$$,
    'Admin can see all servers.'
);

SELECT set_eq(
    $$SELECT * FROM public.grant_server(1,'u1')$$,
    $$VALUES (true)$$,
    'Grant server "hostname1" to "u1".'
);

-- Need to allow u1 to create temp tables for pgtap
SELECT lives_ok(
    format('GRANT TEMPORARY ON DATABASE %I TO u1', current_database()),
    'Grant TEMPORARY on current db to u1'
);

SELECT lives_ok(
    'SET SESSION AUTHORIZATION u1',
    'Set session authorization u1'
);
SELECT lives_ok('SET ROLE u1','Set role u1');

SELECT set_eq(
    $$SELECT * FROM public.list_servers()$$,
    $$VALUES (1,'hostname1','u1')$$,
    '"u1" should only see server "hostname1".'
);

SELECT lives_ok(
    'RESET SESSION AUTHORIZATION',
    'Reset session authorization'
);
SELECT lives_ok('RESET ROLE','Reset role');

SELECT set_eq(
    $$SELECT * FROM public.revoke_server(1,'u1')$$,
    $$VALUES (true)$$,
    'Revoke server "hostname1" from "u1".'
);

--Revoke from u1 create temp tables
SELECT lives_ok(
    format('REVOKE TEMPORARY ON DATABASE %I FROM u1', current_database()),
    'Revoke TEMPORARY on current db from u1'
);

SELECT diag(E'\n==== Update user ====\n');

SELECT set_eq(
    $$SELECT passwd FROM pg_catalog.pg_shadow WHERE usename = 'u1'$$,
    $$SELECT 'md5' || md5('pass1u1')$$,
    'Password for user "u1" should be "pass1".'
);

SELECT set_eq(
    $$SELECT * FROM public.update_user('donotexists','somepassword')$$,
    $$VALUES (false)$$,
    'Changing password of an unexisting user should return false.'
);

SELECT set_eq(
    $$SELECT * FROM public.update_user('u1','newpassword')$$,
    $$VALUES (true)$$,
    'Changing password of user "u1" should return true.'
);

SELECT set_eq(
    $$SELECT passwd FROM pg_catalog.pg_shadow WHERE usename = 'u1'$$,
    $$SELECT 'md5' || md5('newpasswordu1')$$,
    'Password for user "u1" should be "newpassword".'
);

SELECT diag(E'\n==== Drop admin and user ====\n');

-- Drop admin "admin1"
SELECT set_eq(
    $$SELECT * FROM drop_user('admin1')$$,
    $$VALUES (8, 'admin1')$$,
    'User "admin1" is deleted using drop_user.'
);

SELECT hasnt_role('admin1', 'Role "admin1" should not exist anymore.');

SELECT set_hasnt(
    $$SELECT * FROM list_users()$$,
    $$VALUES (8, 'opm_admins', 'admin1')$$,
    'User "admin1" is not listed by list_users() anymore.'
);

SELECT set_hasnt(
    $$SELECT id, rolname FROM public.roles WHERE rolname = 'admin1'$$,
    $$VALUES (8, 'admin1')$$,
    'User "admin1" is not in table "public.roles" anymore.'
);

-- User u1 belongs to acc1 only

-- Drop user "u1"
SELECT set_eq(
    $$SELECT * FROM drop_user('u1')$$,
    $$VALUES (4, 'u1')$$,
    'User "u1" deleted using drop_user.'
);

SELECT hasnt_role('u1', 'Role "u1" does not exist anymore.');

SELECT set_hasnt(
    $$SELECT * FROM list_users()$$,
    $$VALUES (4, 'acc1', 'u1')$$,
    'User "u1" should not be listed by list_users() anymore.'
);

SELECT set_hasnt(
    $$SELECT id, rolname FROM public.roles WHERE rolname = 'u1'$$,
    $$VALUES (4, 'u1')$$,
    'User "u1" is not in table "public.roles" anymore.'
);

-- User u4 belongs to acc1 and acc2

-- Drop user "u4"
SELECT set_eq(
    $$SELECT * FROM drop_user('u4')$$,
    $$VALUES (7, 'u4')$$,
    'User "u4" deleted unsing drop_user.'
);

SELECT hasnt_role('u1', 'Role "u4" does not exist anymore.');

SELECT set_hasnt(
    $$SELECT * FROM list_users()$$,
    $$VALUES (7, 'acc1', 'u4'),
        (7, 'acc2', 'u4')$$,
    'User "u4" not listed by list_users anymore.'
);

SELECT set_hasnt(
    $$SELECT id, rolname FROM public.roles WHERE rolname = 'u4'$$,
    $$VALUES (7, 'u4')$$,
    'User "u4" is not in table "public.roles" anymore.'
);


SELECT diag(E'\n==== Drop accounts ====\n');

SELECT diag(E'User "acc2" has two accounts: u2 only member of acc2 and u4 member of acc1 as well ===\n');

-- Drop "acc2"
SELECT set_eq(
    $$SELECT * FROM drop_account('acc2')$$,
    $$VALUES (5, 'u2'), (3, 'acc2')$$,
    'Account "acc2" should be deleted by drop_account.'
);

-- "acc1" role should not exists anymore
SELECT hasnt_role('u2', 'Role "u2" should not exist.');
SELECT hasnt_role('acc2', 'Role "acc2" should not exist.');
SELECT has_role('u3', 'Role "u3" should still exist.');

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (6, 'acc1', 'u3')$$,
    'List_users should only return "u3".'
);

-- test role existance-related functions on "acc2"
-- They all should returns NULL
SELECT set_eq(
    $$SELECT * FROM is_opm_role('acc2')$$,
    $$VALUES ('f'::boolean)$$,
    'Account "acc2" is not an OPM role anymore.'
);

SELECT set_eq(
    $$SELECT is_account('acc2')$$,
    $$VALUES ('f'::boolean)$$,
    'is_account do not return the "acc2" account.'
);

SELECT set_eq(
    $$SELECT is_user('acc2')$$,
    $$VALUES ('f'::boolean)$$,
    'is_user do not return the "acc2" account.'
);

SELECT set_eq(
    $$SELECT rolname FROM public.roles WHERE rolname = 'u3'$$,
    $$VALUES ('u3')$$,
    'User "u3" is still listed in public.roles.'
);

-- Drop account "acc1"
SELECT set_eq(
    $$SELECT * FROM drop_account('acc1')$$,
    $$VALUES (6, 'u3'), (2, 'acc1')$$,
    'Account "acc1" should be deleted.'
);

SELECT hasnt_role('acc2', 'Role "acc2" should not exist.');

SELECT set_eq(
    $$SELECT count(*) FROM list_users()$$,
    $$VALUES (0::bigint)$$,
    'Function list_users() list nothing.'
);

-- Dropping opm_admin is not allowed.

SELECT throws_matching(
    $$SELECT * FROM drop_account('opm_admins')$$,
    'can not be deleted!',
    'Account opm_admins can not be deleted.'
);

SELECT set_eq(
    $$SELECT count(*) FROM public.roles$$,
    $$VALUES (1::bigint)$$,
    'Table "public.roles" contains one account.'
);

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
