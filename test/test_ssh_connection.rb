require 'egon/undercloud/ssh-connection'
require 'stringio'

describe "SSHConnection" do

  it "should timeout if host unreachable" do
    connection = Egon::Undercloud::SSHConnection.new("194.0.0.0", "mock", "mock")
    io = StringIO.new
    message = connection.execute("ls", io)
    expect(io.string.strip!).to eq("execution expired")
  end

end
