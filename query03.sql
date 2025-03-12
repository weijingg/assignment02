/*
  Using the Philadelphia Water Department Stormwater Billing Parcels dataset,
  pair each parcel with its closest bus stop. The final result should give the
  parcel address, bus stop name, and distance apart in meters, rounded to two
  decimals. Order by distance (largest on top).
  Your query should run in under two minutes.
*/

set search_path to public, septa, pwd; -- include public schema for postgis

select
    p.address as parcel_address,
    stops.stop_name,
    round(stops.dist::numeric, 2) as distance
from phl.pwd_parcels as p
cross join
    lateral (
        select
            stops.stop_name,
            p.geog <-> stops.geog as dist
        from septa.bus_stops as stops
        order by dist
        limit 1
    ) as stops
order by distance desc;
