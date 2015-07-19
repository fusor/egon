require 'egon/undercloud/installer'
require 'egon/undercloud/ssh-connection'
require 'egon/undercloud/commands'
require 'net/ssh'
require 'net/ssh/connection/session'

def run_and_assert_installer(installer, failure)
    expect(installer.started?).to be false
    expect(installer.completed?).to be false
    expect(installer.failure?).to be false
    sleep_count = 0
    installer.install("ls")
    # installer runs in the background if sleep_count > 0
    while !installer.completed?
      expect(installer.started?).to be true
      sleep 1
    end
    expect(installer.started?).to be true
    expect(installer.completed?).to be true
    expect(installer.failure?).to be failure
end

describe "undercloud installer" do

  before do
    @connection = Egon::Undercloud::SSHConnection.new("194.0.0.0", "mock", "mock")
    @installer = Egon::Undercloud::Installer.new(@connection)
  end

  it "installer should run in background and not fail" do
    allow(@connection).to receive(:execute) { @connection.call_complete }
    run_and_assert_installer(@installer, false)
  end

  it "exception raised by ssh should indicate failure" do
    allow(Net::SSH).to receive(:start) { raise "Error in ssh" }
    run_and_assert_installer(@installer, true)
  end

  it "connection should timeout and installer indicate failure" do
    run_and_assert_installer(@installer, true)
  end

  it "check ports should fail on mock connection" do
    @installer.check_ports
    expect(@installer.failure?).to be true
  end

  it "consume stdout and stderr from commands" do
    io = StringIO.new
    @installer.install("time", io)
    while !@installer.completed?
      sleep 1
    end
    expect(io.string).to include("execution expired")

    io = StringIO.new
    @installer.check_ports(io)
    expect(io.string).to include("Testing")
  end
end
  
