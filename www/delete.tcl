# /packages/cop-ui/www/clipboard/attach.tcl
ad_page_contract {
    Delete a rating.

    @author Jeff Davis davis@xarg.net
    @creation-date 10/30/2003
    @cvs-id $Id$
} {
    rating_id:multiple,integer,notnull
}

set user_id [auth::require_login]

db_list nuke "
   SELECT cop_rating__delete(rating_id) 
     FROM cop_ratings
    WHERE rating_id in ([join $rating_id ,])
      and acs_permission__permission_p(rating_id,:user_id,'write') = 't'"

ad_returnredirect [get_referrer]