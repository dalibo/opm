\unset ECHO
\i t/setup.sql

SELECT plan( 50 );

SELECT diag('==== Setup environnement ====');

CREATE EXTENSION pgfactory_core;

SELECT diag('==== Create somes accounts ====');

-- Creates account "acc1"
SELECT set_eq(
    $$SELECT * FROM create_account('acc1')$$,
    $$VALUES (1, 'acc1')$$,
    'Account "acc1" should be created.'
);

-- Role "acc1" exists ?
SELECT has_role('acc1', 'Role "acc1" should exist.');

-- Does "acc1" exists in table roles ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE id=1$$,
    $$VALUES (1, 'acc1')$$,
    'Account "acc1" should exists in public.roles.'
);

-- Is "acc1" member of pgf_roles ?
SELECT is_member_of('pgf_roles', 'acc1', 'Account "acc1" should be a member of "pgf_roles".');

-- Is "acc1" a pgfactory role ?
SELECT set_eq(
    $$SELECT id, rolname, rolcanlogin FROM is_pgf_role('acc1')$$,
    $$VALUES (1, 'acc1'::name, false)$$,
    'Account "acc1" should be a pgfactory role.'
);

-- Is "acc1" an account ?
SELECT set_eq(
    $$SELECT is_account('acc1')$$,
    $$VALUES (true)$$,
    'Account "acc1" should be an account.'
);

-- Is "acc1" a user ?
SELECT set_eq(
    $$SELECT is_user('acc1')$$,
    $$VALUES (false)$$,
    'Account "acc1" should not be a user.'
);

-- Creates account "acc2"
SELECT set_eq(
    $$SELECT * FROM create_account('acc2')$$,
    $$VALUES (2, 'acc2')$$,
    'Account "acc2" should be created.'
);

-- Does "acc1" exists in table roles ?
SELECT has_role('acc2', 'Role "acc2" should exist.');

-- Role "acc2" exists ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE id=2$$,
    $$VALUES (2, 'acc2')$$,
    'Account "acc2" should exists in public.roles.'
);

-- Is "acc2" member of pgf_roles ?
SELECT is_member_of('pgf_roles', 'acc2', 'Account "acc2" should be a member of "pgf_roles".');

-- Is "acc2" a pgfactory role ?
SELECT set_eq(
    $$SELECT id, rolname, rolcanlogin FROM is_pgf_role('acc2')$$,
    $$VALUES (2, 'acc2'::name, false)$$,
    'Account "acc2" should be a pgfactory role.'
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



SELECT diag('==== Create somes users ====');

-- Creates user "u1" in acc1
SELECT set_eq(
    $$SELECT * FROM create_user('u1', 'pass1', '{acc1}')$$,
    $$VALUES (3, 'u1')$$,
    'User "u1" in account "acc1" should be created.'
);

-- Creates user "u2"
SELECT set_eq(
    $$SELECT * FROM create_user('u2', 'pass2', '{acc2}')$$,
    $$VALUES (4, 'u2')$$,
    'User "u2" in account "acc2" should be created.'
);

-- Creates user "u3"
SELECT set_eq(
    $$SELECT * FROM create_user('u3', 'pass3', '{acc1,acc2}')$$,
    $$VALUES (5, 'u3')$$,
    'User "u3" in accounts "acc1", acc2" should be created.'
);

-- Creates user "u4"
SELECT set_eq(
    $$SELECT * FROM create_user('u4', 'pass4', '{acc1,acc2}')$$,
    $$VALUES (6, 'u4')$$,
    'User "u4" in accounts "acc1, acc2" should be created.'
);

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (3, 'acc1', 'u1'),
        (5, 'acc1', 'u3'),
        (6, 'acc1', 'u4'),
        (4, 'acc2', 'u2'),
        (5, 'acc2', 'u3'),
        (6, 'acc2', 'u4')$$,
    'Should list all the users.'
);

