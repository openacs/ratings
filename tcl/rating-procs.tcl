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
    -object_id:required
    -user_id:required
    -rating:required
    {-nomem_p "f"}
} {
    Sets the rating for object_id for user user_id.

    @author Jeff Davis davis@xarg.net
    @creation-date 2004-01-30
} {
    if { $nomem_p } {
	array set dim [ratings::dimensions::get_nomem $dimension_key]
    } else {
	array set dim [ratings::dimensions::get -dimension_key $dimension_key]
    }

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

ad_proc -public ratings::dimension_form { 
    -object_id:required
    {-dimensions_key_list ""}
    {-return_url ""}
    {-context_object_id ""}
} {
    Returns a form to include on an adp page, displaying a group of stars with a checkbox acording to the max and
    min ranges especified when creating the dimension. If dimension_key_list is not provided then it will create a form
    with all dimensions. If it is provided then it will create a form for just the dimension_key's on the list. 

    @param object_id The object you want to rate.
    @param dimension_key_list the rating dimension_key's.
    @param return_url The url to return after the form is submited.
    @param context_object_id The context object to group ratings.

    @author Miguel Marin  (miguelmarin@viaro.net)
    @creation-date 2005-07-29
} {
    set output ""
    set dimensions_num [llength $dimensions_key_list]
    # For each dimension we receive, we are going to use it's value to restrict the query
    if { [expr [llength $dimensions_key_list] > 1] } {
	set dimensions_query "("
	foreach item $dimensions_key_list {
	    append dimensions_query "'"
	    append dimensions_query "$item',"
	}
	append dimensions_query "'[lindex $dimensions_key_list 0]')"
	set extra_query "where dimension_key in $dimensions_query"
    } elseif {[string equal [llength $dimensions_key_list] 1] } {
	set extra_query "where dimension_key = '$dimensions_key_list'"
    } else {
	set extra_query ""
    }
    
    set count 0
    # For each dimension we create a new form to rate all dimensions.
    append output "<table><tr>"
    db_foreach get_dimensions " " {
	append output "<form name=\"rate_dimensions_$count\" action=\"/ratings/rate\" method=\"post\">"
	append output "<td valign=top>"
	append output "<input type=\"hidden\" name=\"dimension_key\" value=\"$dimension_key\">"
	append output "<input type=\"hidden\" name=\"object_id\" value=\"$object_id\">"
	append output "<input type=\"hidden\" name=\"context_object_id\" value=\"$context_object_id\">"
	append output "<input type=\"hidden\" name=\"nomem_p\" value=\"t\">"
	append output "<input type=\"hidden\" name=\"return_url\" value=\"$return_url\">"
	append output "<b>${title}:</b><br><br>"
	# We create the options using the values specified when the dimension was created.
	for { set i $range_low } { $i <= $range_high } { incr i } {
	    append output "<input type=\"radio\" name=\"${dimension_key}-${object_id}\" value=\"$i\""
	    set prev_rating [ratings::get_rating -object_id $object_id -dimension_key $dimension_key]
	    if { [string equal $i $prev_rating] } {
		append output " checked>"
	    } else {
		append output ">"		
	    }	
	    append output "[ratings::icon::html_fragment -icon_key stars -rating $i]<br>"
	}
	append output "<br><input type=\"Submit\" value=\"Rate\"></form>"
	append output "</td><td>&nbsp;&nbsp;&nbsp;&nbsp;</td>"
	incr count
    }

    append output "</tr></table>"
    return $output
}

ad_proc -public ratings::dimension_ad_form_element { 
    -object_id:required
    -dimension_key:required
    {-label ""}
    {-section ""}
} {
    Returns an element to use on ad_form with the -extend switch, displaying a group of stars with a radio button
    acording to the max and  min ranges especified when creating the dimension. The name of the element will be
    object_id.dimension_key.

    @param object_id The object you want to rate.
    @param dimension_key the rating dimension_key's.
    @param label The label of the element. Default to Dimension Title
    @param section The section of the element. Default to ""

    @author Miguel Marin (miguelmarin@viaro.net)
    @creation-date 2005-08-01
} {
   
    set element "{$object_id"
    append element ".$dimension_key:text(radio) "
    append element "{label $label} "
    append element "{section $section} "
    append element "{options {"

    db_1row get_dimension_info { }
    for { set i $range_low } { $i <= $range_high } { incr i } {
	append element "{{[ratings::icon::html_fragment -icon_key stars -rating $i]} $i } "
    }
    # This Close the options
    append element "}} "

    # Select the element value, if it has one
    append element "{ value [ratings::get_rating -object_id $object_id -dimension_key $dimension_key]} "

    # This Close the element
    append element "}"

    return $element
}

ad_proc -public ratings::get_available_dimensions {
    
} {
    Returns a list of all available dimensions of the form { dimension_key title }.
    All dimensions_key in rating_dimensions table.

    @author Miguel Marin  (miguelmarin@viaro.net)
    @creation-date 2005-08-01
} {
    return [db_list_of_lists get_all_dimensions { }]
}


ad_proc -public ratings::get_list {
    {-context_object_id ""}
    -object_id:required
} {
    Returns a list of elements of the form { rating_id value } for one object_id. If context_object_id
    was provided then returns the pairs in that context_id, else, it returns all pairs for
    that object_id.

    @param context_object_id The object_id that groups diferent ratings.
    @param object_id The object_id that was rated.
    @return the list { rating_id value } for the object_id.

    @author Miguel Marin  (miguelmarin@viaro.net)
    @creation-date 2005-07-29
} {
    set extra_query ""
    if { ![empty_string_p $context_object_id] } {
	set extra_query "and context_object_id = $context_object_id"
    }
    return [db_list_of_lists get_rating_id " "]
}

ad_proc -public ratings::get_average {
    {-context_object_id ""}
    -object_id:required
    {-dimension_key ""}
} {
    Returns the average rating for one on the same context_object_id and object_id. If dimension_key is specified
    then returns only the average for that dimension.

    @param context_object_id The object_id that groups diferent ratings.
    @param object_id The object_id that was rated.
    @param dimension_key The dimension to get the average.
    @returns a average rating value.

    @author Miguel Marin  (miguelmarin@viaro.net)
    @creation-date 2005-07-29
} {
    set extra_query ""
    if { ![empty_string_p $dimension_key] } {
	append extra_query "and dimension_id = ( select dimension_id from rating_dimensions where dimension_key = '$dimension_key' )"
    }
    if { ![empty_string_p $context_object_id] } {
	append extra_query "and context_object_id = :context_object_id"
    }

    return [db_string get_average_rating " "]
}


ad_proc -public ratings::get_rating {
    -object_id:required
    -dimension_key:required
    {-owner_id ""}
} {
    Returns the rate for one object_id made by the owner_id for one dimension_key, empty string other wise.

    @param object_id The object that was rated.
    @param dimension_key The dimension key used for rate the object.
    @param owner_id The id of the user that rated the object_id. Default to logged user
    @returns the rating for that object_id

    @author Miguel Marin  (miguelmarin@viaro.net)
    @creation-date 2005-08-01
} {
    if { [empty_string_p $owner_id] } {
	set owner_id [ad_conn user_id]
    }
    return [db_string get_rating { } -default ""]
}