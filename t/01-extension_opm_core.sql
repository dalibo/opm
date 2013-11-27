-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2013: Open PostgreSQL Monitoring Development Group

\unset ECHO
\i t/setup.sql

SELECT plan(141);

SELECT diag(E'\n==== Install opm-core ====\n');

SELECT has_schema('public', 'Schema public exists.' );

SELECT lives_ok(
    $$CREATE EXTENSION opm_core$$,
    'Create extension "opm_core"'
);

SELECT has_extension('opm_core', 'Extension "opm_core" is installed.');

SELECT has_role('opm', 'Role "opm" exists.');
SELECT has_role('opm_admins', 'Role "opm_admins" exists.');
SELECT has_role('opm_roles', 'Role "opm_roles" exists.');
SELECT is_member_of('opm', 'opm_admins', 'Role "opm_admins" is member of "opm".');
SELECT is_member_of('opm_roles', 'opm_admins', 'Role "opm_admins" is member of "opm_roles".');

SELECT has_table('public', 'roles', 'Schema public contains table "roles" of opm_core.' );
SELECT has_table('public', 'services', 'Schema public contains table "services" of opm_core.' );

SELECT has_function('public', 'create_account', '{text}', 'Function "create_account" exists.');
SELECT has_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" exists.');
SELECT has_function('public', 'drop_account', '{name}', 'Function "drop_account" exists.');
SELECT has_function('public', 'drop_user', '{name}', 'Function "drop_user" exists.');
SELECT has_function('public', 'list_accounts', '{}', 'Function "list_accounts" exists.');
SELECT has_function('public', 'list_users', '{name}', 'Function "list_users" exists.');
SELECT has_function('public', 'is_opm_role', '{name}', 'Function "is_opm_role" exists.');
SELECT has_function('public', 'is_user', '{name}', 'Function "is_user" exists.');
SELECT has_function('public', 'is_account', '{name}', 'Function "is_account" exists.');
SELECT has_function('public', 'is_admin', '{name}', 'Function "is_admin" exists.');
SELECT has_function('public', 'list_warehouses', '{}', 'Function "list_warehouses" exists.');
SELECT has_function('public', 'wh_exists', '{name}', 'Function "wh_exists" exists.');
SELECT has_function('public', 'list_processes', '{}', 'Function "list_processes" exists.');
SELECT has_function('public', 'pr_exists', '{name}', 'Function "pr_exists" exists.');
SELECT has_function('public', 'grant_dispatcher', '{name,name}', 'Function "grant_dispatcher" exists.');
SELECT has_function('public', 'revoke_dispatcher', '{name,name}', 'Function "revoke_dispatcher" exists.');
SELECT has_function('public', 'list_services', '{}', 'Function "list_services" exists.');
SELECT has_function('public', 'grant_server', '{bigint,name}', 'Function "grant_server" exists.');
SELECT has_function('public', 'revoke_server', '{bigint,name}', 'Function "revoke_server" exists.');
SELECT has_function('public', 'list_servers', '{}', 'Function "list_servers" exists.');
SELECT has_function('public', 'grant_account', '{name,name}', 'Function "grant_account" exists.');
SELECT has_function('public', 'revoke_account', '{name,name}', 'Function "revoke_account" exists.');

-- Does "opm_admins" is in table roles ?
SELECT set_eq(
    $$SELECT id, rolname FROM public.roles WHERE rolname='opm_admins'$$,
    $$VALUES (1, 'opm_admins')$$,
    'Account "opm_admins" exists in public.roles.'
);

SELECT diag(E'\n==== List warehouses and processes ====\n');

SELECT set_eq(
    $$SELECT COUNT(*) FROM list_warehouses()$$,
    $$VALUES (0)$$,
    'Should not find any warehouse.'
);

SELECT set_eq(
    $$SELECT * FROM wh_exists('wh_nagios')$$,
    $$VALUES (FALSE)$$,
    'Should not find warehouse wh_nagios.'
);

SELECT set_eq(
    $$SELECT COUNT(*) FROM list_processes()$$,
    $$VALUES (0)$$,
    'Should not find any process.'
);

