-- drop the ratings stuff
-- 
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis davis@xarg.net
-- @creation-date 10/22/2003
--
-- @cvs-id $Id$
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html


create or replace function tmp_ratings_drop ()
returns integer as '
declare
  coll_rec RECORD;
begin
  for coll_rec in select object_id
      from acs_objects
      where object_type = ''rating_dimension''
    loop
      PERFORM acs_object__delete (coll_rec.object_id);
    end loop;



  for coll_rec in select object_id
      from acs_objects
      where object_type = ''rating''
    loop
      PERFORM acs_object__delete (coll_rec.object_id);
    end loop;

    return 1;
end; ' language 'plpgsql';

select tmp_ratings_drop ();
drop function tmp_ratings_drop ();

select acs_object_type__drop_type('rating_dimension', 'f');
select acs_object_type__drop_type('rating', 'f');

drop table rating_aggregates;
drop table ratings;
drop table rating_dimensions;

select drop_package('rating_dimension');
select drop_package('rating');

drop function ratings_upd_tr();
drop function ratings_ins_tr();
drop function ratings_del_tr();
