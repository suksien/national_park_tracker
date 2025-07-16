require "pg"
require "bcrypt"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "national_parks")
    @logger = logger
  end

  def query(statement, *params)
    @logger.info("#{statement}: #{params}")
    @db.exec_params(statement, params)
  end

  def valid_user?(username, password)
    statement = "SELECT password FROM users WHERE username = $1"
    result = query(statement, username)
    return false if result.ntuples == 0

    user_pw = result[0]['password']
    BCrypt::Password.new(user_pw) == password
  end

  def count_parks
    statement = "SELECT count(id) FROM park_info"
    result = query(statement)
    result[0]["count"]
  end

  def count_park_visits(park_id)
    statement = "SELECT count(id) FROM visits WHERE park_id = $1"
    result = query(statement, park_id)
    result[0]["count"]
  end

  def has_park?(name)
    statement = "SELECT * FROM park_info WHERE name ilike $1"
    result = query(statement, name)
    result.ntuples == 1
  end

  def get_all_parks(limit, offset)
    statement = <<~sql
      SELECT p.*, count(v.id)
      FROM park_info as p
      LEFT JOIN visits as v
        ON p.id = v.park_id
      GROUP BY p.id
      ORDER BY p.name
      LIMIT $1 
      OFFSET $2
    sql
    
    result = query(statement, limit, limit * (offset-1))
    result.map { |tuple| sql_out_to_hsh(tuple) }
  end

  def get_park(name)
    statement = <<~sql
      SELECT *
      FROM park_info
      WHERE name = $1
    sql

    result = query(statement, name)
    return sql_out_to_hsh_park_info(result[0]) if result.ntuples == 1
    nil
  end

  def get_park_visits(park_id, limit, offset)
    statement = <<~sql
      SELECT * FROM visits 
      WHERE park_id = $1
      ORDER BY date_visited
      LIMIT $2 
      OFFSET $3
    sql

    result = query(statement, park_id, limit, limit * (offset-1))
    result.map { |tuple| sql_out_to_hsh_visit_info(tuple) }
  end

  def insert_park(name, state, date, area, desc)
    statement = <<~sql
      INSERT INTO park_info (name, state, date_established, area_km2, description)
      VALUES ($1, $2, $3, $4, $5)
    sql

    query(statement, name, state, date, area, desc)
  end

  def update_park(park_id, new_name, new_state, new_date, new_area, new_desc)
    statement = <<~sql
      UPDATE park_info
      SET name = $1, state = $2, date_established = $3, area_km2 = $4, description = $5
      WHERE id = $6
    sql
    
    query(statement, new_name, new_state, new_date, new_area, new_desc, park_id)
  end

  def delete_park(name)
    statement = "DELETE FROM park_info where name = $1"
    query(statement, name)
  end
  
  def add_visit(park_name, visit_date, visit_note)
    statement = "SELECT id FROM park_info where name = $1"
    result = query(statement, park_name)
    park_id = result[0]["id"]

    if visit_note.nil?
      statement = "INSERT INTO visits (park_id, date_visited) VALUES ($1, $2)"
      query(statement, park_id, visit_date)
    else
      statement = "INSERT INTO visits (park_id, date_visited, note) VALUES ($1, $2, $3)"
      query(statement, park_id, visit_date, visit_note)
    end
  end

  def visit_exists?(park_name, visit_date)
    statement = "SELECT id FROM park_info where name = $1"
    result = query(statement, park_name)
    park_id = result[0]["id"]

    statement = "SELECT * FROM visits WHERE park_id = $1 AND date_visited = $2"
    result = query(statement, park_id, visit_date)
    result.ntuples == 1
  end

  def get_visit(visit_id)
    statement = "SELECT * FROM visits WHERE id = $1"
    result = query(statement, visit_id)
    return sql_out_to_hsh_visit_info(result[0]) if result.ntuples == 1
    nil
  end

  def update_visit(visit_id, new_date, new_note)
    if new_note.nil?
      statement = "UPDATE visits SET date_visited = $1 WHERE id = $2"
      query(statement, new_date, visit_id)
    else
      statement = <<~sql
        UPDATE visits
        SET date_visited = $1, note = $2
        WHERE id = $3
      sql
      query(statement, new_date, new_note, visit_id)
    end
  end

  def delete_visit(visit_id)
    statement = "DELETE FROM visits WHERE id = $1"
    query(statement, visit_id)
  end

  private

  def sql_out_to_hsh(result)
    {
      id: result["id"].to_i,
      name: result["name"], 
      state: result["state"], 
      date_established: result["date_established"],
      area_km2: result["area_km2"].to_i,
      description: result["description"],
      visit_count: result["count"].to_i
    }
  end

  def sql_out_to_hsh_park_info(result)
    {
      id: result["id"].to_i,
      name: result["name"], 
      state: result["state"], 
      date_established: result["date_established"],
      area_km2: result["area_km2"].to_i,
      description: result["description"]
    }
  end

  def sql_out_to_hsh_visit_info(result)
    {
      id: result["id"].to_i,
      date_visited: result["date_visited"], 
      note: result["note"]
    }
  end

end