-- Ratings
--
-- Triggers for maintaining denormalized rating aggregates
--
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis <davis@xarg.net>
-- @creation-date 1/12/2003
--
-- @cvs-id $Id$
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

create function ratings_ins_tr () returns opaque as '
begin
    if not exists (
        SELECT 1
          FROM rating_aggregates
         WHERE dimension_id = new.dimension_id
           and object_id = new.object_id ) then

        INSERT  INTO rating_aggregates (dimension_id, object_id, ratings, rating_sum, rating_ave, rated_on)
        VALUES (new.dimension_id, new.object_id, 1, new.rating, new.rating, now());

    else

        UPDATE rating_aggregates
           SET ratings = ratings + 1, rating_sum = rating_sum + new.rating,
               rating_ave = (rating_sum + new.rating)/(ratings + 1), rated_on = now()
         WHERE dimension_id = new.dimension_id
           and object_id = new.object_id;

    end if;

    return new;
end;' language 'plpgsql';

create trigger ratings_ins_tr
after insert on ratings
for each row
execute procedure ratings_ins_tr();

create function ratings_upd_tr () returns opaque as '
begin
    UPDATE rating_aggregates
       SET rating_sum = rating_sum - coalesce(old.rating,1) + coalesce(new.rating,1),
           rating_ave = (rating_sum - coalesce(old.rating,1) + coalesce(new.rating,1))/ratings,
           rated_on = now()
     WHERE dimension_id = new.dimension_id
       and object_id = new.object_id;

    return new;

end;' language 'plpgsql';

create trigger ratings_upd_tr
after update on ratings
for each row
execute procedure ratings_upd_tr();

-- drop function ratings_del_tr() cascade;
create function ratings_del_tr () returns opaque as '
begin
    UPDATE rating_aggregates 
       SET ratings = (case when ratings > 0 then ratings - 1 else 0 end),
           rating_sum = (case when rating_sum - coalesce(old.rating,1) > 0 then rating_sum - coalesce(old.rating,1) else 0 end),
           rating_ave = (rating_sum - coalesce(old.rating,1))/(case when ratings > 1 then ratings - 1 else 1 end)
     WHERE dimension_id = old.dimension_id 
       and object_id = old.object_id;

    return old;
end;' language 'plpgsql';

create trigger ratings_del_tr
after delete on ratings
for each row
execute procedure ratings_del_tr();
