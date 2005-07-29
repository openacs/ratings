-- Adding one column to ratings table so we can group diferent ratings to the same context object
alter table ratings add context_object_id integer;

-- Adding the column title to dimensions since is not present.
alter table rating_dimensions add title varchar(100);

-- Recreate the function to use title

create or replace function rating_dimension__new (integer,varchar,varchar,varchar,integer,integer,varchar,varchar,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
    p_dimension_id                        alias for $1;       -- default null
    p_title                               alias for $2;
    p_dimension_key                       alias for $3;
    p_description                         alias for $4;
    p_range_low                           alias for $5;
    p_range_high                          alias for $6;
    p_label_low                           alias for $7;
    p_label_high                          alias for $8;

    p_package_id                          alias for $9;
    p_creation_date                       alias for $10;       -- default now()
    p_creation_user                       alias for $11;       -- default null
    p_creation_ip                         alias for $12;       -- default null
    p_context_id                          alias for $13;       -- default null

    v_dimension_id                                     rating_dimensions.dimension_id%TYPE;
begin
    v_dimension_id := acs_object__new (
                           p_dimension_id,
                           ''rating_dimension'',
                           p_creation_date,
                           p_creation_user,
                           p_creation_ip,
                           p_context_id,
                           ''t'');

    insert into rating_dimensions (dimension_id,dimension_key,description,range_low,range_high,label_low,label_high,title)
    values (v_dimension_id,p_dimension_key,p_description,p_range_low,p_range_high,p_label_low,p_label_high,p_title);

    return v_dimension_id;

end;' language 'plpgsql';


create or replace function rating_dimension__delete (integer)
returns integer as '
declare
  p_dimension_id                             alias for $1;
begin
    if exists (select 1 from acs_objects where object_id = p_dimension_id and object_type = ''rating_dimension'') then 
        delete from acs_permissions
            where object_id = p_dimension_id;

        PERFORM acs_object__delete(p_dimension_id);

        return 0;
    else
        raise NOTICE ''rating_dimension__delete object_id % does not exist or is not a rating_dimension'',p_dimension_id;
        return 0;
    end if;

    delete from rating_dimensions where dimension_id = p_dimension_id;

end;' language 'plpgsql';


select define_function_args('rating_dimension__delete','dimension_id');

