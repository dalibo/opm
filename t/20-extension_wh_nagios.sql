-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2013: Open PostgreSQL Monitoring Development Group

\unset ECHO
\i t/setup.sql

SELECT plan(126);

SELECT diag(E'\n==== Setup environnement ====\n');

SELECT lives_ok(
    $$CREATE EXTENSION opm_core$$,
    'Create extension "opm_core"'
);

SELECT diag(E'\n==== Install wh_nagios ====\n');

SELECT throws_matching(
    $$CREATE EXTENSION wh_nagios$$,
    'required extension "hstore" is not installed',
    'Should not create extension "wh_nagios"'
);

SELECT lives_ok(
    $$CREATE EXTENSION hstore$$,
    'Create extension "hstore"'
);

SELECT lives_ok(
    $$CREATE EXTENSION wh_nagios$$,
    'Create extension "wh_nagios"'
);

SELECT has_extension(
    'wh_nagios',
    'Extension "wh_nagios" should exist.'
);
SELECT extension_schema_is('wh_nagios', 'wh_nagios',
    'Schema of extension "wh_nagios" should "wh_nagios".'
);

SELECT has_schema('wh_nagios', 'Schema "wh_nagios" should exist.');
SELECT has_table('wh_nagios', 'hub',
    'Table "hub" of schema "wh_nagios" should exists.'
);
SELECT has_table('wh_nagios', 'hub_reject',
    'Table "hub_reject" of schema "wh_nagios" should exists.'
);
SELECT has_table('wh_nagios', 'services',
    'Table "services" of schema "wh_nagios" should exists.'
);
SELECT has_table('wh_nagios', 'labels',
    'Table "labels" of schema "wh_nagios" should exists.'
);
SELECT has_view('wh_nagios', 'services_labels',
    'View "services_labels" of schema "wh_nagios" should exists.'
);

SELECT has_function('wh_nagios', 'grant_service', '{bigint,name}', 'Function "wh_nagios.grant_service" exists.');
SELECT has_function('wh_nagios', 'revoke_service', '{bigint,name}', 'Function "wh_nagios.revoke_service" exists.');
SELECT has_function('wh_nagios', 'grant_dispatcher', '{name}', 'Function "wh_nagios.grant_dispatcher" exists.');
SELECT has_function('wh_nagios', 'revoke_dispatcher', '{name}', 'Function "wh_nagios.revoke_dispatcher" exists.');
SELECT has_function('wh_nagios', 'cleanup_service', '{bigint}', 'Function "wh_nagios.cleanup_service" exists.');
SELECT has_function('wh_nagios', 'list_label', '{bigint}', 'Function "wh_nagios.list_label" exists.');
SELECT has_function('wh_nagios', 'list_services', '{}', 'Function "wh_nagios.list_services" exists.');
SELECT has_function('wh_nagios', 'dispatch_record', '{boolean}', 'Function "wh_nagios.dispatch_record" exists.');
SELECT has_function('wh_nagios', 'get_sampled_label_data', '{bigint, timestamp with time zone, timestamp with time zone, integer}', 'Function "wh_nagios.dispatch_record" (label) exists.');
SELECT has_function('wh_nagios', 'get_sampled_label_data', '{text, text, text, timestamp with time zone, timestamp with time zone, integer}', 'Function "wh_nagios.dispatch_record" (hostname, service, label) exists.');
SELECT has_function('wh_nagios', 'create_partition_on_insert_label', '{}', 'Function "wh_nagios.create_partition_on_insert_label" exists.');
SELECT has_function('wh_nagios', 'drop_partition_on_delete_label', '{}', 'Function "wh_nagios.create_partition_on_insert_label" exists.');



SELECT diag(E'\n==== Test wh_nagios functions ====\n');

SELECT diag(
    'Create account: ' || public.create_account('acc1') || 
    E'\nCreate user: ' || public.create_user('u1', 'pass', '{acc1}') ||
    E'\n'
);

SELECT schema_privs_are('wh_nagios', 'opm_roles', '{USAGE}',
    'Group "opm_roles" should only have priv "USAGE" on schema "wh_nagios".'
);

SELECT set_eq(
    $$SELECT COUNT(*) FROM wh_nagios.list_label(1)$$,
    $$VALUES (0)$$,
    'User "u1" should have access to list_label function in "wh_nagios".'
);

