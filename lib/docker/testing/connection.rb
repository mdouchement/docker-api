module Docker
  class Connection
    alias_method :request_real, :request
    def request(*args, &block)
      if Testing.fake?
        response = dispatcher(*args, &block)
        return nil if response.nil?
        format_response response
      else
        request_real(*args, &block)
      end
    end

    private

    def dispatcher(http_method, path, query = {}, opts = {}, &block)
      if opts[:body]
        opts[:body] = JSON.parse(opts[:body])
      else
        opts[:body] = {}
      end

      case
      when path.include?('/containers/')
        container_manager.perform(http_method, path, query, opts, &block)
      when path.include?('/images/')
        $stdout.puts 'Not supported yet'
      end
    end

    def container_manager
      @container_manager ||= Docker::Testing::ContainerManager.new
    end

    def format_response(response)
      JSON.generate(response)
    end
  end
end
