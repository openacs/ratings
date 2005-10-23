-- Simple multidimensional rating package -- backing data.
-- 
-- Copyright (C) 2003 Jeff Davis
-- @author Jeff Davis <davis@xarg.net>
-- @creation-date 10/22/2003
--
-- @cvs-id $Id$
--
-- This is free software distributed under the terms of the GNU Public
-- License.  Full text of the license is available from the GNU Project:
-- http://www.fsf.org/copyleft/gpl.html

select rating_dimension__new ('#ratings.Quality#','quality','#ratings.quality_desc#',1,5,'','best');

