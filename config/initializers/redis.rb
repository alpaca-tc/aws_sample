redis_url = Rails.application.config_for(:redis)['redis_url']
Redis.current = Redis.new(url: redis_url)
