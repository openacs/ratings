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
}

set user_id [auth::require_login]

ratings::rate -dimension_key $dimension_key \
    -object_id $object_id \
    -user_id $user_id \
    -rating $rating

if {[empty_string_p $return_url]} { 
    set return_url [get_referrer]
}

ad_returnredirect -message "Your rating is now $rating for this item." $return_url
