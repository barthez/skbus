
module RedisCache
  module CachingModule
    def self.to_s
      methods = instance_methods - [:redis_key]
      "CachingModule(#{methods.join(', ')})"
    end

    def self.inspect
      to_s
    end

    def self.define_cached_method(name)
      define_method(name) do |*args|
        __redis_cache_fetch(name, *args) do
          super(*args)
        end
      end
    end

    def redis_key
      if defined?(super)
        super
      elsif is_a?(Class)
        name
      else
        self.class.name
      end
    end

    private

    def __redis_cache_fetch(method, *args)
      key = ([redis_key] + args).compact.join(':')
      value = Scheduler.redis.get(key)
      if value
        Marshal.load(value)
      else
        value = yield
        Scheduler.redis.set(key, Marshal::dump(value))
        value
      end
    end
  end

  def redis_cache(method)
    unless caching_module = instance_variable_get(:@caching_module)
      caching_module = instance_variable_set(:@caching_module, CachingModule.dup)
      prepend caching_module
    end

    caching_module.define_cached_method(method)
  end

  def class_redis_cache(method)
    unless caching_module = singleton_class.instance_variable_get(:@caching_module)
      caching_module = singleton_class.instance_variable_set(:@caching_module, CachingModule.dup)
      singleton_class.prepend caching_module
    end

    caching_module.define_cached_method(method)
  end
end
