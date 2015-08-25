require 'net/http'

module Egon
  module Undercloud
    module PortCheckMixin

      def stringio_write(stringio, text)
        $stdout.puts text if stringio.nil?
        stringio.puts text unless stringio.nil?
      end

      def port_open?(ip, port, stringio=nil)
        begin
          url = "http://#{ip}:#{port}"
          stringio_write(stringio, "Testing #{url}")
          res = Net::HTTP.get_response(URI(url))
          stringio_write(stringio, res.body)
          stringio_write(stringio, "Port #{port} is open")
          true
        rescue => e
          stringio_write(stringio, e.message)
          stringio_write(stringio, e.backtrace)
          stringio_write(stringio, "Port #{port} is closed")
          false
        end
      end
    end
  end
end
