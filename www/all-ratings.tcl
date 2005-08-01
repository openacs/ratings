# /packages/ratings/lib/ratings.tcl
ad_page_contract {
    Display all ratings

    @param object_id ratings on this object
    @param owner_id ratings by this user
    @param admin_p

} {
    {object_id ""}
    {owner_id ""}
    {admin_p 0}
}

set page_title "Watch all ratings"
set context [list $page_title]

if {![empty_string_p $object_id]} {
    append clause "and r.object_id = :object_id\n"
}

if {![empty_string_p $owner_id]} {
    append clause "and r.owner_id = :owner_id\n"
}

if {[empty_string_p "$owner_id$object_id"]} {
    append clause ""
}

set elements {
    rating_img {
        label "Rating"
        display_template "@ratings.rating_img;noquote@"
    } 
}

if {[empty_string_p $owner_id]} { 
    lappend elements name {
        label {[_ acs-subsite.Name]}
        display_template {<a href="@ratings.user_url@" title="Member page">@ratings.name@</a> (<a href="@ratings.user_ratings_url@" title="Ratings by @ratings.name@">ratings</a>)}
    } 
}

lappend elements rated {
    label "Rated"
    display_template {@ratings.rated;noquote@}
}

lappend elements object_title {
    label {Item}
    display_template {<a href="/o/@ratings.object_id@">@ratings.object_title@</a> (<a href="@ratings.object_ratings_url@">ratings</a>)}
}

lappend elements dimension_title {
    label { Dimension Title: }
    display_template {@ratings.dimension_title@ }
}

lappend elements dimension_description {
    label {Dimension Description: }
    display_template {@ratings.dimension_description@ }
}

if { 0 } { 
    lappend elements extra {
        label {Debug}
        display_template {o.title:@ratings.obj_title@ url:@ratings.url_one@ type:@ratings.object_type@}
    }
}
if {$admin_p} { 
    set bulk [list   "Delete ratings" delete]
} else { 
    set bulk {}
}



template::list::create \
    -name ratings \
    -multirow ratings \
    -key rating_id \
    -elements $elements \
    -orderby { 
        name {
            orderby_asc "lower(u.last_name),lower(u.first_names)"
            orderby_desc "lower(u.last_name) desc,lower(u.first_names) desc"
        }
        rating_img { 
            orderby_desc {rating asc, o.last_modified desc}
            orderby_asc {rating desc, o.last_modified desc}
        }
        rated { 
            orderby_desc {o.last_modified asc}
            orderby_asc {o.last_modified desc}
        }
        object_title { 
            orderby lower(o.title)
        }
    } -filters { 
        object_id {}
        owner_id {}
    } -bulk_actions $bulk

set now [clock_to_ansi [clock seconds]]
db_multirow -extend {rated rating_img user_url user_ratings_url object_ratings_url url_one} ratings ratings "
    SELECT r.rating_id, r.dimension_id, r.object_id, rd.description as dimension_description, rd.title as dimension_title, u.first_names || ' ' || u.last_name as name, u.user_id, u.email, r.owner_id, r.rating, to_char(o.last_modified,'YYYY-MM-DD HH24:MI:SS') as rated_on, acs_object__name(o2.object_id) as object_title, r.object_id, o2.title as obj_title, o2.object_type
      FROM acs_users_all u,  ratings r, acs_objects o, acs_objects o2, rating_dimensions rd
     WHERE r.owner_id = u.user_id 
       $clause
       and o.object_id = r.rating_id
       and o2.object_id = r.object_id
       and r.dimension_id = rd.dimension_id
   [template::list::orderby_clause -orderby -name "ratings"]" {
       set rating_img [ratings::icon::get_icon -rating $rating]
       set user_url [acs_community_member_url -user_id $user_id]     
       set user_ratings_url [export_vars -base ratings [list [list owner_id $user_id]]]
       set object_ratings_url [export_vars -base ratings {object_id}]
       set rated [regsub -all { } [util::age_pretty -timestamp_ansi $rated_on -sysdate_ansi $now] {\&nbsp;}]

       if {[catch {set url_one [acs_sc_call -error FtsContentProvider url [list $object_id] $object_type]} errMsg]} { 
           global errorCode
           set url_one $errorCode
       }
   }

