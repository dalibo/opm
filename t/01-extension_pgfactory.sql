\unset ECHO
\i t/setup.sql

SELECT plan(55);

SELECT diag(E'\n==== Install pgfactory-core ====\n');

SELECT has_schema('public', 'Schema public exists.' );

SELECT lives_ok(
    $$CREATE EXTENSION pgfactory_core$$,
    'Create extension "pgfactory_core"');

SELECT has_extension('pgfactory_core', 'Extension "pgfactory_core" is installed.');

SELECT has_role('pgfactory', 'Role "pgfactory" exists.');
SELECT has_role('pgf_admins', 'Role "pgf_admins" exists.');
SELECT has_role('pgf_roles', 'Role "pgf_roles" exists.');
SELECT is_member_of('pgfactory', 'pgf_admins', 'Role "pgf_admins" is member of "pgfactory".');
SELECT is_member_of('pgf_roles', 'pgf_admins', 'Role "pgf_admins" is member of "pgf_roles".');

SELECT has_table('public', 'roles', 'Schema public contains table "roles" of pgfactory-core.' );
SELECT has_table('public', 'services', 'Schema public contains table "services" of pgfactory-core.' );

SELECT has_function('public', 'create_account', '{text}', 'Function "create_account" exists.');
SELECT has_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" exists.');
SELECT has_function('public', 'drop_account', '{name}', 'Function "drop_account" exists.');
SELECT has_function('public', 'drop_user', '{name}', 'Function "drop_user" exists.');
SELECT has_function('public', 'list_accounts', '{}', 'Function "list_accounts" exists.');
SELECT has_function('public', 'list_users', '{name}', 'Function "list_users" exists.');
SELECT has_function('public', 'is_pgf_role', '{name}', 'Function "is_pgf_role" exists.');
SELECT has_function('public', 'is_user', '{name}', 'Function "is_user" exists.');
SELECT has_function('public', 'is_account', '{name}', 'Function "is_account" exists.');
SELECT has_function('public', 'is_admin', '{name}', 'Function "is_admin" exists.');
SELECT has_function('public', 'wh_exists', '{name}', 'Function "wh_exists" exists.');
SELECT has_function('public', 'grant_dispatcher', '{name,name}', 'Function "grant_dispatcher" exists.');
SELECT has_function('public', 'revoke_dispatcher', '{name,name}', 'Function "revoke_dispatcher" exists.');
SELECT has_function('public', 'grant_service', '{bigint,name}', 'Function "grant_service" exists.');
SELECT has_function('public', 'revoke_service', '{bigint,name}', 'Function "revoke_service" exists.');
SELECT has_function('public', 'list_services', '{}', 'Function "list_services" exists.');

-- Does "pgf_admins" is in table roles ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE rolname='pgf_admins'$$,
    $$VALUES (1, 'pgf_admins')$$,
    'Account "pgf_admins" exists in public.roles.'
);

SELECT diag(E'\n==== List warehouses and processes ====\n');

SELECT set_eq(
    $$SELECT COUNT(*) FROM list_warehouses()$$,
    $$VALUES (0)$$,
    'Should not find any warehouse.'
);

SELECT set_eq(
    $$SELECT COUNT(*) FROM list_processes()$$,
    $$VALUES (0)$$,
    'Should not find any process.'
);

SELECT lives_ok(
    $$CREATE EXTENSION hstore$$,
    'Create extension "hstore"');

SELECT lives_ok(
    $$CREATE EXTENSION wh_nagios$$,
    'Create extension "wh_nagios"');

SELECT set_eq(
    $$SELECT * FROM list_warehouses()$$,
    $$VALUES ('wh_nagios')$$,
    'Should find warehouse wh_nagios.'
);

SELECT lives_ok(
    $$CREATE EXTENSION pr_grapher$$,
    'Create extension "pr_grapher"');

SELECT set_eq(
    $$SELECT * FROM list_processes()$$,
    $$VALUES ('pr_grapher')$$,
    'Should find process pr_grapher.'
);

SELECT diag(E'\n==== Drop pgfactory_core ====\n');

SELECT lives_ok(
    $$DROP EXTENSION pr_grapher$$,
    'Drop extension "pr_grapher"');

SELECT lives_ok(
    $$DROP EXTENSION wh_nagios$$,
    'Drop extension "wh_nagios"');

SELECT lives_ok(
    $$DROP EXTENSION pgfactory_core$$,
    'Drop extension "pgfactory_core"');

SELECT hasnt_extension('pgfactory_core', 'Extension "pgfactory_core" does not exist.');
SELECT hasnt_table('public', 'roles', 'Schema public does not contains table "roles" of pgfactory-core.' );
SELECT hasnt_table('public', 'services', 'Schema public does not contains table "services" of pgfactory-core.' );

DROP ROLE pgfactory;
DROP ROLE pgf_admins;
DROP ROLE pgf_roles;

SELECT hasnt_role('pgfactory', 'Role "pgfactory" does not exists anymore.');
SELECT hasnt_role('pgf_admins', 'Role "pgf_admins" does not exists anymore.');
SELECT hasnt_role('pgf_roles', 'Role "pgf_roles" does not exists anymore.');

SELECT hasnt_function('public', 'create_account', '{text}', 'Function "create_account" does not exist.');
SELECT hasnt_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" does not exist.');
SELECT hasnt_function('public', 'drop_account', '{name}', 'Function "drop_account" does not exist.');
SELECT hasnt_function('public', 'drop_user', '{name}', 'Function "drop_user" does not exist.');
SELECT hasnt_function('public', 'list_accounts', '{name}', 'Function "list_accounts" does not exists.');
SELECT hasnt_function('public', 'list_users', '{}', 'Function "list_users" does not exist.');
SELECT hasnt_function('public', 'is_pgf_role', '{name}', 'Function "is_pgf_role" does not exist.');
SELECT hasnt_function('public', 'is_user', '{name}', 'Function "is_user" does not exist.');
SELECT hasnt_function('public', 'is_account', '{}', 'Function "is_account" does not exist.');
SELECT hasnt_function('public', 'is_admin', '{name}', 'Function "is_admin" does not exist.');
SELECT hasnt_function('public', 'wh_exists', '{name}', 'Function "wh_exists" does not exist.');
SELECT hasnt_function('public', 'grant_dispatcher', '{name,name}', 'Function "grant_dispatcher" does not exist.');
SELECT hasnt_function('public', 'revoke_dispatcher', '{name,name}', 'Function "revoke_dispatcher" does not exist.');
SELECT hasnt_function('public', 'grant_service', '{bigint,name}', 'Function "grant_service" does not exist.');
SELECT hasnt_function('public', 'revoke_service', '{bigint,name}', 'Function "revoke_service" does not exist.');
SELECT hasnt_function('public', 'list_services', '{}', 'Function "list_services" does not exist.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
