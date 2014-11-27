require 'sqlite3'

class VolcanoStats

  def initialize(info)
  	begin
  		db = SQLite3::Database.open "test.db"
  		db.execute "CREATE TABLE IF NOT EXISTS Connexion(
  			User VARCHAR(255),
  			Duration INT,
  			Transfered_nb INT,
  			Start_time DATETIME
  		)"
      diff = time_diff(info[:duration], info[:start_time])
      db.execute "INSERT INTO Connexion VALUES ( '#{info[:user]}', '#{diff}', '#{info[:transfer_nb]}', '#{info[:start_time]}' )"

  	rescue SQLite3::Exception => e
  		puts "sqlite error #{e}"

  	ensure
  		db.close if db
  	end
  end


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