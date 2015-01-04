require 'mysql2'

DB_CONN_OPTS = {
    host: 'localhost',
    username: 'volcanoftp',
    password: 'volcanoftpass',
    port: 3306,
    database: 'VOLCANO_FTP_DB'
}

class Auth

  def self.grant?(username, password)
    client = Mysql2::Client.new(DB_CONN_OPTS)
    res = client.query("SELECT * FROM VFTP_USER WHERE LB_USER='#{username}'")
    client.close
    raise unless res.size === 1
    res.each { |r|
      raise unless password === r['LB_PASSWD']
    }
    true
  rescue
    false
  end

end