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

class VolcanoLog
  def self.log(msg, pid=0, level=0)
    pid_str = pid.zero? && '' || " [#{pid}]"
    case level
      when LOG_INFO; puts "#{Time.now}:#{pid_str} #{LOG_LBLUE}#{msg}#{LOG_RESET}"
      when LOG_SUCCESS; puts "#{Time.now}:#{pid_str} #{LOG_GREEN}#{msg}#{LOG_RESET}"
      when LOG_ERROR; puts "#{Time.now}:#{pid_str} #{LOG_RED}#{msg}#{LOG_RESET}"
      else; puts "#{LOG_RESET}#{Time.now}:#{pid_str} #{msg.strip}#{LOG_RESET}"
    end
  end

  def self.log_pid(pid, msg)
    puts "#{LOG_RESET}#{Time.now} [#{pid}] #{msg.strip}#{LOG_RESET}"
  end
end
