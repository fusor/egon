require 'egon/undercloud/commands'
require 'egon/undercloud/ssh-connection'
require 'egon/undercloud/installer'

SSH_HOST = ARGV[0]
SSH_USER = ARGV[1]
SSH_PASSWORD = ARGV[2]

RHSM_USER = ARGV[3]
RHSM_PASSWORD = ARGV[4]
RHSM_POOL_ID = ARGV[5]

connection = Egon::Undercloud::SSHConnection.new(SSH_HOST, SSH_USER, SSH_PASSWORD)
installer = Egon::Undercloud::Installer.new(connection)
installer.install(Egon::Undercloud::Commands.OSP7_vanilla_rhel(RHSM_USER, RHSM_PASSWORD, RHSM_POOL_ID))
while !installer.completed?
  sleep 1
end  
