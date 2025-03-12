/*
  You're tasked with giving more contextual information to rail stops to fill the
  stop_desc field in a GTFS feed. Using any of the data sets above, PostGIS functions
  (e.g., ST_Distance, ST_Azimuth, etc.), and PostgreSQL string functions, build a
  description (alias as stop_desc) for each stop. Feel free to supplement with other
  datasets (must provide link to data used so it's reproducible), and other methods of
  describing the relationships. SQL's CASE statements may be helpful for some operations.
*/

set search_path to public, septa; -- include public schema for postgis

with bus_stops as (
    select
        r.stop_id,
        r.stop_name,
        r.stop_lon,
        r.stop_lat,
        count(*) as bus_stops
    from septa.rail_stops as r
    cross join
        lateral (
            select 1
            from septa.bus_stops as b
            where r.geog <-> b.geog < 200
        ) as b
    group by r.stop_id, r.stop_name, r.stop_lon, r.stop_lat
),

rail_desc as (
    select
        stop_id,
        stop_name,
        stop_lon,
        stop_lat,
        case
            -- 0: no bus stops
            when bus_stops = 0
                then 'There are no bus stops within 200m of the rail station.'
            -- 1: bus stop
            when bus_stops = 1
                then 'There is ' || bus_stops || ' bus stop within 200m of the rail station.'
            -- 2: bus stops
            else 'There are ' || bus_stops || ' bus stops within 200m of the rail station.'
        end as stop_desc
    from bus_stops
)

-- reorder
select
    stop_id,
    stop_name,
    stop_desc,
    stop_lon,
    stop_lat
from rail_desc;
