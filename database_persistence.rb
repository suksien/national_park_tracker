require "pg"

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