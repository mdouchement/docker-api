require 'securerandom'
require 'json'
require 'docker'
require 'docker/testing/connection'
require 'docker/testing/container_manager'
require 'docker/testing/container_template'

module Docker
  module Testing
    class << self
      attr_accessor :__test_mode

      def __set_test_mode(mode)
        self.__test_mode = mode
      end

      def disable!
        __set_test_mode(:disable)
      end

      def fake!
        __set_test_mode(:fake)
      end

      def disable?
        __test_mode == :disable
      end

      def fake?
        __test_mode == :fake
      end

      def time_now
        Time.now.gmtime.iso8601(10)
      end
    end
  end

  Testing.fake!
end
