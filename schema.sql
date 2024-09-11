DROP DATABASE IF EXISTS national_parks;

CREATE DATABASE national_parks;

\connect national_parks

CREATE TABLE park_info (
  id serial PRIMARY KEY,
  name text NOT NULL,
  state text NOT NULL,
  date_established date,
  area_km2 numeric,
  description text
);

\copy park_info (name,state,date_established,area_km2,description) from 'data/mini_df.csv' csv header;

CREATE TABLE visits (
  id serial PRIMARY KEY,
  park_id integer NOT NULL REFERENCES park_info (id) ON DELETE CASCADE,
  visited boolean NOT NULL DEFAULT false,
  date_visited date,
  note text
);

INSERT INTO visits (park_id)
VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9), (10);
