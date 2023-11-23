CREATE OR REPLACE FUNCTION ${target_schema}.f_get_extr_expression(p_load_id int8, p_source_table text, p_trg_table text DEFAULT NULL::text)
	RETURNS text
	LANGUAGE plpgsql
	VOLATILE
AS $$
	
	/*Ismailov Dmitry
    * Sapiens Solutions 
    * 2023*/
/*Function get extraction sql for table loading*/
DECLARE
  v_location  text := '${target_schema}.f_get_extr_expression';
  v_full_table_name text;
  v_sql text;
  v_transform jsonb;
  v_source_table text;
  v_trg_table text;
  v_where text;
BEGIN
  perform ${target_schema}.f_write_log(
     p_log_type    := 'SERVICE', 
     p_log_message := 'START Get extraction expression for load_id = '||p_load_id, 
     p_location    := v_location,
     p_load_id     := p_load_id); --log function call

  v_sql := 'select ob.object_name, ob.transform_mapping
            from ${target_schema}.load_info li, ${target_schema}.objects ob where li.object_id = ob.object_id and li.load_id = ' ||
            p_load_id::text;
  execute v_sql into v_full_table_name, v_transform;
  v_full_table_name  = ${target_schema}.f_unify_name(p_name := v_full_table_name); -- full table name
  v_source_table = ${target_schema}.f_unify_name(p_name := p_source_table); -- source table name
  v_trg_table = coalesce(${target_schema}.f_unify_name(p_name := p_trg_table),${target_schema}.f_get_delta_table_name(p_load_id := p_load_id));
  v_where := ${target_schema}.f_get_extract_where_cond(p_load_id := p_load_id);
  select 'select '|| string_agg(coalesce(v_transform->>c.column_name,c.column_name)||' '|| case when upper(c.data_type) = 'ARRAY' then '::'||c.udt_name else '' end ||' "'|| c.column_name ||'"',',' order by c.ordinal_position) ||' from '||v_source_table ||' where ('||v_where||' ) '||coalesce(v_transform->>'additional','') from information_schema.columns c 
   where c.table_schema||'.'||c.table_name = v_trg_table
   into v_sql;
 
  perform ${target_schema}.f_write_log(
     p_log_type    := 'SERVICE', 
     p_log_message := 'END Get extraction expression for load_id = '||p_load_id||', load sql is: '||coalesce(v_sql,'{empty}'), 
     p_location    := v_location,
     p_load_id     := p_load_id); --log function call
  return v_sql;
END;



$$
EXECUTE ON ANY;

-- Permissions

ALTER FUNCTION ${target_schema}.f_get_extr_expression(int8, text, text) OWNER TO "${owner}";
GRANT ALL ON FUNCTION ${target_schema}.f_get_extr_expression(int8, text, text) TO public;
GRANT ALL ON FUNCTION ${target_schema}.f_get_extr_expression(int8, text, text) TO "${owner}";