SELECT set_eq(
    $$SELECT * FROM pr_exists('pr_grapher')$$,
    $$VALUES (FALSE)$$,
    'Should not find process pr_grapher.'
);

SELECT lives_ok(
    $$CREATE EXTENSION hstore$$,
    'Create extension "hstore"'
);

SELECT lives_ok(
    $$CREATE EXTENSION wh_nagios$$,
    'Create extension "wh_nagios"'
);

SELECT set_eq(
    $$SELECT * FROM list_warehouses()$$,
    $$VALUES ('wh_nagios')$$,
    'Should find warehouse wh_nagios.'
);

SELECT set_eq(
    $$SELECT * FROM wh_exists('wh_nagios')$$,
    $$VALUES (TRUE)$$,
    'Should find warehouse wh_nagios.'
);

SELECT lives_ok(
    $$DROP EXTENSION wh_nagios$$,
    'Drop extension "wh_nagios"'
);

SELECT lives_ok(
    $$DROP SCHEMA wh_nagios$$,
    'Drop schema "wh_nagios"'
);

SELECT lives_ok(
    $$CREATE EXTENSION pr_grapher$$,
    'Create extension "pr_grapher"'
);

SELECT set_eq(
    $$SELECT * FROM list_processes()$$,
    $$VALUES ('pr_grapher')$$,
    'Should find process pr_grapher.'
);

SELECT set_eq(
    $$SELECT * FROM pr_exists('pr_grapher')$$,
    $$VALUES (TRUE)$$,
    'Should find process pr_grapher.'
);

SELECT lives_ok(
    $$DROP EXTENSION pr_grapher$$,
    'Drop extension "pr_grapher"'
);

SELECT lives_ok(
    $$DROP SCHEMA pr_grapher$$,
    'Drop schema "pr_grapher"'
);


SELECT diag(E'\n==== Check owner ====\n');

-- schemas owner
SELECT schema_owner_is( n.nspname, 'opm' )
FROM pg_catalog.pg_namespace n
WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema';

-- tables owner
SELECT table_owner_is( n.nspname, c.relname, 'opm'::name )
FROM pg_catalog.pg_class c
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','')
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND c.relpersistence <> 't';

-- sequences owner
SELECT sequence_owner_is(n.nspname, c.relname, 'opm'::name)
FROM pg_catalog.pg_class c
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('S','')
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND c.relpersistence <> 't';

-- functions owner
SELECT function_owner_is( n.nspname, p.proname, (
        SELECT string_to_array(oidvectortypes(proargtypes), ', ')
        FROM pg_proc
        WHERE oid=p.oid
    ),
    'opm'
)
FROM pg_depend dep
    JOIN pg_catalog.pg_proc p ON dep.objid = p.oid
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE dep.deptype= 'e' AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'opm_core'
    )
    AND pg_catalog.pg_function_is_visible(p.oid);


SELECT diag(E'\n==== Check privileges ====\n');

-- database privs
SELECT database_privs_are(current_database(), 'public', ARRAY[]::name[]);

