module Docker
  class Connection
    alias_method :request_real, :request
    def request(*args, &block)
      if Testing.fake?
        faker(*args, &bloack)
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
        create_container(id, opts)
        format_response('Id' => id[0..12], 'Warnings' => [])
      when http_method == :post && id = path.match(/\/containers\/(.*)\/start/)
        update_container_status(id, :started)
      when http_method == :post && id = path.match(/\/containers\/(.*)\/restart/)
        update_container_status(id, :started)
      when http_method == :post && id = path.match(/\/containers\/(.*)\/stop/)
        stop_container(id)
      when http_method == :post && id = path.match(/\/containers\/(.*)\/kill/)
        stop_container(id)
      when http_method == :delete && id = path.match(/\/containers\/(.*)/)
        remove_container(id)
      when http_method == :delete && id = path.match(/\/containers\/(.*)\/json/)
        remove_container(id)
      when http_method == :get && path == '/containers/json/'
        # ALL
      end
    end
  end

  def containers
    @containers ||= {}
  end

  def stoped_containers
    @stoped_containers = {}
  end

  def create_container(id, opts)
    json = opts.merge('Id' => id)
    containers["#{ id[0..12] }"] = { json: json, status: :created }
  end

  # Use json key to change the status
  # See:
  #   https://docs.docker.com/reference/api/docker_remote_api_v1.12/#21-containers
  #   => GET /containers/(id)/json
  # for the structure of the json key
  def update_container_status(id, status)
    containers["#{ id }"][:status] = status
  end

  # See above for returns in the real result format
  def get_container(id)
    format_response containers["#{ id }"][:json]
  end

  def all_containers
    format_response containers.map { |container| container[:json] }
  end

  def stop_container(id)
    stoped_containers["#{ id }"] = containers.delete("#{ id }")
  end

  def remove_container(id)
    stoped_containers.delete("#{ id }")
  end

  def format_response(response)
    JSON.generate(response)
  end
end
