-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2014: Open PostgreSQL Monitoring Development Group

-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pr_grapher_wh_nagios" to load this file. \quit

SET statement_timeout TO 0;

-- Schema should already be created and granted for opm, with pr_grapher extension.
-- We only have to create a few objects.

-- A graph can display one or more services
CREATE TABLE pr_grapher.graph_wh_nagios (
  id_graph bigint references pr_grapher.graphs (id) on delete cascade on update cascade,
  id_label bigint not null references wh_nagios.labels (id) on delete cascade on update cascade
);

CREATE UNIQUE INDEX ON pr_grapher.graph_wh_nagios (id_label, id_graph);
CREATE INDEX ON pr_grapher.graph_wh_nagios (id_graph);
ALTER TABLE pr_grapher.graph_wh_nagios OWNER TO opm;
REVOKE ALL ON TABLE pr_grapher.graph_wh_nagios FROM public;

COMMENT ON TABLE pr_grapher.graph_wh_nagios IS
'This table defines which labels (series) appears in each graphs.
As this module is related to the UI, each time a new label is added to
an existing service, a new graph is created with this new label
automatically. We make the difference between a new label appearing from
a service with an old one deactivated in every related graphs using
"id_graph IS NULL". So as far as a label exists in this table, it is not
new and a new graph will not be created.
The natural PK here should be on (id_label, id_graph). But as "id_graph"
is NULLable we only use a UNIQUE INDEX.' ;
COMMENT ON COLUMN pr_grapher.graph_wh_nagios.id_graph IS 'Unique identifier of referenced graph. Can be NULL' ;
COMMENT ON COLUMN pr_grapher.graph_wh_nagios.id_label IS 'Unique identifier of referenced label.' ;

/*
Function pr_grapher.create_graph_for_wh_nagios(p_id_server bigint) returns boolean
@return rc: status

This function automatically generates for wh_nagios all graphs for a specified
server. If this function is called multiple times, it will only generate
"missing" graphs. A graph will be considered as missing if a label is not
present in any graph. Therefore, it's currently impossible not to graph a label.
FIXME: fix this limitation.
*/
CREATE OR REPLACE FUNCTION pr_grapher.create_graph_for_wh_nagios(IN p_server_id bigint, OUT rc boolean)
AS $$
DECLARE
  v_state   TEXT;
  v_msg     TEXT;
  v_detail  TEXT;
  v_hint    TEXT;
  v_context TEXT;
  labelsrow record;
  v_nb bigint;
BEGIN
  --Does the server exists ?
  SELECT COUNT(*) INTO v_nb FROM public.servers WHERE id = p_server_id;
  IF (v_nb <> 1) THEN
    RAISE WARNING 'Server % does not exists.', p_server_id;
    rc := false;
    RETURN;
  END IF;

  --Is the user allowed to create graphs ?
  SELECT COUNT(*) INTO v_nb FROM public.list_servers() WHERE id = p_server_id;
  IF (v_nb <> 1) THEN
    RAISE WARNING 'User not allowed for server %.', p_server_id;
    rc := false;
    RETURN;
  END IF;

  FOR labelsrow IN (
    SELECT DISTINCT s.service, l.id_service, COALESCE(l.unit,'') AS unit
    FROM wh_nagios.services s
    JOIN wh_nagios.labels l ON s.id = l.id_service
    WHERE s.id_server = p_server_id
        AND NOT EXISTS (
            SELECT 1 FROM pr_grapher.graph_wh_nagios gs
            JOIN wh_nagios.labels l2 ON l2.id=gs.id_label
            WHERE l2.id=l.id
        )
    )
  LOOP
    WITH new_graphs (id_graph) AS (
      INSERT INTO pr_grapher.graphs (graph, config)
        VALUES (labelsrow.service || ' (' || CASE WHEN labelsrow.unit = '' THEN 'no unit' ELSE 'in ' || labelsrow.unit END || ')', '{"type": "lines"}')
        RETURNING graphs.id
    )
    INSERT INTO pr_grapher.graph_wh_nagios (id_graph, id_label)
      SELECT new_graphs.id_graph, l.id
      FROM new_graphs
      CROSS JOIN wh_nagios.labels l
      WHERE l.id_service = labelsrow.id_service
        AND COALESCE(l.unit,'') = labelsrow.unit
        AND NOT EXISTS (
            SELECT 1 FROM pr_grapher.graph_wh_nagios gs
            JOIN wh_nagios.labels l2 ON l2.id=gs.id_label
            WHERE l2.id=l.id
        );
  END LOOP;
  rc := true;
