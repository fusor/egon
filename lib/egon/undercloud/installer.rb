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
    end
  end
end
