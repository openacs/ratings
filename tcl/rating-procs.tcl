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
namespace eval ratings::icon {}

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
        SELECT r.*
        FROM rating_aggregates r
        WHERE r.dimension_id = :dimension_id
          and r.object_id = :object_id } -column_array ret] } {
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


ad_proc -private ratings::dimensions::get_nomem { 
    dimension_key
} {
    Retrieve the dimension data for the given dimension_key.  Not memoized.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01
} {
    db_1row get {select * from rating_dimensions where dimension_key = :dimension_key} -column_array ret
    set ret(icon_key) stars

    return [array get ret]
}


ad_proc -public ratings::dimensions::get {
    -dimension_key
} {
    Retrieve the dimension data for the given dimension_key [memoized]

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01
} {
    return [util_memoize [list ratings::dimensions::get_nomem $dimension_key]]
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

    set out "<form style=\"display: inline\" action=\"/ratings/rate\">\n<div>[export_vars -form {object_id dimension_key return_url}]<select name=\"rating\">\n"
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
        append out "\n</select>\n<input type=\"submit\" value=\"Change\"></div></form>\n"
    } else {
        append out "\n</select>\n<input type=\"submit\" value=\"Rate\"></div></form>\n"
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

    return [package_exec_plsql -var_list $vars rating rate]
}

ad_proc -public ratings::icon::get {
    -icon_key
} {
    Returns the information for rendering a rating icon

    @param icon_key the string that identifies an icon set (currently stars, lstars, or wp).

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-05-20
} {
    switch -exact -- $icon_key {
        stars {
            return {
                name {Stars}
                min 0.5
                max 5.0
                round 2.0
                width 64
                height 12
                format "%.1f"
                eval {<image src="/resources/ratings/stars/s-${normalized}.gif" alt="$normalized stars" width="64" height="12" class="rating" />}
            }
        }
        lstars {
            return {
                name {Stars}
                min 0.5
                max 5.0
                round 2.0
                width 77
                height 17
                format "%.1f"
                eval {<image src="/resources/ratings/lstars/s-${normalized}.gif" alt="$normalized stars" width="77" height="17" class="rating" />}
            }
        }
        wp {
            return {
                name {Bars}
                min 0
                max 9
                round 1
                width 100
                height 10
                format "%1.0f"
                eval {<image src="/resources/ratings/wp/${normalized}.gif" alt="rating $normalized" width="64" height="12" class="rating" />}
            }
        }
        default {
            error "ratings::icon::get: unknown icon_key $icon_key"
        }
    }
}

ad_proc -public ratings::icon::html_fragment {
    {-dimension_key "quality"}
    {-icon_key {}}
    -rating 
} {
    return the an html fragment for a rating icon.  

    If dimension key is provided the rating will be normalized to the icon
    range, if it is not then it will just be used (rounded and clipped if
    necessary).

    @param dimension_key the rating dimension key
    @param icon_key overide the default icon key for the given dimension_key
                    or required if dimension_key not provided.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-05-20
} {
    if {![empty_string_p $dimension_key]} {
        array set dim [ratings::dimensions::get -dimension_key $dimension_key]
    }
    if {[empty_string_p $icon_key]} {
        if {[info exists dim(icon_key)]} {
            set icon_key $dim(icon_key)
        } else {
            error "ratings::icon_fragment: provide either icon_key and/or dimension_key"
        }
    }

    array set icon [ratings::icon::get -icon_key $icon_key]

    set normalized [format $icon(format) [expr {(round($icon(round)*$rating))/$icon(round)}]]
    if {$normalized < $icon(min)} {
        set normalized $icon(min)
    }
    if {$normalized > $icon(max)} {
        set normalized $icon(max)
    }

    return [subst $icon(eval)]
}




