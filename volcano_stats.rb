require 'sqlite3'

class VolcanoStats

  def initialize
  	begin
      @db_name = 'volcano.db'
  		SQLite3::Database.open(@db_name) { |db|

    		db.execute 'CREATE TABLE IF NOT EXISTS Connexion(
    			User VARCHAR(255),
    			Duration INT,
    			Transfered_nb INT,
    			Start_time DATETIME
    		)'
        db.execute 'CREATE TABLE IF NOT EXISTS Transfered(
          Name TEXT,
          Speed NUMERIC,
          Size NUMERIC
        )'
      }

      $log.puts('Stats database created')

  	rescue SQLite3::Exception => e
  		puts "sqlite error #{e}"
    end

  end


  def connexion(info)
    begin
      diff = time_diff(info[:conn][:duration], info[:conn][:start_time])

      SQLite3::Database.open(@db_name) { |db|
        db.execute "INSERT INTO Connexion VALUES ( '#{info[:conn][:user]}', '#{diff}', '#{info[:conn][:transfer_nb]}', '#{info[:conn][:start_time]}' )"  
      }
    rescue SQLite3::Exception => e
      $log.puts "Insert to connexion table occurred an error #{e}"
    end
  end


  def transfered(info)
    begin
      SQLite3::Database.open(@db_name) { |db|
        db.execute "INSERT INTO Transfered VALUES ( '#{info[:transfer][:name]}', '#{info[:transfer][:speed]}', '#{info[:transfer][:size]}' )"  
      }
    rescue SQLite3::Exception => e
      $log.puts "insert to transferred table occurred an error #{e}"
    end
  end

  private
  def time_diff(start_time, end_time)
    seconds_diff = (start_time - end_time).to_i.abs

    hours = seconds_diff / 3600
    seconds_diff -= hours * 3600

    minutes = seconds_diff / 60
    seconds_diff -= minutes * 60

    seconds = seconds_diff

    "#{hours.to_s.rjust(2, '0')}:#{minutes.to_s.rjust(2, '0')}:#{seconds.to_s.rjust(2, '0')}"
  end
  
end