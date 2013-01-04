\unset ECHO
\i t/setup.sql

SELECT plan( 42 );

SELECT diag('====Install pgfactory-core ====');

SELECT has_schema('public', 'Schema public should exist.' );

CREATE EXTENSION pgfactory_core;

SELECT has_extension('pgfactory_core', 'Extension "pgfactory_core" should be installed.');

SELECT has_role('pgfactory', 'Role "pgfactory" should exist.');
SELECT has_role('pgf_admins', 'Role "pgf_admins" should exist.');
SELECT has_role('pgf_roles', 'Role "pgf_roles" should exist.');
SELECT is_member_of('pgfactory', 'pgf_admins', 'Role "pgf_admins" should be member of "pgfactory".');

SELECT has_table('public', 'roles', 'Schema public should contains table "roles" of pgfactory-core.' );
SELECT has_table('public', 'services', 'Schema public should contains table "services" of pgfactory-core.' );

SELECT has_function('public', 'create_account', '{text}', 'Function "create_account" should exist.');
SELECT has_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" should exist.');
SELECT has_function('public', 'drop_account', '{name}', 'Function "drop_account" should exist.');
SELECT has_function('public', 'drop_user', '{name}', 'Function "drop_user" should exist.');
SELECT has_function('public', 'list_users', '{name}', 'Function "list_users" should exist.');
SELECT has_function('public', 'is_pgf_role', '{name}', 'Function "is_pgf_role" should exist.');
SELECT has_function('public', 'is_user', '{name}', 'Function "is_user" should exist.');
SELECT has_function('public', 'is_account', '{name}', 'Function "is_account" should exist.');
SELECT has_function('public', 'wh_exists', '{name}', 'Function "wh_exists" should exist.');
SELECT has_function('public', 'grant_dispatcher', '{name,name}', 'Function "grant_dispatcher" should exist.');
SELECT has_function('public', 'revoke_dispatcher', '{name,name}', 'Function "revoke_dispatcher" should exist.');
SELECT has_function('public', 'grant_service', '{bigint,name}', 'Function "grant_service" should exist.');
SELECT has_function('public', 'revoke_service', '{bigint,name}', 'Function "revoke_service" should exist.');
SELECT has_function('public', 'list_services', '{}', 'Function "list_services" should exist.');

SELECT diag('==== Drop pgfactory_core ====');

DROP EXTENSION pgfactory_core;

SELECT hasnt_extension('pgfactory_core', 'Extension "pgfactory_core" should not exist.');
SELECT hasnt_table('public', 'roles', 'Schema public should not contains table "roles" of pgfactory-core.' );
SELECT hasnt_table('public', 'services', 'Schema public should not contains table "services" of pgfactory-core.' );

DROP ROLE pgfactory;
DROP ROLE pgf_admins;
DROP ROLE pgf_roles;

SELECT hasnt_role('pgfactory', 'Role "pgfactory" should not exists anymore.');
SELECT hasnt_role('pgf_admins', 'Role "pgf_admins" should not exists anymore.');
SELECT hasnt_role('pgf_roles', 'Role "pgf_roles" should not exists anymore.');

SELECT hasnt_function('public', 'create_account', '{text}', 'Function "create_account" should not exist.');
SELECT hasnt_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" should not exist.');
SELECT hasnt_function('public', 'drop_account', '{name}', 'Function "drop_account" should not exist.');
SELECT hasnt_function('public', 'drop_user', '{name}', 'Function "drop_user" should not exist.');
SELECT hasnt_function('public', 'list_users', '{}', 'Function "list_users" should not exist.');
SELECT hasnt_function('public', 'is_pgf_role', '{name}', 'Function "is_pgf_role" should not exist.');
SELECT hasnt_function('public', 'is_user', '{name}', 'Function "is_user" should not exist.');
SELECT hasnt_function('public', 'is_account', '{name}', 'Function "is_account" should not exist.');
SELECT hasnt_function('public', 'wh_exists', '{name}', 'Function "wh_exists" should not exist.');
SELECT hasnt_function('public', 'grant_dispatcher', '{name,name}', 'Function "grant_dispatcher" should not exist.');
SELECT hasnt_function('public', 'revoke_dispatcher', '{name,name}', 'Function "revoke_dispatcher" should not exist.');
SELECT hasnt_function('public', 'grant_service', '{bigint,name}', 'Function "grant_service" should not exist.');
SELECT hasnt_function('public', 'revoke_service', '{bigint,name}', 'Function "revoke_service" should not exist.');
SELECT hasnt_function('public', 'list_services', '{}', 'Function "list_services" should not exist.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
