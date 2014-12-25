require_relative 'dtp'
require_relative'stat_helper'

class Session
  attr_reader :preferences, :cwd, :mode, :dtp

  def initialize(client)
    @preferences = client.server.preferences
    @cwd = Pathname.new('/')
    @mode = 'A'
    @dtp = nil
  end

  def set_cwd(path)
    unless path.is_a?(Pathname); raise TypeError.new('Not a Pathname'); end
    @cwd = path
  end

  def set_mode(mode)
    raise ArgumentError.new('Wrong mode') unless mode.match(/^A|B|I|L$/)
    @mode = mode
  end

  def set_dtp(dtp)
    unless dtp.is_a?(DTP); raise TypeError.new('Not a DTP'); end
    @dtp = dtp
    true
  end

  def reset_dtp
    unless @dtp.nil?
      @dtp.close
      @dtp = nil
    end
  end

  def make_path(args)
    if args.length.zero?
      path = @cwd
    else
      path = Pathname.new(args[0]).expand_path(@cwd)   # TODO: handle ArgumentError: user xxx~ doesn't exist
    end
    path
  end

  def sys_path(path)
    path.sub('/', @preferences[:root_dir].to_s + '/')
  end
end

