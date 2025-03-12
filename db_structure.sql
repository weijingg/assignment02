/*

This file contains the SQL commands to prepare the database for your queries.
Before running this file, you should have created your database, created the
schemas (see below), and loaded your data into the database.

Creating your schemas
---------------------

You can create your schemas by running the following statements in PG Admin:

    create schema if not exists septa;
    create schema if not exists phl;
    create schema if not exists census;

Also, don't forget to enable PostGIS on your database:

    create extension if not exists postgis;

Loading your data
-----------------

After you've created the schemas, load your data into the database specified in
the assignment README.

Finally, you can run this file either by copying it all into PG Admin, or by
running the following command from the command line:

    psql -U postgres -d <YOUR_DATABASE_NAME> -f db_structure.sql

*/

-- Add a column to the septa.bus_stops table to store the geometry of each stop.
alter table septa.bus_stops
add column if not exists geog public.geography;

update septa.bus_stops
set geog = public.st_makepoint(stop_lon, stop_lat)::public.geography;

-- Create an index on the geog column
create index if not exists septa_bus_stops__geog__idx
on septa.bus_stops using gist
(geog);

-- Create an index for route_id column, trip_id, and shape_id columns in bus_trips
create index if not exists septa_bus_trips__route__idx
on septa.bus_trips
(route_id);

create index if not exists septa_bus_trips__trip__idx
on septa.bus_trips
(trip_id);

create index if not exists septa_bus_trips__shape__idx
on septa.bus_trips
(shape_id);

-- Create an index for route_id column in bus_routes
create index if not exists septa_bus_routes__route__idx
on septa.bus_routes
(route_id);

-- Create an index for shape_id column in bus_shapes
create index if not exists septa_bus_routes__route__idx
on septa.bus_shapes
(shape_id);

-- Add geography to rail stops
alter table septa.rail_stops
add column if not exists geog public.geography;

update septa.rail_stops
set geog = public.st_makepoint(stop_lon, stop_lat)::public.geography;

-- Create an index on the geog column
create index if not exists septa_rail_stops__geog__idx
on septa.rail_stops using gist
(geog);
