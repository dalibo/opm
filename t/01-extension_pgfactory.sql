\unset ECHO
\i t/setup.sql

SELECT plan( 44 );

SELECT diag('====Install pgfactory-core ====');

SELECT has_schema('public', 'Schema public exists.' );

CREATE EXTENSION pgfactory_core;

SELECT has_extension('pgfactory_core', 'Extension "pgfactory_core" is installed.');

SELECT has_role('pgfactory', 'Role "pgfactory" exists.');
SELECT has_role('pgf_admins', 'Role "pgf_admins" exists.');
SELECT has_role('pgf_roles', 'Role "pgf_roles" exists.');
SELECT is_member_of('pgfactory', 'pgf_admins', 'Role "pgf_admins" is member of "pgfactory".');

SELECT has_table('public', 'roles', 'Schema public contains table "roles" of pgfactory-core.' );
SELECT has_table('public', 'services', 'Schema public contains table "services" of pgfactory-core.' );

SELECT has_function('public', 'create_account', '{text}', 'Function "create_account" exists.');
SELECT has_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" exists.');
SELECT has_function('public', 'drop_account', '{name}', 'Function "drop_account" exists.');
SELECT has_function('public', 'drop_user', '{name}', 'Function "drop_user" exists.');
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

SELECT diag('==== Drop pgfactory_core ====');

DROP EXTENSION pgfactory_core;

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
SELECT hasnt_function('public', 'list_users', '{}', 'Function "list_users" does not exist.');
SELECT hasnt_function('public', 'is_pgf_role', '{name}', 'Function "is_pgf_role" does not exist.');
SELECT hasnt_function('public', 'is_user', '{name}', 'Function "is_user" does not exist.');
SELECT hasnt_function('public', 'is_account', '{name}', 'Function "is_account" does not exist.');
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
