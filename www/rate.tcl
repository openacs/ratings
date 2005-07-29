# /packages/ratings/www/rate
ad_page_contract {
    Save a rating provided by a user.

    @author Jeff Davis davis@xarg.net

    @creation-date 10/30/2003
    @cvs-id $Id$
} {
    object_id:integer,notnull
    dimension_key:notnull
    rating:integer,notnull
    {return_url:trim {}}
    {nomem_p "f"}
    {context_object_id ""}
}


set user_id [auth::require_login]



set rating_id [ratings::rate -dimension_key $dimension_key \
                   -object_id $object_id \
                   -user_id $user_id \
                   -rating $rating \
		   -nomem_p $nomem_p]

if { ![empty_string_p $context_object_id] } {
    db_dml update_context_id { update ratings set context_object_id = :context_object_id where rating_id = :rating_id }
}

if {[empty_string_p $return_url]} { 
    set return_url [get_referrer]
}

ad_returnredirect -message "Your rating is now $rating for this item $dimension_key." $return_url
