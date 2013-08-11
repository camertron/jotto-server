class PushNotifier

  # 'gateway.sandbox.push.apple.com', 2195
  # 'gateway.push.apple.com', 2195
  attr_reader :host, :port, :environment

  def initialize(host, port, environment)
    @host = host
    @port = port
    @environment = environment
  end

  def notify_device(device_token, json_payload)
    return unless device_token
    device_token = [device_token].pack("H*")
    notification_packet = notification_packet_for(device_token, json_payload)
    socket = TCPSocket.new(host, port)
    ssl = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
    ssl.connect
    ssl.write(notification_packet)
    ssl.close
    socket.close
  end

  private

  def ssl_context
    context = OpenSSL::SSL::SSLContext.new
    context.cert = OpenSSL::X509::Certificate.new(certificate)
    context.key = OpenSSL::PKey::RSA.new(certificate)
    context
  end

  def notification_packet_for(device_token, json_payload)
    [0, 0, 32, device_token, 0, json_payload.size, json_payload].pack("ccca*cca*")
  end

  def certificate
    @certificate ||= begin
      pem_contents = ENV["APS_#{environment.upcase}_PEM"].gsub("\\n", "\n")
      Base64.decode64(pem_contents)
    end
  end

end