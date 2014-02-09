-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pr_grapher" to load this file. \quit

-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2014: Open PostgreSQL Monitoring Development Group

SET statement_timeout TO 0;

-- js_time: Convert the input date to ms (with timezone), suitable for javascript
CREATE OR REPLACE FUNCTION pr_grapher.js_time(timestamptz)
RETURNS bigint
AS $$
SELECT ((extract(epoch FROM $1) + extract(timezone FROM $1))*1000)::bigint;
$$
LANGUAGE SQL
IMMUTABLE;

ALTER FUNCTION pr_grapher.js_time(timestamptz) OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.js_time(timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.js_time(timestamptz) TO opm_roles;
COMMENT ON FUNCTION pr_grapher.js_time(timestamptz) IS 'Return a timestamp without time zone formatted for javascript use.' ;

DROP FUNCTION pr_grapher.js_timetz(timestamptz);
DROP FUNCTION pr_grapher.delete_graph(bigint) ;
