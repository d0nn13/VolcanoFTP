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
  def initialize(preferences)
    @mode = preferences[:log_mode]
    @file = nil
    path = preferences[:log_path]
    unless (@mode & LOG_MODE_FILE).zero?
      raise LogException.new('VolcanoLog: No log file path specified') if path.nil?
      @file = File.new(path, 'w')
      @file.sync = true
      @file.puts('')
      (0..100).each { @file.putc('==') }
      @file.puts("\n\n")
    end
    @mutex = Mutex.new
  end

  def self.log(msg, cid=0, level=0)
    id_str = cid.nil? && '' || " [##{cid.to_s}]"
    case level
      when LOG_INFO; color = LOG_LBLUE
      when LOG_SUCCESS; color = LOG_GREEN
      when LOG_ERROR; color = LOG_RED
      else; color = LOG_RESET
    end
    $stdout.puts "#{color}#{Time.now}:#{id_str} #{msg.strip}#{LOG_RESET}"
  end

  def puts(msg, cid=nil, level=0)
    id_str = cid.nil? && '' || " [##{cid.to_s}]"
    stream = $stdout
    case level
      when LOG_INFO; color = LOG_LBLUE
      when LOG_SUCCESS; color = LOG_GREEN
      when LOG_ERROR; color = LOG_RED; stream = $stderr
      else; color = LOG_RESET
    end
    @mutex.synchronize {
      stream.puts "#{color}#{Time.now}:#{id_str} #{msg}#{LOG_RESET}" unless (@mode & LOG_MODE_STD).zero?
      @file.puts "#{Time.now}:#{id_str} #{msg}" unless (@mode & LOG_MODE_FILE).zero? || @file.nil?
    }
  end

  def close_log
    unless (@mode & LOG_MODE_FILE).zero? || @file.nil?; @file.close; end
  end
end
