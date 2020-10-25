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

create function ratings_ins_tr () returns trigger as '
begin
    if not exists (
        SELECT 1
          FROM rating_aggregates
         WHERE dimension_id = new.dimension_id
           and object_id = new.object_id ) then

        if new.owner_id = 0 then
            INSERT  INTO rating_aggregates (dimension_id, object_id, all_ratings, all_rating_sum, all_rating_ave, 
                anon_ratings, anon_rating_sum, anon_rating_ave, reg_ratings, reg_rating_sum, reg_rating_ave, rated_on)
            VALUES (new.dimension_id, new.object_id, 1, new.rating, new.rating, 
                0, 0, 0, 1, new.rating, new.rating, now());
        else
            INSERT  INTO rating_aggregates (dimension_id, object_id, all_ratings, all_rating_sum, all_rating_ave, 
                anon_ratings, anon_rating_sum, anon_rating_ave, reg_ratings, reg_rating_sum, reg_rating_ave, rated_on)
            VALUES (new.dimension_id, new.object_id, 1, new.rating, new.rating, 
                1, new.rating, new.rating, 0, 0, 0, now());
        end if;

    else

        if new.owner_id = 0 then
            UPDATE rating_aggregates
               SET all_ratings = all_ratings + 1, all_rating_sum = all_rating_sum + new.rating,
                   all_rating_ave = 1.0*(all_rating_sum + new.rating)/(all_ratings + 1), 
                   anon_ratings = anon_ratings + 1, anon_rating_sum = anon_rating_sum + new.rating,
                   anon_rating_ave = 1.0*(anon_rating_sum + new.rating)/(anon_ratings + 1), 
                   rated_on = now()
             WHERE dimension_id = new.dimension_id
               and object_id = new.object_id;
        else
            UPDATE rating_aggregates
               SET all_ratings = all_ratings + 1, all_rating_sum = all_rating_sum + new.rating,
                   all_rating_ave = 1.0*(all_rating_sum + new.rating)/(all_ratings + 1), 
                   reg_ratings = reg_ratings + 1, reg_rating_sum = reg_rating_sum + new.rating,
                   reg_rating_ave = 1.0*(reg_rating_sum + new.rating)/(reg_ratings + 1), 
                   rated_on = now()
             WHERE dimension_id = new.dimension_id
               and object_id = new.object_id;
        end if;
    end if;

    return new;
end;' language 'plpgsql';

create trigger ratings_ins_tr
after insert on ratings
for each row
execute procedure ratings_ins_tr();

