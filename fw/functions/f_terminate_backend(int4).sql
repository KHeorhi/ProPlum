CREATE OR REPLACE FUNCTION ${target_schema}.f_terminate_backend(p_pid int4)
	RETURNS bool
	LANGUAGE plpgsql
	SECURITY DEFINER
	VOLATILE
AS $$
	
	/*Ismailov Dmitry
    * Sapiens Solutions 
    * 2023*/
/*function terminate process by pid */
DECLARE
  v_location text := '${target_schema}.f_terminate_backend';
  v_error    text;
  v_res      bool;
 begin 
   execute 'SELECT pg_catalog.pg_terminate_backend('||p_pid||')' into v_res;
   return v_res;
   exception when others then 
    v_error = 'ERROR while termitate pid '||coalesce(p_pid::text,'<NULL>')||': '||SQLERRM;
    raise notice '%',v_error;
    PERFORM ${target_schema}.f_write_log('ERROR', v_error, v_location);
    return null;
 end;

$$
EXECUTE ON ANY;

-- Permissions

ALTER FUNCTION ${target_schema}.f_terminate_backend(int4) OWNER TO "${owner}";
GRANT ALL ON FUNCTION ${target_schema}.f_terminate_backend(int4) TO public;
GRANT ALL ON FUNCTION ${target_schema}.f_terminate_backend(int4) TO "${owner}";
