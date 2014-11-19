class VolcanoStatsSession
  attr_reader :stats

  def initialize
    @stats = {
        conn_info: {addr: nil, conn_time: nil, conn_duration: nil},
        file_xfer_nb: nil,

    }
  end
end