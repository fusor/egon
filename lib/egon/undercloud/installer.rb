require 'egon/undercloud/port-check-mixin'
require 'stringio'

module Egon
  module Undercloud
    class Installer
      include PortCheckMixin

      attr_reader :started
      alias_method :started?, :started

      # installs locally if ssh connection is not provided
      def initialize(connection=nil)
        @connection = connection
        @completed = false
        @started = false
        @failure = false
      end

      def completed?
        @completed
      end

      def set_completed(bool)
        @completed = bool
      end

      def failure?
        @failure
      end

      def set_failure(bool)
        @failure = bool
      end

      def install(commands, stringio=nil)
        @started = true
        @completed = false

        if !@connection.nil?
          # remote install
          @connection.on_complete(lambda { set_completed(true) })
          @connection.on_failure(lambda { set_failure(true) })

          Thread.new {
            @connection.execute(commands, stringio)
          }
        else
          # local install
          set_failure(true) unless system(commands)
          set_completed(true)
        end
      end

      def check_ports(stringio=nil, ip='192.0.2.1')
        # closed ports 5385, 36357
        ports = [8774, 9292, 8777, 9696, 8004, 5000, 8585, 15672]
        ports.each do |p|
          if !@connection.nil?
            # remote check
            if !@connection.remote_port_open?(p, stringio)
              set_failure(true)
            end
          else
            # local check
            set_failure(true) unless !port_open?(ip, p, stringio)
          end
        end
      end
    end
  end
end
