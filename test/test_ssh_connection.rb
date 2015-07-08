require 'egon/undercloud/ssh-connection'
require 'stringio'

describe "SSHConnection" do

  it "should timeout if host unreachable" do
    connection = Egon::Undercloud::SSHConnection.new("194.0.0.0", "mock", "mock")
    io = StringIO.new
    message = connection.execute("ls", io)
    expect(io.string.strip!).to eq("execution expired")
  end

  it "check port is open" do
    connection = Egon::Undercloud::SSHConnection.new("127.0.0.1", "stack", "test")
    connection.port_open?(1111).should eq false
    end
end