create function ratings_upd_tr () returns trigger as '
begin
    -- We first subtract the old, then add the new, in case owner_id, dimension_id or object_id was changed.

    if old.owner_id = 0 then
        UPDATE rating_aggregates 
           SET all_ratings = (case when all_ratings > 0 then all_ratings - 1 else 0 end),
               all_rating_sum = (case when all_rating_sum - coalesce(old.rating,1) > 0 then all_rating_sum - coalesce(old.rating,1) else 0 end),
               all_rating_ave = 1.0*(all_rating_sum - coalesce(old.rating,1))/(case when all_ratings > 1 then all_ratings - 1 else 1 end),
               anon_ratings = (case when anon_ratings > 0 then anon_ratings - 1 else 0 end),
               anon_rating_sum = (case when anon_rating_sum - coalesce(old.rating,1) > 0 then anon_rating_sum - coalesce(old.rating,1) else 0 end),
               anon_rating_ave = 1.0*(anon_rating_sum - coalesce(old.rating,1))/(case when anon_ratings > 1 then anon_ratings - 1 else 1 end)
         WHERE dimension_id = old.dimension_id 
           and object_id = old.object_id;
    else
        UPDATE rating_aggregates 
           SET all_ratings = (case when all_ratings > 0 then all_ratings - 1 else 0 end),
               all_rating_sum = (case when all_rating_sum - coalesce(old.rating,1) > 0 then all_rating_sum - coalesce(old.rating,1) else 0 end),
               all_rating_ave = 1.0*(all_rating_sum - coalesce(old.rating,1))/(case when all_ratings > 1 then all_ratings - 1 else 1 end),
               reg_ratings = (case when reg_ratings > 0 then reg_ratings - 1 else 0 end),
               reg_rating_sum = (case when reg_rating_sum - coalesce(old.rating,1) > 0 then reg_rating_sum - coalesce(old.rating,1) else 0 end),
               reg_rating_ave = 1.0*(reg_rating_sum - coalesce(old.rating,1))/(case when reg_ratings > 1 then reg_ratings - 1 else 1 end)
         WHERE dimension_id = old.dimension_id 
           and object_id = old.object_id;
    end if;

    if new.owner_id = 0 then
        UPDATE rating_aggregates
           SET all_ratings = all_ratings + 1,
               all_rating_sum = all_rating_sum + coalesce(new.rating,1),
               all_rating_ave = 1.0*(all_rating_sum + coalesce(new.rating,1))/(all_ratings + 1),
               anon_ratings = anon_ratings + 1,
               anon_rating_sum = anon_rating_sum + coalesce(new.rating,1),
               anon_rating_ave = 1.0*(anon_rating_sum + coalesce(new.rating,1))/(anon_ratings + 1),
               rated_on = now()
         WHERE dimension_id = new.dimension_id
           and object_id = new.object_id;
    else        
        UPDATE rating_aggregates
           SET all_ratings = all_ratings + 1,
               all_rating_sum = all_rating_sum + coalesce(new.rating,1),
               all_rating_ave = 1.0*(all_rating_sum + coalesce(new.rating,1))/(all_ratings + 1),
               reg_ratings = reg_ratings + 1,
               reg_rating_sum = reg_rating_sum + coalesce(new.rating,1),
               reg_rating_ave = 1.0*(reg_rating_sum + coalesce(new.rating,1))/(reg_ratings + 1),
               rated_on = now()
         WHERE dimension_id = new.dimension_id
           and object_id = new.object_id;
    end if;
    return new;

end;' language 'plpgsql';

create trigger ratings_upd_tr
after update on ratings
for each row
execute procedure ratings_upd_tr();

-- drop function ratings_del_tr() cascade;
create function ratings_del_tr () returns trigger as '
begin
    if old.owner_id = 0 then
        UPDATE rating_aggregates 
           SET all_ratings = (case when all_ratings > 0 then all_ratings - 1 else 0 end),
               all_rating_sum = (case when all_rating_sum - coalesce(old.rating,1) > 0 then all_rating_sum - coalesce(old.rating,1) else 0 end),
               all_rating_ave = 1.0*(all_rating_sum - coalesce(old.rating,1))/(case when all_ratings > 1 then all_ratings - 1 else 1 end),
               anon_ratings = (case when anon_ratings > 0 then anon_ratings - 1 else 0 end),
               anon_rating_sum = (case when anon_rating_sum - coalesce(old.rating,1) > 0 then anon_rating_sum - coalesce(old.rating,1) else 0 end),
               anon_rating_ave = 1.0*(anon_rating_sum - coalesce(old.rating,1))/(case when anon_ratings > 1 then anon_ratings - 1 else 1 end)
         WHERE dimension_id = old.dimension_id 
           and object_id = old.object_id;
    else
        UPDATE rating_aggregates 
           SET all_ratings = (case when all_ratings > 0 then all_ratings - 1 else 0 end),
               all_rating_sum = (case when all_rating_sum - coalesce(old.rating,1) > 0 then all_rating_sum - coalesce(old.rating,1) else 0 end),
               all_rating_ave = 1.0*(all_rating_sum - coalesce(old.rating,1))/(case when all_ratings > 1 then all_ratings - 1 else 1 end),
               reg_ratings = (case when reg_ratings > 0 then reg_ratings - 1 else 0 end),
               reg_rating_sum = (case when reg_rating_sum - coalesce(old.rating,1) > 0 then reg_rating_sum - coalesce(old.rating,1) else 0 end),
               reg_rating_ave = 1.0*(reg_rating_sum - coalesce(old.rating,1))/(case when reg_ratings > 1 then reg_ratings - 1 else 1 end)
         WHERE dimension_id = old.dimension_id 
           and object_id = old.object_id;
    end if;

    return old;
end;' language 'plpgsql';

create trigger ratings_del_tr
after delete on ratings
for each row
execute procedure ratings_del_tr();
