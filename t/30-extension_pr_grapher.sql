\unset ECHO
\i t/setup.sql

SELECT plan(25);

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
SELECT has_table('pr_grapher', 'series',
    'Table "series" of schema "pr_grapher" should exists.'
);

SELECT has_function('pr_grapher', 'js_time', '{timestamp with time zone}', 'Function "pr_grapher.js_time" exists.');
SELECT has_function('pr_grapher', 'get_categories', '{}', 'Function "pr_grapher.get_categories" exists.');
SELECT has_function('pr_grapher', 'list_graph', '{}', 'Function "pr_grapher.list_graph" exists.');

SELECT diag(E'\n==== Test ACl ====\n');

SELECT set_eq($$SELECT COUNT(*) FROM pr_grapher.list_graph()$$,
    $$VALUES (0)$$,
    'Should not see any graph.'
);

SELECT diag(E'\n==== Drop pr_grapher ====\n');

SELECT lives_ok(
	$$DROP EXTENSION pr_grapher CASCADE;$$,
	'Drop extension "pr_grapher"');

SELECT hasnt_extension('pr_grapher','Extensions "pr_grapher" should not exists anymore.');

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
