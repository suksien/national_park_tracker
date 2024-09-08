require "pg"

class DatabasePersistence
  def initialize(logger)
    @db = PG.connect(dbname: "national_parks")
    @logger = logger
  end
end