-- grant dispatching to u1
SELECT set_eq(
    $$SELECT wh_nagios.grant_dispatcher('u1')$$,
    $$VALUES (true)$$,
    'User "u1" should have been granted to dispatch in "wh_nagios".'
);

SELECT schema_privs_are('wh_nagios', 'u1', '{USAGE}',
    'Role "u1" should only have priv "USAGE" on schema "wh_nagios".'
);
SELECT table_privs_are('wh_nagios', 'hub', 'u1', '{INSERT}',
    'Role "u1" should only have priv "INSERT" on table "wh_nagios.hub".'
);
SELECT sequence_privs_are('wh_nagios', 'hub_id_seq', 'u1', '{USAGE}',
    'Role "u1" should only have priv "USAGE" on sequence "wh_nagios.hub_id_seq".'
);

SELECT diag(E'\n==== Test dispatching ====\n');

-- inserting data with role u1.
SET ROLE u1;

SELECT results_eq(
    $$SELECT current_user$$,
    $$VALUES ('u1'::name)$$,
    'Set role to u1'
);

SELECT lives_ok($$
    INSERT INTO wh_nagios.hub (id, data) VALUES
        (1, ARRAY[ -- more than one dim
            ['BAD RECORD'], ['BAD RECORD'],
            ['BAD RECORD'], ['BAD RECORD'],
            ['BAD RECORD'], ['BAD RECORD'],
            ['BAD RECORD'], ['BAD RECORD'],
            ['BAD RECORD'], ['BAD RECORD']
        ]), 
        (2, ARRAY['BAD RECORD', 'ANOTHER ONE']), -- less than 10 values
        (3, ARRAY[ -- number of parameter not even
            'BAD RECORD', 'BAD RECORD',
            'BAD RECORD', 'BAD RECORD',
            'BAD RECORD', 'BAD RECORD',
            'BAD RECORD', 'BAD RECORD',
            'BAD RECORD', 'BAD RECORD',
            'BAD RECORD'
        ]), 
        (4, ARRAY[ -- missing hostname
            'SERVICEDESC','pgactivity Database size',
            'LABEL','template0',
            'TIMET','1357208343',
            'VALUE','5284356',
            'SERVICESTATE','OK'
        ]),
        (5, ARRAY[ -- missing service desc
            'HOSTNAME','roquefort.dalibo.net',
            'LABEL','template0',
            'TIMET','1357208343',
            'VALUE','5284356',
            'SERVICESTATE','OK'
        ]),
        (6, ARRAY[ -- missing label
            'HOSTNAME','roquefort.dalibo.net',
            'SERVICEDESC','pgactivity Database size',
            'TIMET','1357208343',
            'VALUE','5284356',
            'SERVICESTATE','OK'
        ]),
        (7, ARRAY[ -- missing timet
            'HOSTNAME','roquefort.dalibo.net',
            'SERVICEDESC','pgactivity Database size',
            'LABEL','template0',
            'VALUE','5284356',
            'SERVICESTATE','OK'
        ]),
        (8, ARRAY[ -- missing value
            'HOSTNAME','roquefort.dalibo.net',
            'SERVICEDESC','pgactivity Database size',
            'LABEL','template0',
            'TIMET','1357208343',
            'SERVICESTATE','OK'
        ]),
        (9, ARRAY[ -- good one
            'MIN','0',
            'WARNING','209715200',
            'VALUE','5284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','roquefort.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357038000',
            'SERVICEDESC','pgactivity Database size'
        ]),
        (10, ARRAY[ -- another good one
            'MIN','0',
            'WARNING','209715200',
            'VALUE','6284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','gouda.dalibo.net',
            'MAX','0',
            'UOM','B',
            'SERVICESTATE','OK',
            'TIMET','1357038000',
            'SERVICEDESC','pgactivity Database size'
        ]),
        (11, ARRAY[ -- another good one
            'MIN','0',
            'WARNING','209715200',
            'VALUE','7284356',
            'CRITICAL','524288000',
            'LABEL','postgres',
            'HOSTNAME','gouda.dalibo.net',
            'MAX','0',
            'UOM','B',
            'SERVICESTATE','OK',
            'TIMET','1357038000',
            'SERVICEDESC','pgactivity Database size'
        ]
    )$$,
    'Insert some datas in "wh_nagios.hub" with role "u1".'
);

