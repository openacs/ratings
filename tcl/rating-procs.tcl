# /packages/cop-base/tcl/ratings-procs.tcl
ad_library {
    TCL library for multidimensional ratings

    @author Jeff Davis <davis@xarg.net>

    @creation-date 10/23/2003
    @cvs-id $Id$
}

namespace eval ratings {}
namespace eval ratings::aggregates {}
namespace eval ratings::dimensions {}

ad_proc -public ratings::aggregates::get {
    {-dimension_key "quality"}
    -object_id
} {
    returns array set ratings info for ratings on the given
    object_id along dimension dimension_key

    @param dimension_key
    @param object_id 

    @return array set info on ratings for object $object_id

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01-30
} {
    array set dim [ratings::dimensions::get -dimension_key $dimension_key]
    set dimension_id $dim(dimension_id)

    if { [db_0or1row get_ratings { 
        SELECT rating_ave, rating_sum, ratings 
        FROM rating_aggregates 
        WHERE dimension_id = :dimension_id
        and object_id = :object_id } -column_array ret] } {
        return [array get ret]
    } else { 
        return {}
    }
}

ad_proc -public ratings::get {
    {-dimension_key "quality"}
    -object_id
    -user_id
} {
    Returns the rating given by the passed in user.

    @return the rating or empty string if unrated.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01-30
} {
    if {![empty_string_p $object_id]} {
        return [db_string get_rating { 
            SELECT rating 
            FROM ratings
            WHERE dimension_id = (select dimension_id from rating_dimensions where dimension_key = :dimension_key) 
              and object_id = :object_id
              and owner_id = :user_id} -default {} ]
    } else {
        error "ratings::get: no object_id provided"
    }
}


ad_proc -public ratings::dimensions::get {
    -dimension_key
} {
    Retrieve the dimension data for the given dimension_key

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01
} {
    db_1row get {select * from rating_dimensions where dimension_key = :dimension_key} -column_array ret

    return [array get ret]
}



ad_proc -public ratings::form {
    {-dimension_key "quality"}
    {-user_id {}}
    {-return_url {}}
    -object_id 
} {
    Create a rating widget; returns an html fragment with the form defined.
    should be an include.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01-30
} {
    array set dim [ratings::dimensions::get -dimension_key $dimension_key] 

    if {![info exists dim(dimension_key)]} {
        error "ratings::widget: invalid dimension_key $dimension_key"
    }

    if {![empty_string_p $object_id]
        && [empty_string_p $user_id]} {
        set user_id [ad_conn user_id]
    }

    if {![empty_string_p $object_id]} {
        set rating [ratings::get \
                        -dimension_key $dimension_key \
                        -object_id $object_id \
                        -user_id $user_id ]
    } else {
        set rating {}
    }

    if {[empty_string_p $return_url]} {
        set return_url [ad_return_url]
    }

    set out "<form style=\"display: inline\" action=\"/ratings/rate\">\n[export_vars -form {object_id dimension_key return_url}]<select name=\"rating\">\n"
    for {set i $dim(range_low)} {$i <= $dim(range_high) && $dim(range_high) != $dim(range_low)} {incr i [expr {2*($dim(range_high) - $dim(range_low) > 0)-1}]} {
        if {$rating eq $i} {
            append out "<option value=\"$i\" selected=\"selected\">"
        } else {
            append out "<option value=\"$i\">"
        }
        if {$dim(range_low) eq $i && ![empty_string_p $dim(label_low)]} { 
            append out "$i - $dim(label_low)"
        } elseif  {$dim(range_high) eq $i && ![empty_string_p $dim(label_high)]} { 
            append out "$i - $dim(label_high)"
        } else { 
            append out $i
        }
        append out "</option>\n"
    }
    if {![empty_string_p $rating]} { 
        append out "\n</select>\n<input type=\"submit\" value=\"Change\"></form>\n"
    } else {
        append out "\n</select>\n<input type=\"submit\" value=\"Rate\"></form>\n"
    }
}


ad_proc -public ratings::rate {
    {-dimension_key "quality"}
    -object_id
    -user_id
    -rating
} {
    Sets the rating for object_id for user user_id.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01-30
} {
    array set dim [ratings::dimensions::get -dimension_key $dimension_key]
    set dimension_id $dim(dimension_id)

    set vars [list \
                  [list dimension_id $dimension_id] \
                  [list object_id $object_id] \
                  [list rating $rating] \
                  [list title "Rating $dimension_key by $user_id on $object_id"] \
                  [list package_id [ad_conn package_id]] \
                  [list user_id $user_id] \
                  [list ip [ad_conn peeraddr]] \
                 ]

    package_exec_plsql -var_list $vars rating rate
}

ad_proc -public ratings::icon_base {} {
    return the base url for the rating icons
} {
    return /resources/ratings/big/
}
