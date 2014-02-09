-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION pr_grapher" to load this file. \quit

-- This program is open source, licensed under the PostgreSQL License.
-- For license terms, see the LICENSE file.
--
-- Copyright (C) 2012-2014: Open PostgreSQL Monitoring Development Group

SET statement_timeout TO 0;

-- js_time: Convert the input date to ms (UTC), suitable for javascript
CREATE OR REPLACE FUNCTION pr_grapher.js_time(timestamptz)
RETURNS bigint
AS $$
SELECT (extract(epoch FROM $1)*1000)::bigint;
$$
LANGUAGE SQL
IMMUTABLE;

ALTER FUNCTION pr_grapher.js_time(timestamptz) OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.js_time(timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.js_time(timestamptz) TO opm_roles;
COMMENT ON FUNCTION pr_grapher.js_time(timestamptz) IS 'Return a timestamp without time zone formatted for javascript use.' ;

-- js_timetz: Convert the input date to ms (with timezone), suitable for javascript
CREATE OR REPLACE FUNCTION pr_grapher.js_timetz(timestamptz)
RETURNS bigint
AS $$
SELECT ((extract(epoch FROM $1) + extract(timezone FROM $1))*1000)::bigint;
$$
LANGUAGE SQL
IMMUTABLE;

ALTER FUNCTION pr_grapher.js_timetz(timestamptz) OWNER TO opm;
REVOKE ALL ON FUNCTION pr_grapher.js_timetz(timestamptz) FROM public;
GRANT EXECUTE ON FUNCTION pr_grapher.js_timetz(timestamptz) TO opm_roles;
COMMENT ON FUNCTION pr_grapher.js_timetz(timestamptz) IS 'Return a timestamp with time zone formatted for javascript use.' ;

/* pr_grapher.delete_graph(bigint)
Delete a specific graph.
@id : unique identifier of graph to delete.
@return : true if everything went well, false otherwise or if graph doesn't exists

*/
CREATE OR REPLACE FUNCTION pr_grapher.delete_graph(p_id bigint)
RETURNS boolean
AS $$
DECLARE
        v_state      text ;
        v_msg        text ;
        v_detail     text ;
        v_hint       text ;
        v_context    text ;
        v_exists     boolean ;
BEGIN
    SELECT count(*) = 1 INTO v_exists FROM pr_grapher.graphs WHERE id = p_id ;
    IF NOT v_exists THEN
        RETURN false ;
    END IF ;
    DELETE FROM pr_grapher.graphs WHERE id = p_id ;
    RETURN true;
EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            v_state   = RETURNED_SQLSTATE,
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_hint    = PG_EXCEPTION_HINT,
            v_context = PG_EXCEPTION_CONTEXT ;
        raise notice E'Unhandled error:
            state  : %
            message: %
            detail : %
            hint   : %
            context: %', v_state, v_msg, v_detail, v_hint, v_context ;
        RETURN false ;
END ;
$$
LANGUAGE plpgsql
VOLATILE
LEAKPROOF
SECURITY DEFINER;

ALTER FUNCTION pr_grapher.delete_graph(bigint) OWNER TO opm ;
REVOKE ALL ON FUNCTION pr_grapher.delete_graph(bigint) FROM public ;
GRANT EXECUTE ON FUNCTION pr_grapher.delete_graph(bigint) TO opm_admins ;

COMMENT ON FUNCTION pr_grapher.delete_graph(bigint)
    IS 'Delete a graph' ;

