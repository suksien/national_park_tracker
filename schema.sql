DROP DATABASE IF EXISTS national_parks;

CREATE DATABASE national_parks;

\connect national_parks

CREATE TABLE park_info (
  id serial PRIMARY KEY,
  name text NOT NULL UNIQUE,
  state text NOT NULL,
  date_established date,
  area_km2 numeric,
  description text
);

\copy park_info (name,state,date_established,area_km2,description) from 'data/mini_df.csv' csv header;

CREATE TABLE visits (
  id serial PRIMARY KEY,
  park_id integer NOT NULL REFERENCES park_info (id) ON DELETE CASCADE,
  date_visited date NOT NULL,
  note text
);

INSERT INTO visits (park_id, date_visited, note)
VALUES (1, '2015-01-01', 'A great experience'),
       (1, '2016-03-15', 'Back here again'),
       (1, '2017-05-20', 'Summer visit'),
       (1, '2020-12-01', 'Winter visit'),
       (1, '2022-07-21', 'Definitely my favorite park'),
       (8, '2023-05-03', 'A small but mighty park'),
       (11, '2023-06-07', 'Went with family and friends'),
       (11, '2024-09-21', 'It never gets old');

CREATE TABLE users (
  id serial PRIMARY KEY,
  username text NOT NULL,
  password text NOT NULL
);

/*
Test user:
username = ta
password = letmein
*/
INSERT INTO users (username, password)
VALUES ('ta', '$2a$12$7TZ3EQgwJVMCIufg8UTfeuXHx5aqplNW2iaRzq/k5jXgXupSoN3la');