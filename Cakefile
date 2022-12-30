# todo: move inside executable

require "log"
require "dotenv"
require "sqlite3"
require "migrate"

Dotenv.load

desc "Migrate database to the latest version"
task :dbmigrate do
  migrator = Migrate::Migrator.new(
    DB.open(ENV["DATABASE_URL"])
  )
  migrator.to_latest
end