RESET ROLE;
SELECT results_ne(
    $$SELECT current_user$$,
    $$VALUES ('u1'::name)$$,
    'Reset role.'
);

SELECT diag(E'');
SELECT diag('inserted record: ' || s)
FROM wh_nagios.hub AS s;
SELECT diag(E'');

-- dispatching records
SELECT results_eq(
    $$SELECT * FROM wh_nagios.dispatch_record(true)$$,
    $$VALUES (3::bigint,8::bigint)$$,
    'Dispatching records.'
);

-- check rejected lines and status
SELECT set_eq(
    $$SELECT id, rolname, msg FROM wh_nagios.hub_reject$$,
    $$VALUES (1::bigint, 'u1'::name, 'given array has more than 1 dimension'),
        (2, 'u1', 'less than 10 values'),
        (3, 'u1', 'number of parameter not even'),
        (4, 'u1', 'hostname required'),
        (5, 'u1', 'servicedesc required'),
        (6, 'u1', 'label required'),
        (7, 'u1', 'timet required'),
        (8, 'u1', 'value required')$$,
    'Checking rejected lines.'
);

-- check table hub is now empty
SELECT set_eq(
    $$SELECT count(*) FROM wh_nagios.hub$$,
    $$VALUES (0::bigint)$$,
    'Table "wh_nagios.hub" should be empty now.'
);

-- check table wh_nagios.counters_detail_1
SELECT has_table('wh_nagios', 'counters_detail_1',
    'Table "wh_nagios.counters_detail_1" should exists.'
);

SELECT set_eq(
    $$SELECT * FROM wh_nagios.list_label(1)$$,
    $$VALUES (1::bigint, 'template0', '',0::numeric,0::numeric,524288000::numeric,209715200::numeric)$$,
    'list_label should see label template0.'
);

SELECT set_eq(
    $$SELECT date_records, extract(epoch FROM (c.records[1]).timet),
            (c.records[1]).value
        FROM wh_nagios.counters_detail_1 AS c$$,
    $$VALUES ('2013-01-01'::date, 1357038000::double precision,
        5284356::numeric)$$,
    'Table "wh_nagios.counters_detail_1" should have value of record 9.'
);

-- check table wh_nagios.counters_detail_2
SELECT has_table('wh_nagios', 'counters_detail_2',
    'Table "wh_nagios.counters_detail_2" should exists.'
);

SELECT set_eq(
    $$SELECT date_records, extract(epoch FROM (c.records[1]).timet),
            (c.records[1]).value
        FROM wh_nagios.counters_detail_2 AS c$$,
    $$VALUES ('2013-01-01'::date, 1357038000::double precision,
        6284356::numeric)$$,
    'Table "wh_nagios.counters_detail_2" should have value of record 10.'
);

-- check table wh_nagios.counters_detail_3
SELECT has_table('wh_nagios', 'counters_detail_3',
    'Table "wh_nagios.counters_detail_3" should exists.'
);

SELECT set_eq(
    $$SELECT date_records, extract(epoch FROM (c.records[1]).timet),
            (c.records[1]).value
        FROM wh_nagios.counters_detail_3 AS c$$,
    $$VALUES ('2013-01-01'::date, 1357038000::double precision,
        7284356::numeric)$$,
    'Table "wh_nagios.counters_detail_3" should have value of record 11.'
);

-- check table public.services
SELECT set_eq(
    $$SELECT s1.id, s2.hostname, s1.warehouse, s1.service, s1.last_modified, s1.creation_ts,
            s1.last_cleanup, s1.servalid, s2.id_role
        FROM public.services s1 JOIN public.servers s2 ON s1.id_server = s2.id$$,
    $$VALUES
        (1::bigint, 'roquefort.dalibo.net', 'wh_nagios'::name,
            'pgactivity Database size', current_date, now(), now(),
            NULL::interval, NULL::bigint),
        (2::bigint, 'gouda.dalibo.net', 'wh_nagios'::name,
            'pgactivity Database size', current_date, now(), now(),
            NULL::interval, NULL::bigint)$$,
    'Table "public.services" should have services defined by records 9, 10 (and 11).'
);

