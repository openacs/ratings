-- Ratings
--
-- Simple multidimensional rating package.
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

create table rating_dimensions (
        dimension_id    integer
                        constraint rating_dims_object_id_fk
                        references acs_objects(object_id)
                        constraint rating_dimensions_pk
                        primary key,
        dimension_key   varchar(100)
                        constraint rating_dims_dim_key_nn
                        not null,
        description     text,
        range_low       integer default 1,
        range_high      integer default 5,
        label_low       text default 'worst',
        label_high      text default 'best'
);

comment on table rating_dimensions is '
        The definition for a rating dimension.
';


create table ratings (
        rating_id       integer
                        constraint ratings_rating_id_fk
                        references acs_objects(object_id)
                        constraint ratings_rating_id_pk
                        primary key,
        dimension_id    integer
                        constraint ratings_dimension_id_fk
                        references rating_dimensions(dimension_id) on delete cascade,
        object_id       integer
                        constraint ratings_object_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint ratings_object_id_nn
                        not null,
        rating          integer
                        constraint ratings_rating_nn
                        not null,
        owner_id        integer
                        constraint ratings_owner_id_fk
                        references parties(party_id) on delete cascade
                        constraint ratings_owner_id_nn
                        not null,
        constraint ratings_un
        unique (object_id, owner_id, dimension_id) 
);

comment on table ratings is '
        An object_id is related along dimension dimension_id by user user_id.  Triggers maintain
        rating_aggregates which hold the average rating along a dimension.
';

comment on column ratings.rating is '
        An integer rating object_id along dimension.  Typically 1-5 although no constraint imposed
        although maybe there should be a before insert trigger to verify the rating is between high and low
        for dimension_id.
';


create table rating_aggregates ( 
        dimension_id    integer
                        constraint ratings_dimension_id_fk
                        references rating_dimensions(dimension_id) on delete cascade,
        object_id       integer
                        constraint ratings_object_id_fk
                        references acs_objects(object_id) on delete cascade
                        constraint ratings_object_id_nn
                        not null,
        ratings         integer,
        rating_sum      integer,
        rating_ave      float,
        rated_on        timestamptz,
        constraint      rating_aggregates_pk
                        primary key (object_id, dimension_id)
);

comment on table rating_aggregates is '
        contains denormalized aggregates for the ratings table.  trigger maintained by inserts and updates on ratings.
';


select acs_object_type__create_type(
        'rating_dimension',
        'Rating Dimension',
        'Rating Dimensions',
        'acs_object',
        'rating_dimensions',
        'dimension_id',
        'rating_dimension',
        'f',
        null,
        'rating_dimension__title'
);

select acs_object_type__create_type(
        'rating',
        'Rating',
        'Ratings',
        'acs_object',
        'ratings',
        'rating_id',
        'rating',
        'f',
        null,
        'rating__title'
);