EXCEPTION
  WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS
      v_state   = RETURNED_SQLSTATE,
      v_msg     = MESSAGE_TEXT,
      v_detail  = PG_EXCEPTION_DETAIL,
      v_hint    = PG_EXCEPTION_HINT,
      v_context = PG_EXCEPTION_CONTEXT;
    raise notice E'Unhandled error on pr_grapher.create_graph_for_wh_nagios:
      state  : %
      message: %
      detail : %
      hint   : %
      context: %', v_state, v_msg, v_detail, v_hint, v_context;
    rc := false;
END;
$$
LANGUAGE plpgsql
LEAKPROOF
SECURITY DEFINER;

ALTER FUNCTION pr_grapher.create_graph_for_wh_nagios(p_server_id bigint, OUT rc boolean) OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.create_graph_for_wh_nagios(p_server_id bigint, OUT rc boolean) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.create_graph_for_wh_nagios(p_server_id bigint, OUT rc boolean) TO opm_roles;

COMMENT ON FUNCTION pr_grapher.create_graph_for_wh_nagios(p_server_id bigint, OUT rc boolean) IS 'Create default graphs for all new services.';

/* pr_grapher.list_wh_nagios_graphs()
Return every pr_grapher.graphs%ROWTYPE a user can see
*/
CREATE OR REPLACE FUNCTION pr_grapher.list_wh_nagios_graphs()
RETURNS TABLE (id bigint, graph text, description text, y1_query text,
    y2_query text, config json, id_server bigint, id_service bigint)
AS $$
DECLARE
BEGIN
    IF is_admin(session_user) THEN
        RETURN QUERY SELECT  g2.id, g2.graph, g2.description, g2.y1_query, g2.y2_query, g2.config, s2.id, s1.id
            FROM ( SELECT DISTINCT g.id, l.id_service
                FROM pr_grapher.graphs g
                JOIN pr_grapher.graph_wh_nagios gs ON gs.id_graph = g.id
                JOIN wh_nagios.labels l ON gs.id_label = l.id
            ) g1
            JOIN pr_grapher.graphs g2 ON g1.id = g2.id
            JOIN public.services s1 ON s1.id = g1.id_service
            JOIN public.servers s2 ON s2.id = s1.id_server;
    ELSE
        RETURN QUERY SELECT g.id, g.graph, g.description, g.y1_query, g.y2_query, g.config, s2.id_server, s2.id_service
            FROM (
                SELECT DISTINCT gs.id_graph, s1.id_server, s1.id_service
                FROM (
                    SELECT (wh_nagios.list_label(ls.id)).id_label, ls.id_server, ls.id as id_service
                    FROM public.list_services() ls
                ) s1
                JOIN pr_grapher.graph_wh_nagios gs ON gs.id_label = s1.id_label
            ) s2
            JOIN pr_grapher.graphs g ON g.id = s2.id_graph;
    END IF;
END;
$$
LANGUAGE plpgsql
STABLE
LEAKPROOF
SECURITY DEFINER;

ALTER FUNCTION pr_grapher.list_wh_nagios_graphs() OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.list_wh_nagios_graphs() FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.list_wh_nagios_graphs() TO opm_roles;

COMMENT ON FUNCTION pr_grapher.list_wh_nagios_graphs()
    IS 'List all graphs related to warehouse wh_nagios.' ;

/* pr_grapher.list_wh_nagios_labels(bigint)
Return every wh_nagios's labels used in all graphs that current user is granted.
*/
CREATE OR REPLACE FUNCTION pr_grapher.list_wh_nagios_labels(p_id_graph bigint)
RETURNS TABLE (id_graph bigint, id_label bigint, label text, unit text,
    id_service bigint, available boolean )