-- check table wh_nagios.services
SELECT set_eq(
    $$SELECT s1.id, s2.hostname, s1.warehouse, s1.service, s1.last_modified, s1.creation_ts,
            s1.last_cleanup, s1.servalid, s2.id_role, s1.state, l.min::numeric,
            l.max::numeric, l.critical::numeric, l.warning::numeric,
            extract(epoch FROM s1.oldest_record) AS oldest_record,
            extract(epoch FROM s1.newest_record) AS newest_record
        FROM wh_nagios.services s1
        JOIN wh_nagios.labels l ON s1.id = l.id_service
        JOIN public.servers s2 ON s1.id_server = s2.id$$,
    $$VALUES
        (1::bigint, 'roquefort.dalibo.net', 'wh_nagios'::name,
            'pgactivity Database size', current_date, now(), now(),
            NULL::interval, NULL::bigint, 'OK', 0, 0, 524288000,
            209715200, 1357038000::double precision, 1357038000::double precision),
        (2::bigint, 'gouda.dalibo.net', 'wh_nagios'::name,
            'pgactivity Database size', current_date, now(), now(),
            NULL::interval, NULL::bigint, 'OK', 0, 0, 524288000,
            209715200, 1357038000::double precision, 1357038000::double precision)$$,
    'Table "wh_nagios.services" should have services defined by records 9, 10 (and 11).'
);

-- check table public.labels
SELECT set_eq(
    $$SELECT * FROM wh_nagios.labels$$,
    $$VALUES
        (1,1,'template0', '', 0::numeric, 0::numeric,
            524288000::numeric, 209715200::numeric),
        (2,2,'template0', 'B', 0::numeric, 0::numeric,
            524288000::numeric, 209715200::numeric),
        (3,2,'postgres', 'B', 0::numeric, 0::numeric,
            524288000::numeric, 209715200::numeric)$$,
    'Table "wh_nagios.labels" should contains labels of records 9, 10 and 11.'
);

-- Revoke dispatching to u1
SELECT set_eq(
    $$SELECT wh_nagios.revoke_dispatcher('u1')$$,
    $$VALUES (true)$$,
    'Revoke dispatch in "wh_nagios" from role "u1".'
);

SELECT table_privs_are('wh_nagios', 'hub', 'u1', '{}',
    'Role "u1" should not have privs on table "wh_nagios.hub".'
);
SELECT sequence_privs_are('wh_nagios', 'hub_id_seq', 'u1', '{}',
    'Role "u1" should not have privs on sequence "wh_nagios.hub_id_seq".'
);

-- test inserting with u1
SET ROLE u1;
SELECT results_eq(
    $$SELECT current_user$$,
    $$VALUES ('u1'::name)$$,
    'Set role to u1.'
);


SELECT throws_matching($$
    INSERT INTO wh_nagios.hub (id, data) VALUES
        (12, ARRAY[ -- a good one
            'MIN','0',
            'WARNING','209715200',
            'VALUE','7284356',
            'CRITICAL','524288000',
            'LABEL','postgres',
            'HOSTNAME','gouda.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357038000',
            'SERVICEDESC','pgactivity Database size'
        ]
    )$$,
    'permission denied',
    'Insert now fail on "wh_nagios.hub" with role "u1".'
);

RESET ROLE;
SELECT results_ne(
    $$SELECT current_user$$,
    $$VALUES ('u1'::name)$$,
    'Reset role.'
);

SELECT lives_ok($$
    INSERT INTO wh_nagios.hub (id, data) VALUES
        (1, ARRAY[ -- unit is now "b"
            'MIN','0',
            'WARNING','209715200',
            'VALUE','6284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','gouda.dalibo.net',
            'MAX','0',
            'UOM','b',
            'SERVICESTATE','OK',
            'TIMET','1357638000',
            'SERVICEDESC','pgactivity Database size'
        ])$$,
    'Insert some datas in "wh_nagios.hub" and change unit.'
);

SELECT results_eq(
    $$SELECT * FROM wh_nagios.dispatch_record(true)$$,
    $$VALUES (1::bigint,0::bigint)$$,
    'Dispatching the record.'
);

-- check table wh_nagios.services
SELECT set_eq(
    $$SELECT l.unit
        FROM wh_nagios.labels l
        JOIN wh_nagios.services s1 ON l.id_service = s1.id
        JOIN public.servers s2 ON s1.id_server = s2.id
        WHERE s2.hostname = 'gouda.dalibo.net'
            AND service = 'pgactivity Database size'
            AND label = 'template0'$$,
    $$VALUES ('b')$$,
    'Field "unit" in "wh_nagios.labels" should be "b" instead of "B".'
);

