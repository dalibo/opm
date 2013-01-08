\unset ECHO
\i t/setup.sql

SELECT plan(16);

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
    'Table "graphs" of schema "pr_grapher" should not exists anymore.'
);
SELECT has_table('pr_grapher', 'categories',
    'Table "categories" of schema "pr_grapher" should not exists anymore.'
);
SELECT has_table('pr_grapher', 'nested_categories',
    'Table "nested_categories" of schema "pr_grapher" should not exists anymore.'
);
SELECT has_table('pr_grapher', 'graph_categories',
    'Table "graph_categories" of schema "pr_grapher" should not exists anymore.'
);
SELECT has_table('pr_grapher', 'series',
    'Table "series" of schema "pr_grapher" should not exists anymore.'
);

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
SELECT hasnt_table('pr_grapher', 'series',
    'Table "series" of schema "pr_grapher" should not exists anymore.'
);

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
