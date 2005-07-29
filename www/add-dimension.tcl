#packages/ratings/www/add-dimentions.tcl
ad_page_contract {
    Adds and show the existent dimension in the rating_dimensions table
    
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-06-28
} {
    
}

set page_title "Add a new Dimension"
set context [list $page_title]

ad_form -name add_dimension -form {
    dimension_id:key
    {title:text(text),optional
	{label "Dimension Title:"}
	{help_text "The Pretty name (e.g. Quality)"}
    }
    {dimension_key:text(text)
	{label "Dimension Key:"}
	{help_text "An unique identifier (e.g. quality)"}
    }
    {description:text(textarea),optional
	{label "Description:"}
	{html {rows 7 cols 30 }}
    }
    {range_low:text(text)
	{label "Low Range:"}
	{help_text "Mininum Rate for one Rating"}
	{html {size 3}}
    }
    {range_high:text(text)
	{label "High Range:"}
	{help_text "Maximun Rate for one Rating"}
	{html {size 3}}
    }
    {label_low:text(text),optional
	{label "Label for Low Range:"}
	{help_text "(e.g. Worst)"}
    }
    {label_high:text(text),optional
	{label "Label for High Range:"}
	{help_text "(e.g. Best)"}
    }
} -new_data {
    if { [db_string check_key { } -default 0] } {
	ad_return_complaint 1 "<b>This key is already present. Please type a new one.</b>"
	ad_script_abort
    }
    db_exec_plsql add_dimension { }
} -after_submit {
    ad_returnredirect "add-dimension"
}


template::list::create \
    -name dimensions \
    -multirow dimensions \
    -key dimension_id \
    -bulk_action_method post \
    -bulk_action_export_vars { } \
    -bulk_actions { Delete delete-dimension "Delete This Dimensions" } \
    -row_pretty_plural "Dimensions" \
    -elements {
	title {
	    label "Title:"
	}
	dimension_key {
	    label "Key:"
	}
	description {
	    label "Description"
	}
	range_low {
	    label "Low Range:"
	}
	range_high {
	    label "High Range:"
	}
	label_low {
	    label "Low Range Label:"
	}
	label_high {
	    label "High Range Label:"
	}
    }
    

db_multirow -extend { } dimensions dimensions {

}