AS $$
BEGIN

    IF is_admin(session_user) THEN
        RETURN QUERY
            SELECT ds.id_graph, l.id AS id_label, l.label, l.unit,
                l.id_service, gs.id_graph IS NOT NULL AS available
            FROM wh_nagios.labels AS l
            JOIN (
                    SELECT DISTINCT l.id_service, gs.id_graph
                    FROM wh_nagios.labels AS l
                    JOIN pr_grapher.graph_wh_nagios AS gs
                            ON l.id = gs.id_label
                    WHERE gs.id_graph=p_id_graph
            ) AS ds
                    ON ds.id_service = l.id_service
            LEFT JOIN pr_grapher.graph_wh_nagios gs
                    ON (gs.id_label, gs.id_graph)=(l.id, ds.id_graph) ;
    ELSE
        RETURN QUERY
            SELECT ds.id_graph, l.id AS id_label, l.label, l.unit,
                l.id_service, gs.id_graph IS NOT NULL AS available
            FROM wh_nagios.labels AS l
            JOIN (
                    SELECT DISTINCT l.id_service, gs.id_graph
                    FROM wh_nagios.labels AS l
                    JOIN pr_grapher.graph_wh_nagios AS gs
                            ON l.id = gs.id_label
                    WHERE gs.id_graph=p_id_graph
                        AND EXISTS (SELECT 1
                            FROM public.list_services() ls
                            WHERE l.id_service=ls.id
                        )
            ) AS ds
                    ON ds.id_service = l.id_service
            LEFT JOIN pr_grapher.graph_wh_nagios gs
                    ON (gs.id_label, gs.id_graph)=(l.id, ds.id_graph);
    END IF;
END;
$$
LANGUAGE plpgsql
STABLE
LEAKPROOF
SECURITY DEFINER;

ALTER FUNCTION pr_grapher.list_wh_nagios_labels(bigint) OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.list_wh_nagios_labels(bigint) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.list_wh_nagios_labels(bigint) TO opm_roles;

COMMENT ON FUNCTION pr_grapher.list_wh_nagios_labels(bigint)
    IS 'List all wh_nagios''s labels used in a specific graph.';

/* pr_grapher.update_graph_labels(bigint, bigint[])
Update what are the labels associated to the given graph.

Returns 2 arrays:
  * added bigint[]: Array of added labels
  * removed bigint[]: Array of removed labels
*/
CREATE OR REPLACE FUNCTION pr_grapher.update_graph_labels( p_id_graph bigint, p_id_labels bigint[], OUT added bigint[], OUT removed bigint[])
AS $$
DECLARE
    v_result record;
    v_remove  bigint[];
    v_add     bigint[];
BEGIN
    IF NOT is_admin(session_user) THEN
        SELECT 1 FROM pr_grapher.list_wh_nagios_graphs()
        WHERE id = p_id_graph;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Graph id % does not exists or not granted.', p_id_graph;
        END IF;
    END IF;

    FOR v_result IN
        SELECT gs.id_label AS to_remove, a.id_label AS to_add
        FROM (
            SELECT id_label FROM pr_grapher.graph_wh_nagios
            WHERE id_graph = p_id_graph
        ) AS gs
        FULL JOIN (
            SELECT * FROM unnest ( p_id_labels )
        ) AS a(id_label) ON a.id_label = gs.id_label
        WHERE gs.id_label IS NULL OR a.id_label IS NULL
    LOOP
        /* if "existing" is NULL, the label should be added to the graph
         * else "given" is NULL, the label should be removed from the
         * graph
         */
        IF v_result.to_add IS NOT NULL THEN
            v_add := array_append(v_add, v_result.to_add);
        ELSE
            v_remove := array_append(v_remove, v_result.to_remove);
        END IF;
    END LOOP;

    -- Add new labels to the graph
    INSERT INTO pr_grapher.graph_wh_nagios (id_graph, id_label)
    SELECT p_id_graph, unnest(v_add);

    -- Remove labels from the graph
    PERFORM 1 FROM pr_grapher.graph_wh_nagios
    WHERE id_graph = p_id_graph FOR UPDATE;

    FOR v_result IN SELECT array_agg(id_label) AS vals, to_delete
        FROM (
                SELECT id_label, count(*) > 1 AS to_delete
                FROM pr_grapher.graph_wh_nagios
                WHERE id_label = any( v_remove ) group by id_label
        ) AS sub
        GROUP BY to_delete
    LOOP
        IF v_result.to_delete THEN
            DELETE FROM pr_grapher.graph_wh_nagios
            WHERE id_label = any( v_result.vals )
                AND id_graph = p_id_graph;
        ELSE
            UPDATE pr_grapher.graph_wh_nagios SET id_graph = NULL
            WHERE id_label = any( v_result.vals )
                AND id_graph = p_id_graph;
        END IF;
    END LOOP;

    added := v_add; removed := v_remove;
END
$$
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER;

ALTER FUNCTION pr_grapher.update_graph_labels(bigint, bigint[]) OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.update_graph_labels(bigint, bigint[]) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.update_graph_labels(bigint, bigint[]) TO opm_roles;
COMMENT ON FUNCTION pr_grapher.update_graph_labels(bigint, bigint[]) IS 'Update what are the labels associated to the given graph.' ;
