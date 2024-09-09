require "pg"
require "pry"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "national_parks")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def get_all_parks
    statement = <<~sql
      SELECT *
      FROM park_info as p
      JOIN visits as v
      ON p.id = v.park_id
    sql

    result = query(statement)
    result.map { |tuple| sql_out_to_hsh(tuple) }
  end

  def get_park(name)
    statement = <<~sql
      SELECT *
      FROM park_info as p
      JOIN visits as v
      ON p.id = v.park_id
      WHERE p.name = $1
    sql

    result = query(statement, name)
    sql_out_to_hsh(result[0])
  end

  def update_park_visit(park_name, date_visited, note)
    statement= "SELECT id FROM park_info WHERE name = $1"
    park_id = query(statement, park_name)[0]["id"].to_i

    statement = <<~sql
      UPDATE visits
      SET visited = true, date_visited = $1, note = $2
      WHERE park_id = $3
    sql

    query(statement, date_visited, note, park_id)
  end

  private

  def sql_out_to_hsh(result)
    {
      id: result["id"].to_i,
      name: result["name"], 
      state: result["state"], 
      date_established: result["date_established"],
      area_acres: result["area_acres"].to_i,
      area_km2: result["area_km2"].to_i,
      description:  result["description"],
      visited: result["visited"] == "t",
      date_visited: result["date_visited"],
      note: result["note"]
    }
  end
end