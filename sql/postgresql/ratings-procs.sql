-- Ratings
--
-- PL/pgSQL procs for the simple multidimensional ratings package.
-- 
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis <davis@xarg.net>
-- @creation-date 10/22/2003
--
-- @cvs-id $Id$
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

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

select define_function_args('rating_dimension__new','dimension_id,title,dimension_key,description,range_low,range_high,label_low,label_high,package_id,creation_date,creation_user,creation_ip,context_id');

-- simple api for initial populate.
create or replace function rating_dimension__new (varchar,varchar,varchar,integer,integer,varchar,varchar)
returns integer as '
declare
  p_title                               alias for $1;
  p_dimension_key                       alias for $2;
  p_description                         alias for $3;
  p_range_low                           alias for $4;
  p_range_high                          alias for $5;
  p_label_low                           alias for $6;
  p_label_high                          alias for $7;
begin
    return rating_dimension__new(null,p_title,p_dimension_key,p_description,p_range_low,p_range_high,p_label_low,p_label_high,null,now(),null,null,null);
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

create or replace function rating_dimension__title (integer)
returns varchar as '
declare
    p_dimension_id        alias for $1;
    v_title           varchar;
begin
    SELECT title into v_title
      FROM acs_objects
     WHERE object_id = p_dimension_id 
       and object_type = ''rating_dimension'';

    return v_title;
end;
' language 'plpgsql';

select define_function_args('rating_dimension__title','dimension_id');


create or replace function rating__new (integer,integer,integer,integer,varchar,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
    p_rating_id                 alias for $1;
    p_dimension_id              alias for $2;
    p_object_id                 alias for $3;
    p_rating                    alias for $4;
    p_title                     alias for $5;
    p_package_id                alias for $6;
    p_creation_date             alias for $7;
    p_creation_user             alias for $8;
    p_creation_ip               alias for $9;
    p_context_id                alias for $10;
    v_rating_id                                     ratings.rating_id%TYPE;
begin
    v_rating_id := acs_object__new (
                           p_rating_id,
                           ''rating'',
                           p_creation_date,
                           p_creation_user,
                           p_creation_ip,
                           p_context_id,
                           ''t'');

    INSERT INTO ratings (rating_id,dimension_id,object_id,rating,owner_id)
    VALUES (v_rating_id,p_dimension_id,p_object_id,p_rating,p_creation_user);

    return v_rating_id;
end;' language 'plpgsql';

select define_function_args('rating__new','rating_id,dimension_id,object_id,rating,title,package_id,creation_date,creation_user,creation_ip,context_id');

create or replace function rating__delete (integer)
returns integer as '
declare
  p_rating_id                             alias for $1;
begin
    if exists (select 1 from acs_objects where object_id = p_rating_id and object_type = ''rating'') then 
        delete from acs_permissions
            where object_id = p_rating_id;

        -- we can just rely on the cascade in ratings, and the triggers for updating averages.
        PERFORM acs_object__delete(p_rating_id);

        return 0;
    else
        raise NOTICE ''rating__delete object_id % does not exist or is not a rating'',p_rating_id;
        return -1;
    end if;
end;' language 'plpgsql';

select define_function_args('rating__delete','rating_id');

create or replace function rating__title (integer)
returns varchar as '
declare
    p_rating_id        alias for $1;
    v_title           varchar;
begin
    SELECT title into v_title
      FROM acs_objects
     WHERE object_id = p_rating_id 
       and object_type = ''rating'';

    return v_title;
end;' language 'plpgsql';

select define_function_args('rating__title','rating_id');

create or replace function rating__rate(integer,integer,integer,varchar,integer,timestamptz,integer,varchar,integer)
returns integer as '
declare
    p_dimension_id              alias for $1;
    p_object_id                 alias for $2;
    p_rating                    alias for $3;
    p_title                     alias for $4;
    p_package_id                alias for $5;
    p_date                      alias for $6;
    p_user                      alias for $7;
    p_ip                        alias for $8;
    p_context_id                alias for $9;
    v_rating_id                                     ratings.rating_id%TYPE;
begin
    if p_user = 0 then
        v_rating_id := null;
    else
        SELECT rating_id into v_rating_id
          FROM ratings
         WHERE dimension_id = p_dimension_id
           and object_id = p_object_id
           and owner_id = p_user;
    end if;

    if v_rating_id is null then
        v_rating_id := rating__new(null, p_dimension_id, p_object_id, p_rating, p_title, p_package_id, p_date, p_user, p_ip, p_context_id);
    else
        UPDATE ratings
           SET rating = p_rating
         WHERE rating_id = v_rating_id;

        UPDATE acs_objects
           SET last_modified = coalesce(p_date,now()), modifying_user = p_user, modifying_ip = p_ip
         WHERE object_id = v_rating_id;
    end if;

    return v_rating_id;
end;' language 'plpgsql';

select define_function_args('rating__rate','dimension_id,object_id,rating,title,package_id,rated_on;now(),user_id,ip,context_id');
