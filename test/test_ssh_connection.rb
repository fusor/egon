require 'egon/undercloud/ssh-connection'

describe "SSHConnection" do

  it "should timeout if host unreachable" do
    connection = SSHConnection.new("194.0.0.0", "mock", "mock")
    message = connection.execute("ls")
    expect(message.to_s).to eq("execution expired")
  end

end
