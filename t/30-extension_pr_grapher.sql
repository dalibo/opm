-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2014: Open PostgreSQL Monitoring Development Group

\unset ECHO
\i t/setup.sql

SELECT plan(58);

SELECT diag(E'\n==== Setup environnement ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION opm_core$$,
    'Create extension "opm_core"');

SELECT diag(E'\n==== Install pr_grapher ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION pr_grapher$$,
    'Create extension "pr_grapher"');

SELECT has_extension('pr_grapher', 'Extension "pr_grapher" should exist.');

SELECT results_eq(
    $$SELECT extversion FROM pg_extension WHERE extname = 'pr_grapher'$$,
    $$ VALUES('1.1')$$,
    'pr_grapher should be in version 1.1'
);

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
SELECT has_function('pr_grapher', 'js_timetz', '{timestamp with time zone}', 'Function "pr_grapher.js_timetz" exists.');
SELECT has_function('pr_grapher', 'get_categories', '{}', 'Function "pr_grapher.get_categories" exists.');
SELECT has_function('pr_grapher', 'list_graph', '{}', 'Function "pr_grapher.list_graph" exists.');


SELECT diag(E'\n==== Test functions ====\n');

SELECT set_eq($$SELECT * from pr_grapher.js_time('2013-01-01 12:34:56 CEST')$$,
    $$VALUES (1357036496000)$$,
    'Test js_time function.'
);

SELECT set_eq($$SELECT * from pr_grapher.js_timetz('2013-01-01 12:34:56 CEST')$$,
    $$VALUES (1357040096000)$$,
    'Test js_time function.'
);

SELECT diag(E'\n==== Test ACl ====\n');

SELECT set_eq($$SELECT COUNT(*) FROM pr_grapher.list_graph()$$,
    $$VALUES (0)$$,
    'Should not see any graph.'
);

SELECT lives_ok($$INSERT INTO pr_grapher.graphs (graph,description,config) VALUES
    ('Test graph 1','A simple graph test','{}'::json)$$,
    'Insert an empty graph'
);

SELECT set_eq($$SELECT id,graph,description,y1_query,y2_query,config::text  FROM pr_grapher.list_graph()$$,
    $$VALUES (1::bigint,'Test graph 1','A simple graph test',NULL,NULL,'{}')$$,
    'Should see one graph.'
);
-- As PG 9.2 can't compare two json, we need to test the return args
SELECT set_eq($$SELECT proallargtypes,proargmodes,proargnames FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE proname = 'list_graph' AND nspname = 'pr_grapher'$$,
    $$VALUES ('{20,25,25,25,25,114}'::oid[],'{t,t,t,t,t,t}'::"char"[],'{id,graph,description,y1_query,y2_query,config}'::text[])$$,
    'Return arguments of function list_graph of schema "pr_grapher" should be correct.'
);


SELECT diag(E'\n==== Check owner ====\n');

-- schemas privs
SELECT schema_owner_is( 'pr_grapher', 'opm' );

-- tables owner
SELECT table_owner_is( n.nspname, c.relname, 'opm'::name )
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'pr_grapher'
    )
    AND c.relpersistence <> 't';

-- sequences owner
SELECT sequence_owner_is(n.nspname, c.relname, 'opm'::name)
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'S'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'pr_grapher'
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
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher'
    );


SELECT diag(E'\n==== Check privileges ====\n');

-- schemas privs
SELECT schema_privs_are('pr_grapher', 'public', ARRAY[]::name[]);

-- tables privs
SELECT table_privs_are('pr_grapher', c.relname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_class c
WHERE c.relkind = 'r'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'pr_grapher'
    )
    AND c.relpersistence <> 't';

-- sequences privs
SELECT sequence_privs_are('pr_grapher', c.relname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_class c
WHERE c.relkind = 'S'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'pr_grapher'
    )
    AND c.relpersistence <> 't';

-- functions privs
SELECT function_privs_are( 'pr_grapher', p.proname, (
        SELECT string_to_array(oidvectortypes(proargtypes), ', ')
        FROM pg_proc
        WHERE oid=p.oid
    ),
    'public', ARRAY[]::name[]
)
FROM pg_depend dep
    JOIN pg_catalog.pg_proc p ON dep.objid = p.oid
WHERE dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'pr_grapher'
    );


SELECT diag(E'\n==== Drop pr_grapher ====\n');

SELECT lives_ok(
    $$DROP EXTENSION pr_grapher CASCADE;$$,
    'Drop extension "pr_grapher"'
);

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

SELECT hasnt_function('pr_grapher', 'js_time', '{timestamp with time zone}', 'Function "pr_grapher.js_time" does not exists.');
SELECT hasnt_function('pr_grapher', 'js_timetz', '{timestamp with time zone}', 'Function "pr_grapher.js_timetz" does not exists.');
SELECT hasnt_function('pr_grapher', 'get_categories', '{}', 'Function "pr_grapher.get_categories" does not exists.');
SELECT hasnt_function('pr_grapher', 'list_graph', '{}', 'Function "pr_grapher.list_graph" does not exists.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
