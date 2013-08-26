-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pr_grapher" to load this file. \quit

SET statement_timeout TO 0;

ALTER SCHEMA pr_grapher OWNER TO pgfactory;
GRANT USAGE ON SCHEMA pr_grapher TO pgf_roles;

-- Graphs
CREATE TABLE pr_grapher.graphs (
  id bigserial primary key,
  graph text not null,
  description text,
  y1_query text,
  y2_query text,
  config json
);

ALTER TABLE pr_grapher.graphs OWNER TO pgfactory;
REVOKE ALL ON TABLE pr_grapher.graphs FROM public;

-- Categories
CREATE TABLE pr_grapher.categories (
  id bigserial primary key,
  category text not null,
  description text
);

ALTER TABLE pr_grapher.categories OWNER TO pgfactory;
REVOKE ALL ON TABLE pr_grapher.categories FROM public;

-- Categories can be nested
CREATE TABLE pr_grapher.nested_categories (
  id_parent bigint not null references pr_grapher.categories (id),
  id_child bigint not null references pr_grapher.categories (id)
);

ALTER TABLE pr_grapher.nested_categories ADD PRIMARY KEY (id_parent,id_child);
ALTER TABLE pr_grapher.nested_categories OWNER TO pgfactory;
REVOKE ALL ON TABLE pr_grapher.nested_categories FROM public;


-- A graph can be in zero to many categories
CREATE TABLE pr_grapher.graph_categories (
  id_graph bigint not null references pr_grapher.graphs (id),
  id_category bigint not null references pr_grapher.categories (id)
);

ALTER TABLE pr_grapher.graph_categories ADD PRIMARY KEY (id_graph,id_category);
ALTER TABLE pr_grapher.graph_categories OWNER TO pgfactory;
REVOKE ALL ON TABLE pr_grapher.graph_categories FROM public;

-- Each series of a graph can be configured
CREATE TABLE pr_grapher.series (
  id bigserial primary key,
  label text not null,
  config json,
  id_graph bigint not null references pr_grapher.graphs (id)
);

ALTER TABLE pr_grapher.series OWNER TO pgfactory;
REVOKE ALL ON TABLE pr_grapher.series FROM public;

-- A graph can display one or more services
CREATE TABLE pr_grapher.graph_services (
  id_graph bigint not null references pr_grapher.graphs (id),
  id_label bigint not null references wh_nagios.labels (id)
);
--TODO: add constraint trigger to enforce FK pr_grapher.graph_services and public.services

ALTER TABLE pr_grapher.graph_services ADD PRIMARY KEY (id_graph, id_label);
ALTER TABLE pr_grapher.graph_services OWNER TO pgfactory;
REVOKE ALL ON TABLE pr_grapher.graph_services FROM public;

-- jstime: Convert the input date to ms from the Epoch in UTC, suitable for javascript
CREATE OR REPLACE FUNCTION pr_grapher.js_time(timestamptz) RETURNS bigint LANGUAGE 'sql' IMMUTABLE SECURITY DEFINER
AS $$
SELECT ((extract(epoch FROM $1) + extract(timezone FROM $1))*1000)::bigint;
$$;

