require 'egon/undercloud/commands'
require 'egon/undercloud/installer'

installer = Egon::Undercloud::Installer.new
installer.install(Egon::Undercloud::Commands.OSP7_no_registration)
installer.check_ports
