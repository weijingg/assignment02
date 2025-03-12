/*
  Using the bus_shapes, bus_routes, and bus_trips tables from
  GTFS bus feed, find the two routes with the longest trips.
  Your query should run in under two minutes.
*/

set search_path to public, septa; -- include public schema for postgis

with trip_shape as (
    select
        s.shape_id,
        -- create trip geometries from lat lon
        st_makeline(
            array_agg(
                st_setsrid(st_makepoint(s.shape_pt_lon, s.shape_pt_lat), 4326)
                order by s.shape_pt_sequence
            )
        ) as geom
    from bus_shapes as s
    group by s.shape_id
),

trip_length as (
    select
        ts.shape_id,
        ts.geom,
        t.trip_headsign,
        t.route_id,
        -- calculate length
        st_length(st_transform(ts.geom, 32129)) as trip_length
    from trip_shape as ts
    left join bus_trips as t
        on ts.shape_id = t.shape_id
    group by ts.shape_id, ts.geom, trip_length, t.trip_headsign, t.route_id
),

trip_rank as (
    select
        geom,
        trip_headsign,
        trip_length,
        route_id,
        row_number() over (
            order by trip_length desc
        ) as rank
    from trip_length
)

select
    r.route_short_name,
    tr.trip_headsign,
    tr.geom::geography as shape_geog,
    round(tr.trip_length::numeric, 0) as shape_length
from trip_rank as tr
left join septa.bus_routes as r
    on tr.route_id = r.route_id
-- 2 longest trips
where tr.rank <= 2;