SELECT diag(E'\n==== Partition cleanup ====\n');

SELECT lives_ok($$
    INSERT INTO wh_nagios.hub (id, data) VALUES
        (13, ARRAY[
            'MIN','0',
            'WARNING','209715200',
            'VALUE','5284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','roquefort.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357038300',
            'SERVICEDESC','pgactivity Database size'
        ]),
        (14, ARRAY[
            'MIN','0',
            'WARNING','209715200',
            'VALUE','5284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','roquefort.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357038600',
            'SERVICEDESC','pgactivity Database size'
        ]),
        (15, ARRAY[
            'MIN','0',
            'WARNING','209715200',
            'VALUE','5284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','roquefort.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357038900',
            'SERVICEDESC','pgactivity Database size'
        ]),
        (16, ARRAY[
            'MIN','0',
            'WARNING','209715200',
            'VALUE','5284356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','roquefort.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357039200',
            'SERVICEDESC','pgactivity Database size'
        ]),
        (17, ARRAY[
            'MIN','0',
            'WARNING','209715200',
            'VALUE','7285356',
            'CRITICAL','524288000',
            'LABEL','template0',
            'HOSTNAME','roquefort.dalibo.net',
            'MAX','0',
            'UOM','',
            'SERVICESTATE','OK',
            'TIMET','1357039500',
            'SERVICEDESC','pgactivity Database size'
        ]
    )$$,
    'Insert some more values for service 1, label "template0"'
);

-- dispatching new records
SELECT set_eq(
    $$SELECT * FROM wh_nagios.dispatch_record(true)$$,
    $$VALUES (5::bigint,0::bigint)$$,
    'Dispatching 5 new records.'
);

SELECT set_eq(
    $$WITH u AS (UPDATE wh_nagios.services
            SET last_cleanup = oldest_record - INTERVAL '1 month'
            RETURNING last_cleanup
        )
        SELECT * FROM u$$,
    $$VALUES (to_timestamp(1357038000) - INTERVAL '1 month')$$,
    'Set a fake last_cleanup timestamp.'
);

SELECT set_eq(
    $$SELECT wh_nagios.cleanup_service(1)$$,
    $$VALUES (true)$$,
    'Run cleanup_service on service 1.'
);

SELECT set_eq(
    $$SELECT last_cleanup, extract(epoch FROM oldest_record) AS oldest_record,
            extract(epoch FROM newest_record) AS newest_record
        FROM wh_nagios.services
        WHERE id=1$$,
    $$VALUES (now(), 1357038000::double precision,
        1357039500::double precision)$$,
    'Table "wh_nagios.services" fields should reflect last cleanup activity.'
);

SELECT diag('counters: '|| s) FROM wh_nagios.counters_detail_1 AS s;
SELECT set_eq(
    $$SELECT date_records, extract(epoch FROM timet), value
        FROM (SELECT date_records, (unnest(records)).*
            FROM wh_nagios.counters_detail_1
        ) as t$$,
    $$VALUES
        ('2013-01-01'::date, 1357038000::double precision, 5284356::numeric),
        ('2013-01-01'::date, 1357039200, 5284356),
        ('2013-01-01'::date, 1357039500, 7285356),
        ('2013-01-01'::date, 1357038300, 5284356),
        ('2013-01-01'::date, 1357038600, 5284356),
        ('2013-01-01'::date, 1357038900, 5284356)
        $$,
    'Consecutive records with same value of "wh_nagios.counters_detail_1" should not be cleaned.'
);

SELECT set_eq(
    $$SELECT date_records FROM wh_nagios.counters_detail_1$$,
    $$VALUES
        ('2013-01-01'::date)
    $$,
    'Records of "wh_nagios.counters_detail_1" should be aggregated.'
);

SELECT diag(E'\n==== Dropping a service ====\n');

SELECT lives_ok(
    $$DELETE FROM wh_nagios.services WHERE id = 2$$,
    'Delete service with id=2.'
);

-- check table public.labels do not have label from service 2 anymore
SELECT set_eq(
    $$SELECT * FROM wh_nagios.labels$$,
    $$VALUES (1,1,'template0', '', 0::numeric, 0::numeric,
        524288000::numeric, 209715200::numeric)$$,
    'Table "wh_nagios.labels" should not contains labels of service id 2 anymore.'
);

