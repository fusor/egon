#! /usr/bin/ruby
require 'egon/undercloud/commands'
require 'egon/undercloud/installer'

installer = Egon::Undercloud::Installer.new
installer.install(Egon::Undercloud::Commands.OSP8_no_registration)
if installer.failure?
  exit 1
else
  installer.check_ports
end