-- Creates user "admin1"
SELECT set_eq(
    $$SELECT * FROM create_user('admin1', 'passadmin1', '{pgf_admins}')$$,
    $$VALUES (7, 'admin1')$$,
    'User "admin1" in account "admin1" should be created.'
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

SELECT set_eq(
    $$SELECT * FROM list_users() WHERE rolname = 'admin1'$$,
    $$VALUES (7, 'pgf_admins', 'admin1')$$,
    'Should only list admin admin1.'
);

SELECT set_eq(
    $$SELECT * FROM list_users('acc1')$$,
    $$VALUES (3, 'acc1', 'u1'),
        (5, 'acc1', 'u3'),
        (6, 'acc1', 'u4')$$,
    'Should list users of account "acc1".'
);

-- We cannot test this call for a simple user yet :/

SELECT diag('==== Drop admin and user ====');

-- Drop admin "admin1"
SELECT set_eq(
    $$SELECT * FROM drop_user('admin1')$$,
    $$VALUES (7, 'admin1')$$,
    'User "admin1" should be deleted using drop_user.'
);

SELECT hasnt_role('admin1', 'Role "admin1" should not exist anymore.');

SELECT set_hasnt(
    $$SELECT * FROM list_users()$$,
    $$VALUES (7, 'pgf_admins', 'admin1')$$,
    'User "admin1" is not listed by list_users() anymore.'
);

SELECT set_hasnt(
    $$SELECT id, rolname FROM public.roles WHERE rolname = 'admin1'$$,
    $$VALUES (7, 'admin1')$$,
    'User "admin1" is not in table "publi.roles" anymore.'
);

SELECT diag('=== User u1 belongs to acc1 only ===');

-- Drop user "u1"
SELECT set_eq(
    $$SELECT * FROM drop_user('u1')$$,
    $$VALUES (3, 'u1')$$,
    'User "u1" deleted using drop_user.'
);

SELECT hasnt_role('u1', 'Role "u1" does not exist anymore.');

SELECT set_hasnt(
    $$SELECT * FROM list_users()$$,
    $$VALUES (3, 'acc1', 'u1')$$,
    'User "u1" should not be listed by list_users() anymore.'
);

SELECT set_hasnt(
    $$SELECT id, rolname FROM public.roles WHERE rolname = 'u1'$$,
    $$VALUES (3, 'u1')$$,
    'User "u1" is not in table "publi.roles" anymore.'
);

SELECT diag('=== User u4 belongs to acc1 and acc2 ===');

-- Drop user "u4"
SELECT set_eq(
    $$SELECT * FROM drop_user('u4')$$,
    $$VALUES (6, 'u4')$$,
    'User "u4" deleted unsing drop_user.'
);

SELECT hasnt_role('u1', 'Role "u4" does not exist anymore.');

SELECT set_hasnt(
    $$SELECT * FROM list_users()$$,
    $$VALUES (6, 'acc1', 'u4'),
        (6, 'acc2', 'u4')$$,
    'User "u4" not listed by list_users anymore.'
);

SELECT set_hasnt(
    $$SELECT id, rolname FROM public.roles WHERE rolname = 'u4'$$,
    $$VALUES (6, 'u4')$$,
    'User "u4" is not in table "publi.roles" anymore.'
);

SELECT diag('==== Drop accounts ====');

SELECT diag('=== acc2 has two accounts: u2 only member of acc2 and u4 member of acc1 as well ===');

-- Drop "acc2"
SELECT set_eq(
    $$SELECT * FROM drop_account('acc2')$$,
    $$VALUES (4, 'u2'), (2, 'acc2')$$,
    'Account "acc2" should be deleted by drop_account.'
);

-- "acc1" role should not exists anymore
SELECT hasnt_role('u2', 'Role "u2" should not exist.');
SELECT hasnt_role('acc2', 'Role "acc2" should not exist.');
SELECT has_role('u3', 'Role "u3" should still exist.');

SELECT set_eq(
    $$SELECT * FROM list_users()$$,
    $$VALUES (5, 'acc1', 'u3')$$,
    'List_users should only return "u3".'
);

-- test role existance-related functions on "acc2"
-- They all should returns NULL
SELECT set_eq(
    $$SELECT id FROM is_pgf_role('acc2')$$,
    $$VALUES (NULL::bigint)$$,
    'Account "acc2" should not be a pgfactory role.'
);

SELECT set_eq(
    $$SELECT is_account('acc2')$$,
    $$VALUES (NULL::boolean)$$,
    'is_account should not return the "acc2" account.'
);

SELECT set_eq(
    $$SELECT is_user('acc2')$$,
    $$VALUES (NULL::boolean)$$,
    'is_user should not return the "acc2" account.'
);

SELECT set_eq(
    $$SELECT rolname FROM public.roles WHERE rolname = 'u3'$$,
    $$VALUES ('u3')$$,
    'User "u3" should still be listed in public.roles.'
);

-- Drop account "acc1"
SELECT set_eq(
    $$SELECT * FROM drop_account('acc1')$$,
    $$VALUES (5, 'u3'), (1, 'acc1')$$,
    'Account "acc1" should be deleted.'
);

SELECT hasnt_role('acc2', 'Role "acc2" should not exist.');

SELECT set_eq(
    $$SELECT count(*) FROM list_users()$$,
    $$VALUES (0::bigint)$$,
    'Function list_users() list nothing.'
);

SELECT set_eq(
    $$SELECT count(*) FROM public.roles$$,
    $$VALUES (0::bigint)$$,
    'Table "publi.roles" empty.'
);

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
