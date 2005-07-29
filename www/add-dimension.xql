<?xml version="1.0"?>
<queryset>

<fullquery name="check_key">
    <querytext>
	select
		1
	from
		rating_dimensions
	where
		dimension_key = :dimension_key
    </querytext>
</fullquery>

<fullquery name="dimensions">
    <querytext>
	select 
		* 
	from 
		rating_dimensions
	order by dimension_key asc
    </querytext>
</fullquery>

</queryset>