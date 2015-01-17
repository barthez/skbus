module Scheduler

	module_function

	def redis
		@redis ||= if Rails.env.production?
			Redis.new(url: ENV['REDISCLOUD_URL'])
		else
			Redis.new
		end
	end

end