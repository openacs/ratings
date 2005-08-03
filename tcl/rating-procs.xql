<?xml version="1.0"?>
<queryset>

<fullquery name="ratings::dimension_form.get_dimensions">
   <querytext>
	select
		* 
	from 
		rating_dimensions
	$extra_query
   </querytext>
</fullquery>

<fullquery name="ratings::dimension_ad_form_element.get_dimension_info">
   <querytext>
	select
		* 
	from 
		rating_dimensions
	where 
		dimension_key = :dimension_key
   </querytext>
</fullquery>


<fullquery name="ratings::get_available_dimensions.get_all_dimensions">
   <querytext>
	select
		dimension_key,
		title
	from 
		rating_dimensions
   </querytext>
</fullquery>

<fullquery name="ratings::get_list.get_rating_id">
   <querytext>
	select
		rating_id, rating
	from 
		ratings
	where
		object_id = :object_id
	$extra_query
   </querytext>
</fullquery>

<fullquery name="ratings::get_average.get_average_rating">
   <querytext>
	select
		avg(rating::float)
	from 
		ratings
	where
		object_id = :object_id
	$extra_query
   </querytext>
</fullquery>

<fullquery name="ratings::get_rating.get_rating">
   <querytext>
	select
		rating
	from 
		ratings
	where
		object_id = :object_id
		and owner_id = :owner_id
		and dimension_id = ( select 
					    dimension_id 
				     from 
					    rating_dimensions 
				     where 
					    dimension_key = :dimension_key )
   </querytext>
</fullquery>


</queryset>