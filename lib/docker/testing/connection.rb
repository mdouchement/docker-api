module Docker
  class Connection
    alias_method :request_real, :request
    def request(*args, &block)
      if Testing.fake?
        faker(*args, &block)
      else
        request_real(*args, &block)
      end
    end

    private

    # Use #send & #missing_methods to dispatch calls (in place of case/when)
    def faker(http_method, path, query = nil, opts = nil, &block)
      case
      when http_method == :post && path == '/containers/create'
        id = SecureRandom.hex(32)
        create_container(id)
        format_response('Id' => id, 'Warnings' => [])
      when http_method == :post && id = path.match(/\/containers\/(.*)\/start/)
        update_container_status(id[1], :started)
      when http_method == :post && id = path.match(/\/containers\/(.*)\/restart/)
        update_container_status(id[1], :started)
      when http_method == :post && id = path.match(/\/containers\/(.*)\/stop/)
        stop_container(id[1])
      when http_method == :post && id = path.match(/\/containers\/(.*)\/kill/)
        stop_container(id[1])
      when http_method == :delete && id = path.match(/\/containers\/(.*)/)
        remove_container(id[1])
      when http_method == :delete && id = path.match(/\/containers\/(.*)\/json/)
        remove_container(id[1])
      when http_method == :get && id = path.match(/\/containers\/(.*)\/json/)
        get_container(id[1])
      when http_method == :get && path == '/containers/json'
        all_containers
      end
    end

    def containers
      @containers ||= {}
    end

    def stoped_containers
      @stoped_containers = {}
    end

    def create_container(id)
      containers["#{ id[0..12] }"] = { json: { 'Id' => id }, status: :created }
    end

    # Use json key to change the status
    # See:
    #   https://docs.docker.com/reference/api/docker_remote_api_v1.12/#21-containers
    #   => GET /containers/(id)/json
    # for the structure of the json key
    def update_container_status(id, status)
      containers["#{ id[0..12] }"][:status] = status
    end

    # See above for returns in the real result format
    # What to do when not found
    def get_container(id)
      format_response containers["#{ id[0..12] }"][:json]
    end

    def all_containers
      format_response containers.values.map { |container| container[:json] }
    end

    def stop_container(id)
      update_container_status(id, :stoped)
      stoped_containers["#{ id[0..12] }"] = containers.delete("#{ id[0..12] }")
    end

    def remove_container(id)
      stoped_containers.delete("#{ id[0..12] }")
    end

    def format_response(response)
      JSON.generate(response)
    end
  end
end
