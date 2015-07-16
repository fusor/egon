module Egon
  module Undercloud
    class Installer
      attr_reader :started
      alias_method :started?, :started
    
      def initialize(connection)
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
    
      def install(commands)
        @started = true
        @completed = false
             
        @connection.on_complete(lambda { set_completed(true) })
        @connection.on_failure(lambda { set_failure(true) })
    
        Thread.new {
          @connection.execute(commands)
        }
      end

      def check_ports
        # closed ports 5385, 36357
        ports = [8774, 9292, 8777, 9696, 8004, 5000, 8585, 15672]
        ports.each do |p|
          if !@connection.port_open?(p)
            set_failure(true)
          end
        end
      end
    end
  end
end
