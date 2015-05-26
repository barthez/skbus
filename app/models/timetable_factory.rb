class TimetableFactory
	REGISTERED_PARSERS = %w(sk_bus mat_bus)
	delegate :each, :to => :all

	include Enumerable

	def new(init = false)
		all if init
	end

	def by_id(id)
		return unless id
		klass_id, tid = id.split('-', 2)
		parser_class(klass_id).by_id(tid)
	end

	def all
		REGISTERED_PARSERS.flat_map do |klass_id|
			parser_class(klass_id).all
		end
	end

	private

	def parser_class(id)
		"#{id.camelize}Parser".constantize
	end

end
