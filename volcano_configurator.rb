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

class VolcanoConfigurator
  attr_reader :settings

  def initialize
    @settings = {
        bind: VOLCANO_DEFAULT_BIND,
        port: VOLCANO_DEFAULT_PORT,
        accept_anon: true
    }
    config_from_file
    config_from_cli
  end

  private
  def config_from_file
    begin
      cfg = YAML.load_file(VOLCANO_CONFIG_FILE_PATH);
      @settings[:bind] = cfg['bind']
      @settings[:port] = cfg['port']
      @settings[:accept_anon] = cfg['accept_anon']
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
          @settings[:bind] = bind
        }

        opts.on('-p', '--port PORT') { |port|
          if port.to_i >= VOLCANO_MIN_PORT && port.to_i <= VOLCANO_MAX_PORT
            @settings[:port] = port.to_i
          else
            VolcanoLog.log("Ignoring bad value (#{port})")
          end
        }

        opts.on('-a', '--no-anonymous') {
          @settings[:accept_anon] = false
        }

      }.parse!
    rescue OptionParser::MissingArgument, OptionParser::InvalidOption => e
      VolcanoLog.log(e)
      exit(1)
    end
  end
end
