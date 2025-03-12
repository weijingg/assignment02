/*
  With a query, find out how many census block groups Penn's main campus
  fully contains. Discuss which dataset you chose for defining Penn's campus.
*/

set search_path to public, census, phl; -- include public schema for postgis

with selection as (
    select
        objectid,
        geog
    from phl.pwd_parcels
    where
        owner1 like '%TRUSTEES OF THE UNIVERSIT%'
        or
        owner1 like '%TRS UNIV OF PENN%'
        or
        owner1 like '%UNIV OF PENNSYLVANIA%'
        or
        owner1 like '%THE UNIVERSITY OF PENNA%'
        or
        owner1 like '%UNIVERSITY CITY ASSOC%'
        or
        owner2 like '%TRUSTEES OF THE UNIVERSIT%'
        or
        owner2 like '%TRS UNIV OF PENN%'
        or
        owner2 like '%UNIV OF PENNSYLVANIA%'
        or
        owner2 like '%THE UNIVERSITY OF PENNA%'
        or
        owner2 like '%UNIVERSITY CITY ASSOC%'
),

penn as (
    select *
    from selection as s
    where exists (
        select 1 from selection as b
        where
            s.objectid != b.objectid
            -- to narrow down to main campus
            and s.geog <-> b.geog < 10
    )
),

blocks as (
    select cb.geoid
    from penn as p
    inner join census.blockgroups_2020 as cb
        on st_contains(cb.geog::geometry, p.geog::geometry)
    group by cb.geoid, cb.geog
    -- ensure at least 20% coverage of census block group by parcels
    -- 20% because likely not all UPenn parcels were identified from string comparison
    having sum(st_area(p.geog)) >= 0.2 * st_area(cb.geog)
)

select count(*) as count_block_groups
from blocks;
