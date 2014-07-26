module Docker
  module Testing
    class ContainerManager
      def perform(http_method, path, query, opts, &block)
        splits = path.split('/')[1..-1] # /containers/5453685454/start => ['containers, '5453685454', 'start']

        if splits.length == 3
          send("#{ http_method }_#{ splits[2] }_with_id".downcase, splits[1][0..12], query, opts)
        else
          # remove: DELETE /containers/#{self.id}
          # all: GET /containers/json
          if http_method == :delete && id = path.match(/\/containers\/(.*)/)
            post_remove(id[1])
          else
            send("#{ http_method }_#{ splits.last }".downcase, path, query, opts)
          end
        end
      end

      private

      def containers
        @containers ||= {}
      end

      def stoped_containers
        @stoped_containers ||= {}
      end

      # create container
      def post_create(path, query, opts)
        id = SecureRandom.hex(32)
        containers["#{ id[0..12] }"] = Docker::Testing::ContainerTemplate.new(id, query, opts)
        response(id)
      end

      # start container
      def post_start_with_id(id, query, opts)
        containers[id].tap do |container|
          container.host_config(opts[:body])
          container.state('StartedAt' => Testing.time_now, 'Running' => true)
        end
        response(id)
      end

      # stop container
      def post_stop_with_id(id, query, opts)
        containers[id].tap do |container|
          container.host_config(opts[:body])
          container.state('FinishedAt' => Testing.time_now, 'Running' => false)
        end
        stoped_containers[id] = containers.delete(id)
        response(id)
      end

      # TODO: restart

      # kill container
      def post_kill_with_id(id, query, opts)
        containers[id].tap do |container|
          container.host_config(opts[:body])
          container.state('ExitCode' => -1, 'FinishedAt' => Testing.time_now, 'Running' => false)
        end
        stoped_containers[id] = containers.delete(id)
        response(id)
      end

      # get container
      def get_json_with_id(id, query, opts)
        if containers.key?(id)
          containers[id].template
        elsif stoped_containers.key?(id)
          stoped_containers[id].template
        else
          # when removed
        end
      end

      # get all container
      def get_json(*args)
        containers.values.map do |container|
          tpt = container.template

          # Space escaping
          args = tpt['Args'].map do |arg|
            arg = "'#{ arg }'" if arg.include?(' ')
          end

          {
            'Command' => "#{ tpt['Path'] } #{ args.join(' ') }",
            'Created' => 1406395977,# Find what is this format (created_at is iso formated)
            'Id' => tpt['id'],
            'Image' => tpt['Image'],
            'Names' => tpt['Name'],# Several names ?
            'Ports' => tpt['HostConfig']['PortBindings'] || [],# Seems to this
            'Status' => 'Up Less than a second'# Write method that define this
          }
        end
      end

      # remove container
      def post_remove(id)
        short_id = id[0..12]
        fail 'Expected(200..204) <=> Actual(406 Not Acceptable) (Excon::Errors::NotAcceptable)' if containers.key?(short_id)
        fail 'Expected(200..204) <=> Actual(404 Not Found) (Docker::Error::NotFoundError)' unless stoped_containers.key?(short_id)
        stoped_containers.delete(short_id)
        nil
      end

      # Warnings value is nil or it is an array
      def response(id)
        { 'Id' => id, 'Warnings' => nil }
      end

      # TODO: Implement conflicts operations errors
    end
  end
end
