DROP DATABASE IF EXISTS national_parks;

CREATE DATABASE national_parks;

\connect national_parks

CREATE TABLE info (
  id serial PRIMARY KEY,
  name text NOT NULL,
  state text NOT NULL,
  date_established date,
  area_acres numeric,
  area_km2 numeric,
  description text,
  visited boolean NOT NULL DEFAULT false,
  visit_date date,
  visit_note text
);

\copy info (name,state,date_established,area_acres,area_km2,description) from 'data/mini_df.csv' csv header;