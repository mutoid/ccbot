SLACK_DOMAIN = ENV['SLACK_DOMAIN']
SLACKBOT_ENDPOINT = ENV['SLACKBOT_ENDPOINT']
SLACKBOT_TOKEN = ENV['SLACKBOT_TOKEN']
WEBHOOK_TOKEN = ENV['WEBHOOK_TOKEN']

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
    nil
  end

  def topic(new_topic)
    endpoint = 'channels.setTopic'
    post_to_webhook(endpoint, 'topic' => new_topic)
  end

  private

  def post_to_webhook(endpoint, params = {})
    begin
      params['token'] = WEBHOOK_TOKEN
      params['channel'] = @channel
      uri = URI.parse("https://slack.com/api/#{endpoint}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(params)
      response = http.request(request)
    rescue StandardError => e
      # logger.info "Got exception #{e}"
      puts "WTF!"
      raise e
    end
    "Done"
  end
end