ALTER FUNCTION pr_grapher.js_time(timestamptz) OWNER TO pgfactory;
REVOKE ALL ON FUNCTION pr_grapher.js_time(timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.js_time(timestamptz) TO pgf_roles;

-- get_categories: Get the tree of categories
CREATE OR REPLACE FUNCTION pr_grapher.get_categories() RETURNS TABLE(id bigint, category text, description text, distance integer, path bigint[]) LANGUAGE 'sql'
AS $$
WITH RECURSIVE tc(id, category, description, distance, path, cycle) AS (
  SELECT c.id, c.category, c.description, 1 as distance, array[c.id], false FROM pr_grapher.categories c LEFT JOIN pr_grapher.nested_categories n ON (c.id = n.id_child) WHERE n.id_parent IS NULL
  UNION ALL
  SELECT c.id, c.category, c.description, tc.distance + 1, path || c.id, c.id = ANY(path) FROM pr_grapher.categories c LEFT JOIN pr_grapher.nested_categories n ON (c.id = n.id_child) JOIN tc ON (tc.id = n.id_parent) WHERE NOT tc.cycle
) SELECT id, category, description, distance, path FROM tc WHERE NOT cycle ORDER BY path;
$$;

CREATE OR REPLACE FUNCTION pr_grapher.create_graph_for_services(IN p_server_id bigint, OUT rc boolean)
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

  FOR labelsrow IN (SELECT DISTINCT s.service, l.id_service, COALESCE(l.unit,'') AS unit FROM wh_nagios.services s
    JOIN wh_nagios.labels l ON s.id = l.id_service
    LEFT JOIN pr_grapher.graph_services gs ON gs.id_label = l.id
    WHERE s.id_server = p_server_id
    AND gs.id_label IS NULL)
  LOOP
    WITH new_graphs (id_graph) AS (
      INSERT INTO pr_grapher.graphs (graph, config)
        VALUES (labelsrow.service || ' (' || CASE WHEN labelsrow.unit = '' THEN 'no unit' ELSE 'in ' || labelsrow.unit END || ')', '{"type": "lines"}')
        RETURNING graphs.id
    )
    INSERT INTO pr_grapher.graph_services (id_graph, id_label)
      SELECT new_graphs.id_graph, l.id
      FROM new_graphs
      CROSS JOIN wh_nagios.labels l
      WHERE l.id_service = labelsrow.id_service
      AND COALESCE(l.unit,'') = labelsrow.unit;
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
    raise notice E'Unhandled error on pr_grapher.create_graph_for_services:
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

ALTER FUNCTION pr_grapher.create_graph_for_services(p_server_id bigint, OUT rc boolean) OWNER TO pgfactory;
REVOKE ALL ON FUNCTION pr_grapher.create_graph_for_services(p_server_id bigint, OUT rc boolean) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.create_graph_for_services(p_server_id bigint, OUT rc boolean) TO public;

COMMENT ON FUNCTION pr_grapher.create_graph_for_services(p_server_id bigint, OUT rc boolean) IS 'Create default graphs for all new services.';

/* pr_grapher.list_graph()
Return every pr_grapher.graphs%ROWTYPE a user can see

*/
CREATE OR REPLACE FUNCTION pr_grapher.list_graph() RETURNS TABLE (id bigint, graph text, description text,
  y1_query text, y2_query text, config json, id_server bigint, id_service bigint)
AS $$
DECLARE
BEGIN
    IF pg_has_role(session_user, 'pgf_admins', 'MEMBER') THEN
        RETURN QUERY SELECT  g2.id, g2.graph, g2.description, g2.y1_query, g2.y2_query, g2.config, s2.id, s1.id
            FROM ( SELECT DISTINCT g.id, l.id_service
                FROM pr_grapher.graphs g
                LEFT JOIN pr_grapher.graph_services gs ON gs.id_graph = g.id
                LEFT JOIN wh_nagios.labels l ON gs.id_label = l.id
            ) g1
            JOIN pr_grapher.graphs g2 ON g1.id = g2.id
            LEFT JOIN public.services s1 ON s1.id = g1.id_service
            LEFT JOIN public.servers s2 ON s2.id = s1.id_server;
    ELSE
        RETURN QUERY SELECT g.id, g.graph, g.description, g.y1_query, g.y2_query, g.config, s2.id_server, s2.id_service
            FROM (
                SELECT DISTINCT gs.id_graph, s1.id_server, s1.id_service
                FROM (
                    SELECT (wh_nagios.list_label(ls.id)).id_label, ls.id_server, ls.id as id_service
                    FROM public.list_services() ls
                ) s1
                JOIN pr_grapher.graph_services gs ON gs.id_label = s1.id_label
            ) s2
            JOIN pr_grapher.graphs g ON g.id = s2.id_graph;
        END IF;
END;
$$
LANGUAGE plpgsql
VOLATILE
LEAKPROOF
SECURITY DEFINER;
ALTER FUNCTION pr_grapher.list_graph() OWNER TO pgfactory;
REVOKE ALL ON FUNCTION pr_grapher.list_graph() FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.list_graph() TO pgf_roles;

COMMENT ON FUNCTION pr_grapher.list_graph()
    IS 'List all graphs';
