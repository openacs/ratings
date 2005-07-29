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
	and	
		context_object_id = :context_object_id
	$extra_query
   </querytext>
</fullquery>


</queryset>