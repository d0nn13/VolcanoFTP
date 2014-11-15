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
  def self.log(msg)
    puts "#{LOG_RESET}#{msg}#{LOG_RESET}"
  end

  def self.log_pid(pid, msg)
    puts "[#{pid}] #{LOG_RESET}#{msg}#{LOG_RESET}"
  end
end

class VolcanoLogInfo
  def self.log(msg)
    puts "#{LOG_LBLUE}#{msg}#{LOG_RESET}"
  end

  def self.log_pid(pid, msg)
    puts "[#{pid}] #{LOG_LBLUE}#{msg}#{LOG_RESET}"
  end
end

class VolcanoLogSuccess
  def self.log(msg)
    puts "#{LOG_GREEN}#{msg}#{LOG_RESET}"
  end

  def self.log_pid(pid, msg)
    puts "[#{pid}] #{LOG_GREEN}#{msg}#{LOG_RESET}"
  end
end

class VolcanoLogError
  def self.log(msg)
    puts "#{LOG_RED}#{msg}#{LOG_RESET}"
  end

  def self.log_pid(pid, msg)
    puts "[#{pid}] #{LOG_RED}#{msg}#{LOG_RESET}"
  end
end
