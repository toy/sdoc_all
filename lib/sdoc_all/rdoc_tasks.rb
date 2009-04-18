class SdocAll
  class RdocTasks
    include Enumerable
    def initialize
      @tasks = {}
    end

    def add(klass, options = {})
      type = klass.name.split('::').last.downcase.to_sym
      (@tasks[type] ||= []) << RdocTask.new(options)
    end

    def length
      @tasks.sum{ |type, tasks| tasks.length }
    end
    def each(&block)
      @tasks.each do |type, tasks|
        tasks.each(&block)
      end
    end

    def method_missing(method, *args, &block)
      if /^find_or_(first|last)_(.*)/ === method.to_s
        tasks = @tasks[$2.to_sym] || super
        name = args[0]
        name && tasks.find{ |task| task.name_parts.any?{ |part| part[name] } } || ($1 == 'first' ? tasks.first : tasks.last)
      else
        @tasks[method] || super
      end
    end
  end
end
