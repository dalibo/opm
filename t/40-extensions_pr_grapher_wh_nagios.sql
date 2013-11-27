-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2013: Open PostgreSQL Monitoring Development Group

\unset ECHO
\i t/setup.sql

SELECT plan(55);

SELECT diag(E'\n==== Setup environnement ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION opm_core$$,
    'Create extension "opm_core"');

SELECT diag(E'\n==== Install pr_grapher ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION pr_grapher$$,
    'Create extension "pr_grapher"');

SELECT diag(E'\n==== Install wh_nagios ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION hstore$$,
    'Create extension "hstore"');

SELECT lives_ok(
    $$CREATE EXTENSION wh_nagios$$,
    'Create extension "wh_nagios"');

SELECT diag(E'\n==== Install pr_grapher_wh_nagios ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION pr_grapher_wh_nagios$$,
    'Create extension "pr_grapher_wh_nagios"');

SELECT has_extension('pr_grapher_wh_nagios', 'Extension "pr_grapher_wh_nagios" should exist.');
SELECT extension_schema_is('pr_grapher_wh_nagios', 'pr_grapher',
    'Schema of extension "pr_grapher_wh_nagios" should be "pr_grapher".'
);

SELECT has_schema('pr_grapher', 'Schema "pr_grapher" should exist.');
SELECT has_table('pr_grapher', 'graph_wh_nagios',
    'Table "graph_wh_nagios" of schema "pr_grapher" should exists.'
);

SELECT has_function('pr_grapher', 'create_graph_for_wh_nagios', '{bigint}', 'Function "pr_grapher.create_graph_for_wh_nagios(bigint)" exists.');
SELECT has_function('pr_grapher', 'list_wh_nagios_graphs', '{}', 'Function "pr_grapher.list_wh_nagios_graphs()" exists.');
SELECT has_function('pr_grapher', 'list_wh_nagios_labels', '{bigint}', 'Function "pr_grapher.list_wh_nagios_labels(bigint)" exists.');

SELECT diag(E'\n==== Test ACl ====\n');

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_wh_nagios(1)$$,
    $$VALUES (FALSE)$$,
    'Should not be able to generate a graph for an inexistant service.'
);

SELECT lives_ok($$INSERT INTO public.servers (hostname) VALUES
    ('hostname1'),('hostname2')$$,
    'Insert two servers'
);

SELECT set_eq($$SELECT * FROM public.list_servers()$$,
    $$VALUES (1,'hostname1',NULL),(2,'hostname2',NULL)$$,
    'Servers hostname1 and hostname2 should exist.'
);

SELECT lives_ok($$INSERT INTO wh_nagios.services (id_server,warehouse,service) VALUES
    (1,'wh_nagios','service1'),(2,'wh_nagios','service2')$$,
    'Insert two services'
);

SELECT lives_ok($$INSERT INTO wh_nagios.labels (id_service,label) VALUES
    (1,'service1 label1'),(2,'service2 label 1')$$,
    'Insert two labels'
);

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_wh_nagios(1)$$,
    $$VALUES (TRUE)$$,
    'Generate graph for service 1.'
);

SELECT set_eq(
    $$SELECT * FROM create_account('acc1')$$,
    $$VALUES (2, 'acc1')$$,
    'Account "acc1" should be created.'
);

SELECT set_eq(
    $$SELECT * FROM create_user('u1', 'pass1', '{acc1}')$$,
    $$VALUES (3,'u1')$$,
    'User "u1" in account "acc1" should be created.'
);

SELECT set_eq($$SELECT id,graph,description,y1_query,y2_query,config::text FROM pr_grapher.list_graph()$$,
    $$VALUES (1::bigint,'service1 (no unit)',NULL,NULL,NULL, '{"type": "lines"}'::text)$$,
    'Should only see one graph.'
);

--Need to allow u3 to create temp tables for pgtap
SELECT lives_ok(format('GRANT TEMPORARY ON DATABASE %I TO u1',current_database()),'Grant TEMPORARY on current db to u1');

SELECT lives_ok('SET SESSION AUTHORIZATION u1','Set session authorization to u1');
SELECT lives_ok('SET ROLE u1','Set role u1');

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_wh_nagios(2)$$,
    $$VALUES (FALSE)$$,
    'User "u1" should not be able to generate graph for service 2.'
);

SELECT lives_ok('RESET SESSION AUTHORIZATION','Reset session authorization');
SELECT lives_ok('RESET ROLE','Reset role');

SELECT set_eq(
    $$SELECT * FROM public.grant_server(2,'u1')$$,
    $$VALUES (TRUE)$$,
    'Server "2" should be granted to user "u1".'
);

SELECT lives_ok('SET SESSION AUTHORIZATION u1','Set session authorization to u1');
SELECT lives_ok('SET ROLE u1','Set role u1');

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_wh_nagios(2)$$,
    $$VALUES (TRUE)$$,
    'User "u1" should be able to generate graph for service 2.'
);

