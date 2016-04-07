SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']

class Chat
  def initialize(channel)
    @channel = channel
  end

  def chat_out(message)
    begin
      uri = URI.parse("#{SLACK_DOMAIN}#{SLACKBOT_ENDPOINT}?token=#{SLACKBOT_TOKEN}&channel=#{@channel}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri)
      request.body = message
      response = http.request(request)
    rescue StandardError => e
      logger.info "Got exception #{e}"
      puts "WTF!"
      raise e
    end
  end
end
