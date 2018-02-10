class RedisController < ApplicationController
  def show
    count = Redis.current.incr('counter')
    render plain: "Redis: #{count}"
  end
end