SELECT set_eq($$SELECT id,graph,description,y1_query,y2_query,config::text,id_server,id_service FROM pr_grapher.list_wh_nagios_graphs()$$,
    $$VALUES (2::bigint,'service2 (no unit)',NULL,NULL,NULL, '{"type": "lines"}'::text,2::bigint,2::bigint)$$,
    'Should only see graph 2.'
);

SELECT lives_ok('RESET SESSION AUTHORIZATION','Reset session authorization');
SELECT lives_ok('RESET ROLE','Reset role');
--Revoke from u1 create temp tables
SELECT lives_ok(format('REVOKE TEMPORARY ON DATABASE %I FROM u1',current_database()),'Revoke TEMPORARY on current db from u1');

SELECT set_eq($$SELECT * FROM pr_grapher.list_wh_nagios_labels(1)$$,
    $$VALUES (1::bigint, 1::bigint, 'service1 label1', NULL::text, 1::bigint, true)$$,
    'Should see one labels for graph 1'
);



SELECT diag(E'\n==== Check owner ====\n');

-- schemas privs
SELECT schema_owner_is( 'pr_grapher', 'opm' );

-- tables owner
SELECT table_owner_is( n.nspname, c.relname, 'opm'::name )
FROM pg_depend dep
JOIN pg_catalog.pg_class c ON dep.objid = c.oid
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r'
    AND dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher_wh_nagios'
    )
    AND c.relpersistence <> 't';

-- sequences owner
SELECT sequence_owner_is(n.nspname, c.relname, 'opm'::name)
FROM pg_depend dep
JOIN pg_catalog.pg_class c ON dep.objid = c.oid
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'S'
    AND dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher_wh_nagios'
    )
    AND c.relpersistence <> 't';


-- functions owner
SELECT function_owner_is( n.nspname, p.proname, (
        SELECT string_to_array(oidvectortypes(proargtypes), ', ')
        FROM pg_proc
        WHERE oid=p.oid
    ),
    'opm'::name
)
FROM pg_depend dep
    JOIN pg_catalog.pg_proc p ON dep.objid = p.oid
    JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher_wh_nagios'
    );


SELECT diag(E'\n==== Check privileges ====\n');

-- schemas privs
SELECT schema_privs_are('pr_grapher', 'public', ARRAY[]::name[]);

-- tables privs
SELECT table_privs_are('pr_grapher', c.relname, 'public', ARRAY[]::name[])
FROM pg_depend dep
JOIN pg_catalog.pg_class c ON dep.objid = c.oid
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r'
    AND dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher_wh_nagios'
    )
    AND c.relpersistence <> 't';

-- sequences privs
SELECT sequence_privs_are('pr_grapher', c.relname, 'public', ARRAY[]::name[])
FROM pg_depend dep
JOIN pg_catalog.pg_class c ON dep.objid = c.oid
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'S'
    AND dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher_wh_nagios'
    )
    AND c.relpersistence <> 't';

-- functions privs
SELECT function_privs_are( 'pr_grapher', p.proname, (
        SELECT string_to_array(oidvectortypes(proargtypes), ', ')
        FROM pg_proc
        WHERE oid=p.oid
    ),
    'public'::name, ARRAY[]::name[]
)
FROM pg_depend dep
    JOIN pg_catalog.pg_proc p ON dep.objid = p.oid
    JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher_wh_nagios'
    );



SELECT diag(E'\n==== Drop pr_grapher_wh_nagios ====\n');

SELECT lives_ok(
    $$DROP EXTENSION pr_grapher_wh_nagios CASCADE;$$,
    'Drop extension "pr_grapher_wh_nagios"');

SELECT hasnt_extension('pr_grapher_wh_nagios','Extensions "pr_grapher_wh_nagios" should not exists anymore.');
SELECT has_extension('pr_grapher','Extensions "pr_grapher" should still anymore.');
SELECT has_extension('wh_nagios','Extensions "wh_nagios" should still anymore.');

SELECT hasnt_table('pr_grapher', 'graph_labels',
    'Table "graph_labels" of schema "pr_grapher" should not exists anymore.'
);

SELECT hasnt_function('pr_grapher', 'create_graph_for_wh_nagios', '{bigint}', 'Function "pr_grapher.create_graph_for_wh_nagios(bigint)" should not exists anymore.');
SELECT hasnt_function('pr_grapher', 'list_wh_nagios_graphs', '{}', 'Function "pr_grapher.list_wh_nagios_graphs" should not exists anymore.');
SELECT hasnt_function('pr_grapher', 'list_wh_nagios_labels', '{}', 'Function "pr_grapher.list_wh_nagios_labels" should not exists anymore.');
SELECT hasnt_function('pr_grapher', 'list_wh_nagios_labels', '{bigint}', 'Function "pr_grapher.list_wh_nagios_labels(bigint)" should not exists anymore.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
