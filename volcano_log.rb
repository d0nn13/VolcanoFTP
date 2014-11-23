LOG_INFO = 1
LOG_SUCCESS = 2
LOG_ERROR = 3

LOG_BLACK = "\x1b[0;30m"
LOG_RED = "\x1b[0;31m"
LOG_GREEN = "\x1b[0;32m"
LOG_YELLOW = "\x1b[0;33m"
LOG_DBLUE = "\x1b[0;34m"
LOG_PURPLE = "\x1b[0;35m"
LOG_LBLUE = "\x1b[0;36m"
LOG_WHITE = "\x1b[0;37m"
LOG_RESET = "\x1b[0;0;0m"

LOG_MODE_SILENT = 0
LOG_MODE_STD = 1
LOG_MODE_FILE = 2

class LogException < StandardError
end

class VolcanoLog
  def initialize(settings)
    @mode = settings.settings[:log_mode]
    @file = nil
    path = settings.settings[:log_path]
    unless (@mode & LOG_MODE_FILE).zero?
      raise LogException.new('VolcanoLog: No log file path specified') if path.nil?
      @file = File.new(path, 'w')
      @file.sync = true
      @file.puts('')
      for i in 0..100; @file.putc('=='); end
      @file.puts("\n\n")
    end
  end

  def self.log(msg, pid=0, level=0)
    pid_str = pid.zero? && '' || " [#{pid}]"
    case level
      when LOG_INFO; puts "#{Time.now}:#{pid_str} #{LOG_LBLUE}#{msg}#{LOG_RESET}"
      when LOG_SUCCESS; puts "#{Time.now}:#{pid_str} #{LOG_GREEN}#{msg}#{LOG_RESET}"
      when LOG_ERROR; puts "#{Time.now}:#{pid_str} #{LOG_RED}#{msg}#{LOG_RESET}"
      else; puts "#{LOG_RESET}#{Time.now}:#{pid_str} #{msg.strip}#{LOG_RESET}"
    end
  end

  def puts(msg, pid=0, level=0)
    pid_str = pid.zero? && '' || " [#{pid}]"
    case level
      when LOG_INFO
        $stdout.puts "#{Time.now}:#{pid_str} #{LOG_LBLUE}#{msg}#{LOG_RESET}" unless (@mode & LOG_MODE_STD).zero?

      when LOG_SUCCESS
        $stdout.puts "#{Time.now}:#{pid_str} #{LOG_GREEN}#{msg}#{LOG_RESET}" unless (@mode & LOG_MODE_STD).zero?

      when LOG_ERROR
        $stderr.puts "#{Time.now}:#{pid_str} #{LOG_RED}#{msg}#{LOG_RESET}" unless (@mode & LOG_MODE_STD).zero?

      else
        $stderr.puts "#{LOG_RESET}#{Time.now}:#{pid_str} #{msg}#{LOG_RESET}" unless (@mode & LOG_MODE_STD).zero?
    end
    @file.puts "#{Time.now}:#{pid_str} #{msg}" unless (@mode & LOG_MODE_FILE).zero? || @file.nil?
  end

  def close_log
    unless (@mode & LOG_MODE_FILE).zero? || @file.nil?; @file.close; end
  end
end
