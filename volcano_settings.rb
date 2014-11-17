require 'optparse'
require 'yaml'
require_relative 'volcano_log'

# magic values
VOLCANO_MIN_PORT=1025
VOLCANO_MAX_PORT=65535

# default server settings values
# (used only if a setting has not been defined
# either with CLI args or config file)
VOLCANO_DEFAULT_BIND = '127.0.0.1'
VOLCANO_DEFAULT_PORT = 4242

# paths
VOLCANO_CONFIG_FILE_PATH = './config.yml'

class VolcanoSettings
  def initialize
    @bind_ip = VOLCANO_DEFAULT_BIND
    @external_ip = VOLCANO_DEFAULT_BIND
    @port = VOLCANO_DEFAULT_PORT
    @root_dir = Pathname.new(Dir.home)
    @accept_anon = true

    @set_external = false
    config_from_file
    config_from_cli
    @external_ip = @bind_ip unless @set_external
  end

  def to_h
    {bind_ip: @bind_ip, external_ip: @external_ip, port: @port, root_dir: @root_dir, accept_anon: @accept_anon}
  end

  private
  def set_bind_ip(bind)
    @bind_ip = bind
  end

  def set_external_ip(ip)
    @external_ip = ip
    @set_external = true
  end

  def set_port(port)
    if port.to_i >= VOLCANO_MIN_PORT && port.to_i <= VOLCANO_MAX_PORT
      @port = port.to_i
    else
      VolcanoLog.log("Ignoring bad value '#{port}'")
    end
  end

  def set_root_dir(path)
    path = Pathname.new((path == '~') && Dir.home || path).realpath
    if Dir.exists?(path)
      @root_dir = path
    else
      VolcanoLog.log("Directory '#{path}' does not exists")
    end
  end

  def set_accept_anon(accept)
    @accept_anon = accept
  end

  def config_from_file
    begin
      return unless File.exists?(VOLCANO_CONFIG_FILE_PATH)
      cfg = YAML.load_file(VOLCANO_CONFIG_FILE_PATH)
      set_bind_ip(cfg['bind_ip']) if cfg.keys.include?('bind_ip')
      set_port(cfg['port']) if cfg.keys.include?('port')
      set_root_dir(cfg['root_dir']) if cfg.keys.include?('root_dir')
      set_accept_anon(cfg['accept_anon']) if cfg.keys.include?('accept_anon')
    rescue Exception => e
      VolcanoLog.log(e)
      exit(1)
    end
  end

  def config_from_cli
    begin
      OptionParser.new { |opts|
        opts.banner = 'Usage: ./volcano_ftp.rb [options]'

        opts.on('-b', '--bind HOSTNAME_OR_IP') { |bind|
          set_bind_ip(bind)
        }
        opts.on('-e', '--external HOSTNAME_OR_IP') { |ip|
          set_external_ip(ip)
        }
        opts.on('-p', '--port PORT') { |port|
          set_port(port.to_i)
        }
        opts.on('-r', '--root DIR') { |path|
          set_root_dir(path)
        }
        opts.on('-a', '--no-anonymous') {
          set_accept_anon(false)
        }
      }.parse!
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
      VolcanoLog.log(e)
      exit(1)
    end
  end
end

