require 'docker/testing/container/template'

module Docker
  module Testing
    class EmulatedContainer
      include Container::Template

      attr_reader :template

      def initialize(id, query, opts)
        @template = new_template
        @template['id'] = id

        at_create_time(query, opts[:body])
      end

      def user
        user = @template['Config']['User']
        user.empty? ? 'root' : user
      end

      def pid
        @template['State']['Pid']
      end

      def ppid
        @ppid ||= SecureRandom.random_number(80_000)
      end

      def tty_name
        @template['Config']['Tty'] ? 'pts/6' : '?'
      end

      def define_pid
        @template['State']['Pid'] = SecureRandom.random_number(80_000)
      end

      def command
        # Space escaping
        args = @template['Args'].map do |arg|
          "'#{ arg }'" if arg.include?(' ')
        end

        "#{ @template['Path'] } #{ args.join(' ') }"
      end

      def state(state)
        return if state.nil?
        @template['State'].merge!(state)
      end

      def host_config(host_config)
        return if host_config.nil?
        @template['HostConfig'].merge!(host_config)
      end

      def inspect
        "#<#{ self.class }:0x00%08x>".format(object_id * 2)
      end

      # Define all port bindings
      def define_pulic_ports(port_bindings = {})
        return if port_bindings.nil? || port_bindings.empty?

        @template['HostConfig']['PortBindings'] = {}.tap do |pbindings|
          # Init
          @template['Config']['ExposedPorts'].each_key do |k|
            pbindings[k] = nil
          end

          # Set bindings
          port_bindings.each do |private_port, public_ports|
            pbindings[private_port] = public_ports.each do |host|
              host.merge!('HostIp' => '0.0.0.0')
            end
          end
        end

        # Set networksettings (used for Container#all method)
        @template['NetworkSettings']['Ports'] = @template['HostConfig']['PortBindings'].dup
      end

      # ports formating for Container#all request
      def ports_details
        ports = @template['NetworkSettings']['Ports']

        [].tap do |pdetails|
          ports.each do |private_port, public_ports|
            pport, type = private_port.split('/')

            if public_ports.nil?
              pdetails << { 'PrivatePort' => pport, 'Type' => type }
            else
              public_ports.each do |host|
                pdetails << { 'IP' => host['HostIp'], 'PrivatePort' => pport,
                              'PublicPort' => host['HostPort'], 'Type' => type }
              end
            end
          end
        end
      end

      private

      def at_create_time(query, body)
        @template['Name'] = "/#{ query['name'].gsub(/[^a-zA-Z0-9_.-]/, '') }"

        @template['Path'] = body['Cmd'][0]
        @template['Args'] = body['Cmd'][1..-1]

        port_specs = body.delete('PortSpecs')
        @template['Config'].merge!(body)
        define_private_ports(port_specs)

        @template['Created'] = Testing.time_now
      end

      # Convert PortSpecs option to ExposedPorts
      # ['8000/udp'] to { '8000/udp' => {} }
      #
      # Updates NetworkSettings -> Ports values
      def define_private_ports(port_specs = [])
        return if port_specs.nil? || port_specs.empty?

        @template['Config']['ExposedPorts'] = {}.tap do |eports|
          port_specs.each do |port|
            port += '/tcp' if port !~ /\D/

            eports[port] = {}
          end
        end

        @template['NetworkSettings']['Ports'] = {}.tap do |ports|
          @template['Config']['ExposedPorts'].each_key do |k|
            ports[k] = nil
          end
        end
      end
    end
  end
end
