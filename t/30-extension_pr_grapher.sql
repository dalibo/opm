\unset ECHO
\i t/setup.sql

SELECT plan(51);

SELECT diag(E'\n==== Setup environnement ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION pgfactory_core$$,
    'Create extension "pgfactory_core"');

SELECT diag(E'\n==== Install pr_grapher ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION pr_grapher$$,
    'Create extension "pr_grapher"');

SELECT has_extension('pr_grapher', 'Extension "pr_grapher" should exist.');
SELECT extension_schema_is('pr_grapher', 'pr_grapher',
    'Schema of extension "pr_grapher" should be "pr_grapher".'
);

SELECT has_schema('pr_grapher', 'Schema "pr_grapher" should exist.');
SELECT has_table('pr_grapher', 'graphs',
    'Table "graphs" of schema "pr_grapher" should exists.'
);
SELECT has_table('pr_grapher', 'categories',
    'Table "categories" of schema "pr_grapher" should exists.'
);
SELECT has_table('pr_grapher', 'nested_categories',
    'Table "nested_categories" of schema "pr_grapher" should exists.'
);
SELECT has_table('pr_grapher', 'graph_categories',
    'Table "graph_categories" of schema "pr_grapher" should exists.'
);
SELECT has_table('pr_grapher', 'graph_services',
    'Table "graph_services" of schema "pr_grapher" should exists.'
);
SELECT has_table('pr_grapher', 'series',
    'Table "series" of schema "pr_grapher" should exists.'
);

SELECT has_function('pr_grapher', 'create_graph_for_services', '{bigint}', 'Function "pr_grapher.create_graph_for_services" exists.');
SELECT has_function('pr_grapher', 'js_time', '{timestamp with time zone}', 'Function "pr_grapher.js_time" exists.');
SELECT has_function('pr_grapher', 'get_categories', '{}', 'Function "pr_grapher.get_categories" exists.');
SELECT has_function('pr_grapher', 'list_graph', '{}', 'Function "pr_grapher.list_graph" exists.');

SELECT diag(E'\n==== Test ACl ====\n');

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_services(1)$$,
    $$VALUES (FALSE)$$,
    'Should not be able to generate a graph for an inexistant service.'
);

SELECT lives_ok($$INSERT INTO public.servers (hostname) VALUES
    ('hostname1'),('hostname2')$$,
    'Insert two servers'
);

SELECT lives_ok(
    $$CREATE EXTENSION hstore$$,
    'Create extension "hstore"');

SELECT lives_ok(
    $$CREATE EXTENSION wh_nagios$$,
    'Create extension "wh_nagios"');

SELECT lives_ok($$INSERT INTO public.services (id_server,warehouse,service) VALUES
    (1,'wh_nagios','service1'),(2,'wh_nagios','service2')$$,
    'Insert two services'
);

SELECT set_eq($$SELECT COUNT(*) FROM pr_grapher.list_graph()$$,
    $$VALUES (0)$$,
    'Should not see any graph.'
);

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_services(1)$$,
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

SELECT set_eq($$SELECT id,graph,description,y1_query,y2_query,config::text,id_server,id_service FROM pr_grapher.list_graph()$$,
    $$VALUES (1::bigint,'service1',NULL,NULL,NULL, '{"type": "lines"}'::text,1::bigint,1::bigint)$$,
    'Should only see one graph.'
);

--Need to allow u3 to create temp tables for pgtap
SELECT lives_ok(format('GRANT TEMPORARY ON DATABASE %I TO u1',current_database()),'Grant TEMPORARY on current db to u1');

SELECT lives_ok('SET SESSION AUTHORIZATION u1','Set session authorization to u1');
SELECT lives_ok('SET ROLE u1','Set role u1');

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_services(2)$$,
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

SELECT set_eq($$SELECT * FROM pr_grapher.create_graph_for_services(2)$$,
    $$VALUES (TRUE)$$,
    'User "u1" should be able to generate graph for service 2.'
);

SELECT set_eq($$SELECT id,graph,description,y1_query,y2_query,config::text,id_server,id_service FROM pr_grapher.list_graph()$$,
    $$VALUES (2::bigint,'service2',NULL,NULL,NULL, '{"type": "lines"}'::text,2::bigint,2::bigint)$$,
    'Should only see graph 2.'
);

SELECT lives_ok('RESET SESSION AUTHORIZATION','Reset session authorization');
SELECT lives_ok('RESET ROLE','Reset role');
--Revoke from u1 create temp tables
SELECT lives_ok(format('REVOKE TEMPORARY ON DATABASE %I FROM u1',current_database()),'Revoke TEMPORARY on current db from u1');

SELECT lives_ok(
	$$DROP EXTENSION wh_nagios;$$,
	'Drop extension "wh_nagios"');

SELECT diag(E'\n==== Drop pr_grapher ====\n');

SELECT lives_ok(
	$$DROP EXTENSION pr_grapher CASCADE;$$,
	'Drop extension "pr_grapher"');

SELECT hasnt_table('pr_grapher', 'graphs',
    'Table "graphs" of schema "pr_grapher" should not exists anymore.'
);
SELECT hasnt_table('pr_grapher', 'categories',
    'Table "categories" of schema "pr_grapher" should not exists anymore.'
);
SELECT hasnt_table('pr_grapher', 'nested_categories',
    'Table "nested_categories" of schema "pr_grapher" should not exists anymore.'
);
SELECT hasnt_table('pr_grapher', 'graph_categories',
    'Table "graph_categories" of schema "pr_grapher" should not exists anymore.'
);
SELECT hasnt_table('pr_grapher', 'graph_services',
    'Table "graph_services" of schema "pr_grapher" should not exists anymore.'
);
SELECT hasnt_table('pr_grapher', 'series',
    'Table "series" of schema "pr_grapher" should not exists anymore.'
);

SELECT hasnt_function('pr_grapher', 'create_graph_for_services', '{bigint}', 'Function "pr_grapher.create_graph_for_services" does not exists.');
SELECT hasnt_function('pr_grapher', 'js_time', '{timestamp with time zone}', 'Function "pr_grapher.js_time" does not exists.');
SELECT hasnt_function('pr_grapher', 'get_categories', '{}', 'Function "pr_grapher.get_categories" does not exists.');
SELECT hasnt_function('pr_grapher', 'list_graph', '{}', 'Function "pr_grapher.list_graph" does not exists.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
