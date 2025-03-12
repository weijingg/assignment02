/*
  With a query involving PWD parcels and census block groups,
  find the geo_id of the block group that contains Meyerson Hall.
  ST_MakePoint() and functions like that are not allowed.
*/

set search_path to public, census, phl; -- include public schema for postgis

with meyerson as (
    select geog
    from phl.pwd_parcels
    where address like '%220-30 S 34TH ST%'
)

select cb.geoid as geo_id
from meyerson as m
left join census.blockgroups_2020 as cb
    on st_contains(cb.geog::geometry, m.geog::geometry);
