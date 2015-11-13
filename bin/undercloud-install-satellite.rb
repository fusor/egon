#! /usr/bin/ruby
require 'egon/undercloud/commands'
require 'egon/undercloud/ssh-connection'
require 'egon/undercloud/installer'

SSH_HOST = ARGV[0]
SSH_USER = ARGV[1]
SSH_PASSWORD = ARGV[2]

# Satellite URL
# https://server
SATELLITE_URL = ARGV[3]
SATELLITE_ORG = ARGV[4]
SATELLITE_ACTIVATION_KEY = ARGV[5]

connection = Egon::Undercloud::SSHConnection.new(SSH_HOST, SSH_USER, SSH_PASSWORD)
installer = Egon::Undercloud::Installer.new(connection)
installer.install(Egon::Undercloud::Commands.OSP7_satellite(SATELLITE_URL, SATELLITE_ORG, SATELLITE_ACTIVATION_KEY))
while !installer.completed?
  sleep 1
end  
installer.check_ports
