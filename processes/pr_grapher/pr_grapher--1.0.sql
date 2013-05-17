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
  id_service bigint not null
);
--TODO: add constraint trigger to enforce FK pr_grapher.graph_services and public.services

ALTER TABLE pr_grapher.graph_services ADD PRIMARY KEY (id_graph, id_service);
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

CREATE OR REPLACE FUNCTION pr_grapher.create_graph_for_services(OUT rc boolean)
AS $$
DECLARE
  v_state   TEXT;
  v_msg     TEXT;
  v_detail  TEXT;
  v_hint    TEXT;
  v_context TEXT;
  servicesrow public.services%rowtype;
BEGIN
  FOR servicesrow IN (SELECT s.* FROM public.services s
    LEFT JOIN pr_grapher.graph_services gs ON gs.id_service = s.id
    WHERE gs.id_service IS NULL)
  LOOP
    WITH new_graphs (id_graph) AS (
      INSERT INTO pr_grapher.graphs (graph, config)
        VALUES (servicesrow.service, '{"type": "lines"}')
        RETURNING graphs.id
    )
    INSERT INTO pr_grapher.graph_services (id_graph, id_service)
      SELECT new_graphs.id_graph, servicesrow.id
      FROM new_graphs;
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

ALTER FUNCTION pr_grapher.create_graph_for_services(OUT rc boolean) OWNER TO pgfactory;
REVOKE ALL ON FUNCTION pr_grapher.create_graph_for_services(OUT rc boolean) FROM public;
GRANT ALL ON FUNCTION pr_grapher.create_graph_for_services(OUT rc boolean) TO pgf_admins;

COMMENT ON FUNCTION pr_grapher.create_graph_for_services(OUT rc boolean) IS 'Create default graphs for all new services.'