-- check tables has been drop'ed
SELECT hasnt_table('wh_nagios', 'counters_detail_2',
    'Table "wh_nagios.counters_detail_2" should not exists anymore.'
);
SELECT hasnt_table('wh_nagios', 'counters_detail_3',
    'Table "wh_nagios.counters_detail_3" should not exists anymore.'
);




SELECT diag(E'\n==== Check owner ====\n');

-- schemas owner
SELECT schema_owner_is( 'wh_nagios', 'opm' );

-- tables owner
SELECT table_owner_is( n.nspname, c.relname, 'opm'::name )
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'r'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'wh_nagios'
    )
    AND c.relpersistence <> 't';

-- sequences owner
SELECT sequence_owner_is(n.nspname, c.relname, 'opm'::name)
FROM pg_catalog.pg_class c
JOIN pg_catalog.pg_namespace n ON c.relnamespace = n.oid
WHERE c.relkind = 'S'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'wh_nagios'
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
        SELECT oid FROM pg_extension WHERE extname = 'wh_nagios'
    );



SELECT diag(E'\n==== Check privileges ====\n');

-- schemas privs
SELECT schema_privs_are('wh_nagios', 'public', ARRAY[]::name[]);

-- tables privs
SELECT table_privs_are('wh_nagios', c.relname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_class c
WHERE c.relkind = 'r'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'wh_nagios'
    )
    AND c.relpersistence <> 't';

-- sequences privs
SELECT sequence_privs_are('wh_nagios', c.relname, 'public', ARRAY[]::name[])
FROM pg_catalog.pg_class c
WHERE c.relkind = 'S'
    AND c.relnamespace = (
        SELECT oid FROM pg_catalog.pg_namespace n WHERE nspname = 'wh_nagios'
    )
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
    JOIN pg_catalog.pg_namespace n ON p.pronamespace = n.oid
WHERE dep.deptype= 'e'
    AND dep.refobjid = (
        SELECT oid FROM pg_extension WHERE extname = 'wh_nagios'
    );


SELECT diag(E'\n==== Drop wh_nagios ====\n');

SELECT lives_ok(
    $$DROP EXTENSION wh_nagios CASCADE;$$,
    'Drop extension "wh_nagios"'
);

SELECT hasnt_table('wh_nagios', 'hub',
    'Table "wh_nagios.hub" should not exists anymore.'
);
SELECT hasnt_table('wh_nagios', 'hub_reject',
    'Table "wh_nagios.hub_reject" should not exists anymore.'
);
SELECT hasnt_table('wh_nagios', 'services',
    'Table "wh_nagios.services" should not exists anymore.'
);
SELECT hasnt_table('wh_nagios', 'labels',
    'Table "wh_nagios.labels" should not exists anymore.'
);
SELECT hasnt_table('wh_nagios', 'services_labels',
    'Table "wh_nagios.services_labels" should not exists anymore.'
);

SELECT hasnt_function('wh_nagios', 'grant_service', '{bigint,name}', 'Function "wh_nagios.grant_service" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'revoke_service', '{bigint,name}', 'Function "wh_nagios.revoke_service" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'grant_dispatcher', '{name}', 'Function "wh_nagios.grant_dispatcher" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'revoke_dispatcher', '{name}', 'Function "wh_nagios.revoke_dispatcher" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'cleanup_service', '{bigint}', 'Function "wh_nagios.cleanup_service" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'list_label', '{bigint}', 'Function "wh_nagios.list_label" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'list_services', '{}', 'Function "wh_nagios.list_services" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'dispatch_record', '{boolean}', 'Function "wh_nagios.dispatch_record" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'get_sampled_label_data', '{bigint, timestamp with time zone, timestamp with time zone, integer}', 'Function "wh_nagios.dispatch_record" (label) should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'get_sampled_label_data', '{text, text, text, timestamp with time zone, timestamp with time zone, integer}', 'Function "wh_nagios.dispatch_record" (hostname, service, label) should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'create_partition_on_insert_label', '{}', 'Function "wh_nagios.create_partition_on_insert_label" should not exists anymore.');
SELECT hasnt_function('wh_nagios', 'drop_partition_on_delete_label', '{}', 'Function "wh_nagios.create_partition_on_insert_label" should not exists anymore.');

-- Finish the tests and clean up.
SELECT * FROM finish();

ROLLBACK;
