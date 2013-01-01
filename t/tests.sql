\unset ECHO
\i t/setup.sql

SELECT plan( 36 );

SELECT diag('====Install pgfactory-core ====');

CREATE EXTENSION pgfactory_core;

SELECT has_schema('public', 'Schema wh_nagios should not exists anymore.' );
SELECT has_table('public', 'roles', 'Schema public should contains table ''roles'' of pgfactory-core.' );
SELECT has_table('public', 'services', 'Schema public should contains table ''services'' of pgfactory-core.' );


SELECT diag('====Install wh_nagios ====');

CREATE EXTENSION hstore;
CREATE EXTENSION wh_nagios;

SELECT has_schema('wh_nagios', 'Le schéma wh_nagios doit exister.' );

SELECT diag('==== Create somes accounts ====');

-- Creates account "acc1"
SELECT set_eq(
    $$SELECT * FROM create_account('acc1')$$,
    $$VALUES (1, 'acc1')$$,
    'Account ''acc1'' should be created.'
);

-- Role "acc1" exists ?
SELECT has_role('acc1', 'Role ''acc1'' should exist.');

-- Does "acc1" exists in table roles ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE id=1$$,
    $$VALUES (1, 'acc1')$$,
    'Account ''acc1'' should exists in public.roles.'
);

-- Is "acc1" member of pgf_roles ?
SELECT is_member_of('pgf_roles', 'acc1', 'Account ''acc1'' should be a member of ''pgf_roles''.');

-- Is "acc1" a pgfactory role ?
SELECT set_eq(
    $$SELECT id, rolname, rolcanlogin FROM is_pgf_role('acc1')$$,
    $$VALUES (1, 'acc1'::name, false)$$,
    'Account ''acc1'' should be a pgfactory role.'
);

-- Is "acc1" an account ?
SELECT set_eq(
    $$SELECT is_account('acc1')$$,
    $$VALUES (true)$$,
    'Account ''acc1'' should be an account.'
);

-- Is "acc1" a user ?
SELECT set_eq(
    $$SELECT is_user('acc1')$$,
    $$VALUES (false)$$,
    'Account ''acc1'' should not be a user.'
);

-- Creates account "acc2"
SELECT set_eq(
    $$SELECT * FROM create_account('acc2')$$,
    $$VALUES (2, 'acc2')$$,
    'Account ''acc2'' should be created.'
);

-- Does "acc1" exists in table roles ?
SELECT has_role('acc2', 'Role ''acc2'' should exist.');

-- Role "acc2" exists ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE id=2$$,
    $$VALUES (2, 'acc2')$$,
    'Account ''acc2'' should exists in public.roles.'
);

-- Is "acc2" member of pgf_roles ?
SELECT is_member_of('pgf_roles', 'acc2', 'Account ''acc2'' should be a member of ''pgf_roles''.');

-- Is "acc2" a pgfactory role ?
SELECT set_eq(
    $$SELECT id, rolname, rolcanlogin FROM is_pgf_role('acc2')$$,
    $$VALUES (2, 'acc2'::name, false)$$,
    'Account ''acc2'' should be a pgfactory role.'
);

-- Is "acc2" an account ?
SELECT set_eq(
    $$SELECT is_account('acc2')$$,
    $$VALUES (true)$$,
    'Account ''acc2'' should be an account.'
);

-- Is "acc2" a user ?
SELECT set_eq(
    $$SELECT is_user('acc2')$$,
    $$VALUES ('f'::bool)$$,
    'Account ''acc2'' should not be a user.'
);



SELECT diag('==== Create somes users ====');

-- Creates user "u1"
SELECT set_eq(
    $$SELECT * FROM create_user('u1', 'pass1', '{acc1}')$$,
    $$VALUES (3, 'u1')$$,
    'Account ''u1'' should be created.'
);

-- Creates user "u2"
SELECT set_eq(
    $$SELECT * FROM create_user('u2', 'pass2', '{acc2}')$$,
    $$VALUES (4, 'u2')$$,
    'Account ''u2'' should be created.'
);

-- Creates user "u3"
SELECT set_eq(
    $$SELECT * FROM create_user('u3', 'pass3', '{acc1,acc2}')$$,
    $$VALUES (5, 'u3')$$,
    'Account ''u3'' should be created.'
);


SELECT diag('==== Drop user ====');

-- Drop user "u1"
SELECT set_eq(
    $$SELECT * FROM drop_user('u1')$$,
    $$VALUES (3, 'u1')$$,
    'Account ''u1'' should be deleted.'
);

SELECT diag('==== Drop accounts ====');

-- Drop "acc1"
SELECT set_eq(
    $$SELECT * FROM drop_account('acc1')$$,
    $$VALUES ('acc1')$$,
    'Account ''acc1'' should be deleted.'
);

-- "acc1" role should not exists anymore
SELECT hasnt_role('acc1', 'Role ''acc1'' should not exist.');

-- test role existance-related functions on "acc1"
-- They all should returns NULL
SELECT set_eq(
    $$SELECT id FROM is_pgf_role('acc1')$$,
    $$VALUES (NULL::bigint)$$,
    'Account ''acc1'' should not be a pgfactory role.'
);

SELECT set_eq(
    $$SELECT is_account('acc1')$$,
    $$VALUES (NULL::boolean)$$,
    'is_account should not return the ''acc1'' account.'
);

SELECT set_eq(
    $$SELECT is_user('acc1')$$,
    $$VALUES (NULL::boolean)$$,
    'is_user should not return the ''acc1'' account.'
);

-- Drop account "acc2"
SELECT set_eq(
    $$SELECT * FROM drop_account('acc2')$$,
    $$VALUES ('acc2'), ('u2'), ('u3')$$,
    'Account ''acc2'' should be deleted.'
);

SELECT hasnt_role('acc2', 'Role ''acc2'' should not exist.');

SELECT diag('==== Drop wh_nagios ====');

DROP EXTENSION wh_nagios;
SELECT hasnt_table('wh_nagios', 'hub', 'Table ''hub'' of schema wh_nagios should not exists anymore.' );

DROP SCHEMA wh_nagios;
SELECT hasnt_schema('wh_nagios', 'Schema wh_nagios should not exists anymore.' );

SELECT diag('==== Drop pgfactory_core ====');

DROP EXTENSION pgfactory_core;

SELECT hasnt_table('public', 'roles', 'Schema public should not contains table ''roles'' of pgfactory-core.' );
SELECT hasnt_table('public', 'services', 'Schema public should not contains table ''services'' of pgfactory-core.' );

DROP EXTENSION hstore;

DROP ROLE pgfactory;
DROP ROLE pgf_admins;
DROP ROLE pgf_roles;

SELECT hasnt_role('pgfactory', 'Role ''pgfactory'' should not exists anymore.');
SELECT hasnt_role('pgf_admins', 'Role ''pgf_admins'' should not exists anymore.');
SELECT hasnt_role('pgf_roles', 'Role ''pgf_roles'' should not exists anymore.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
