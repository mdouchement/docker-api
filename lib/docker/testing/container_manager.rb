module Docker
  module Testing
    class ContainerManager
      def perform(http_method, path, query, opts, &block)
        puts "query: #{ query }, opts: #{ opts }"

        # /containers/5453685454/start => ['containers, '5453685454', 'start']
        splits = path.split('/')[1..-1]

        if splits.length == 3
          send("#{ http_method }_#{ splits[2] }_with_id".downcase, splits[1][0..12], query, opts)
        else
          # remove: DELETE /containers/#{self.id}
          # all: GET /containers/json
          if http_method == :delete && (id = path.match(/\/containers\/(.*)/))
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
        containers["#{ id[0..12] }"] = EmulatedContainer.new(id, query, opts)
        response(id)
      end

      # start container
      def post_start_with_id(id, query, opts)
        containers[id].tap do |container|
          container.define_pulic_ports(opts[:body].delete('PortBindings'))
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

      # get all containers
      def get_json(*args)
        containers.values.map do |container|
          tpt = container.template

          # Space escaping
          args = tpt['Args'].map do |arg|
            "'#{ arg }'" if arg.include?(' ')
          end

          {
            'Command' => "#{ tpt['Path'] } #{ args.join(' ') }",
            'Created' => Time.parse(tpt['Created']).to_i,
            'Id' => tpt['id'],
            'Image' => tpt['Image'],
            'Names' => [tpt['Name']],
            'Ports' => container.ports_details,
            'Status' => 'Up Less than a second'# Write method that define this
          }
        end
      end

      # remove container
      def post_remove(id)
        short_id = id[0..12]

        if containers.key?(short_id)
          fail 'Expected(200..204) <=> Actual(406 Not Acceptable) (Excon::Errors::NotAcceptable)'
        end

        unless stoped_containers.key?(short_id)
          fail 'Expected(200..204) <=> Actual(404 Not Found) (Docker::Error::NotFoundError)'
        end

        stoped_containers.delete(short_id)
        nil
      end

      # Warnings value is nil or it is an array
      def response(id)
        { 'Id' => id, 'Warnings' => nil }
      end
    end
  end
end
