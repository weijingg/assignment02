/*
  What are the bottom five neighborhoods according to your accessibility metric?
*/

set search_path to public, septa, phl; -- include public schema for postgis

with inheritance as (
    select
        s.stop_id,
        s.geog,
        case
            -- 0: inherit from parent stop
            when s.wheelchair_boarding = 0 and s.parent_station is not null
                then p.wheelchair_boarding
            -- 0: no accessibility information
            when s.wheelchair_boarding = 0 and s.parent_station is null
                then null
            -- 1 or 2 (keep original value)
            else s.wheelchair_boarding
        end as wheelchair_boarding
    from septa.bus_stops as s
    left join septa.bus_stops as p
        -- join to parent stop
        on s.parent_station = p.stop_id
),

nhood_stops as (
    select
        n.name as neighborhood_name,
        -- Convert square meters to square km
        i.stop_id,
        i.wheelchair_boarding,
        st_area(n.geog) / 1e6 as area_sqkm
    from inheritance as i
    left join phl.neighborhoods as n
        on st_contains(n.geog::geometry, i.geog::geometry)
),

scores as (
    select
        neighborhood_name,
        round((100.0 * sum(case when wheelchair_boarding = 1 then 1 else 0 end) / area_sqkm)::numeric, 2) as score,
        sum(case when wheelchair_boarding = 1 then 1 else 0 end) as num_bus_stops_accessible,
        sum(case when wheelchair_boarding = 2 then 1 else 0 end) as num_bus_stops_inaccessible
    from nhood_stops
    where neighborhood_name is not null
    group by neighborhood_name, area_sqkm
),

weighted_scores as (
    select
        neighborhood_name,
        num_bus_stops_accessible,
        num_bus_stops_inaccessible,
        round(
            (
                (score - (min(score) over ())) / ((max(score) over ()) - (min(score) over ()))
            ), 2
        ) as accessibility_metric
    from scores
)

select
    neighborhood_name,
    accessibility_metric,
    num_bus_stops_accessible,
    num_bus_stops_inaccessible
from weighted_scores
group by neighborhood_name, accessibility_metric, num_bus_stops_accessible, num_bus_stops_inaccessible
order by accessibility_metric asc
limit 5;