-- schemas privs
SELECT schema_privs_are(n.nspname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_namespace n
WHERE n.nspname !~ '^pg_' AND n.nspname <> 'information_schema';

-- tables privs
SELECT table_privs_are(n.nspname, c.relname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_class c
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('r','')
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND c.relpersistence <> 't';

-- sequences privs
SELECT sequence_privs_are(n.nspname, c.relname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_class c
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind IN ('S','')
    AND n.nspname <> 'pg_catalog'
    AND n.nspname <> 'information_schema'
    AND n.nspname !~ '^pg_toast'
    AND c.relpersistence <> 't';

-- functions privs
SELECT function_privs_are( n.nspname, p.proname, (
        SELECT string_to_array(oidvectortypes(proargtypes), ', ')
        FROM pg_proc
        WHERE oid=p.oid
    ),
    'public', ARRAY[]::name[]
)
FROM pg_depend dep
    JOIN pg_catalog.pg_proc p ON dep.objid = p.oid
    LEFT JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
WHERE dep.deptype= 'e' AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'opm_core'
    )
    AND pg_catalog.pg_function_is_visible(p.oid);


SELECT diag(E'\n==== Drop opm_core ====\n');

SELECT lives_ok(
    $$DROP EXTENSION opm_core$$,
    'Drop extension "opm_core"'
);

SELECT hasnt_extension('opm_core', 'Extension "opm_core" does not exist.');
SELECT hasnt_table('public', 'roles', 'Schema public does not contains table "roles" of opm_core.' );
SELECT hasnt_table('public', 'services', 'Schema public does not contains table "services" of opm_core.' );

SELECT lives_ok(
    format('REVOKE ALL ON DATABASE %I FROM opm, opm_roles', pg_catalog.current_database()),
    'Revoke ALL on current db from opm'
);
SELECT lives_ok(
    'REASSIGN OWNED BY opm, opm_roles, opm_admins TO postgres',
    'Reasigned all objects of opm, opm_roles, opm_admins to postgres'
);

SELECT lives_ok($$DROP ROLE opm$$, 'Drop role opm');
SELECT lives_ok($$DROP ROLE opm_admins$$, 'Drop role opm_admin');

SELECT lives_ok(
    'REVOKE ALL ON SCHEMA public FROM opm_roles',
    'Revoke all on schema public from opm_roles'
);
SELECT lives_ok($$DROP ROLE opm_roles$$, 'Drop role opm_roles');

SELECT hasnt_role('opm', 'Role "opm" does not exists anymore.');
SELECT hasnt_role('opm_admins', 'Role "opm_admins" does not exists anymore.');
SELECT hasnt_role('opm_roles', 'Role "opm_roles" does not exists anymore.');

SELECT hasnt_function('public', 'create_account', '{text}', 'Function "create_account" does not exist anymore.');
SELECT hasnt_function('public', 'create_user', '{text, text, name[]}', 'Function "create_user" does not exist anymore.');
SELECT hasnt_function('public', 'drop_account', '{name}', 'Function "drop_account" does not exist anymore.');
SELECT hasnt_function('public', 'drop_user', '{name}', 'Function "drop_user" does not exist anymore.');
SELECT hasnt_function('public', 'list_accounts', '{name}', 'Function "list_accounts" does not exists anymore.');
SELECT hasnt_function('public', 'list_users', '{}', 'Function "list_users" does not exist anymore.');
SELECT hasnt_function('public', 'is_opm_role', '{name}', 'Function "is_opm_role" does not exist anymore.');
SELECT hasnt_function('public', 'is_user', '{name}', 'Function "is_user" does not exist anymore.');
SELECT hasnt_function('public', 'is_account', '{}', 'Function "is_account" does not exist anymore.');
SELECT hasnt_function('public', 'is_admin', '{name}', 'Function "is_admin" does not exist anymore.');
SELECT hasnt_function('public', 'wh_exists', '{name}', 'Function "wh_exists" does not exist anymore.');
SELECT hasnt_function('public', 'grant_dispatcher', '{name,name}', 'Function "grant_dispatcher" does not exist. anymore');
SELECT hasnt_function('public', 'revoke_dispatcher', '{name,name}', 'Function "revoke_dispatcher" does not exist anymore.');
SELECT hasnt_function('public', 'grant_service', '{bigint,name}', 'Function "grant_service" does not exist anymore.');
SELECT hasnt_function('public', 'revoke_service', '{bigint,name}', 'Function "revoke_service" does not exist anymore.');
SELECT hasnt_function('public', 'list_services', '{}', 'Function "list_services" does not exist anymore.');
SELECT hasnt_function('public', 'grant_server', '{bigint,name}', 'Function "grant_server" does not exists anymore.');
SELECT hasnt_function('public', 'revoke_server', '{bigint,name}', 'Function "revoke_server" does not exists anymore.');
SELECT hasnt_function('public', 'list_servers', '{}', 'Function "list_servers" does not exists anymore.');
SELECT hasnt_function('public', 'grant_account', '{name,name}', 'Function "grant_account" does not exists anymore.');
SELECT hasnt_function('public', 'revoke_account', '{name,name}', 'Function "revoke_account" does not exists anymore.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
