module ApplicationHelper

  def time_formatter(time)
    time.strftime("%b %e, %l:%M:%S %p")
  end

end
