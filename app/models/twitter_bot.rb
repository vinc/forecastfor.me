class TwitterBot
  def initialize
    config = {
      consumer_key:         ENV['TWITTER_CONSUMER_KEY'],
      consumer_secret:      ENV['TWITTER_CONSUMER_SECRET'],
      access_token:         ENV['TWITTER_ACCESS_TOKEN'],
      access_token_secret:  ENV['TWITTER_ACCESS_TOKEN_SECRET']
    }
    @rest_client = Twitter::REST::Client.new(config)
    @streaming_client = Twitter::Streaming::Client.new(config)
  end

  def listen
    username = @rest_client.user.screen_name
    @streaming_client.filter(track: username) do |tweet|
      if tweet.text =~ Regexp.new("@#{username}", Regexp::IGNORECASE)
        Rails.logger.info("Received tweet from @#{tweet.user.screen_name}: '#{tweet.text}'")

        time = self.parse_time(tweet)
        coordinates = self.parse_coordinates(tweet)
        if time && coordinates
          lat, lon = coordinates
          bulletin = GFS.last.bulletin(longitude: lon, latitude: lat)

          self.tweet_bulletin(tweet, bulletin)
        end
      end
    end
  end

  def tweet_bulletin(tweet, bulletin)
    text = I18n.t('bulletin_tweet',
      user: tweet.user.screen_name,
      weather: bulletin.weather,
      temperature: bulletin.temperature,
      wind: bulletin.wind
    )
    @rest_client.update(text, { in_reply_to_status: tweet })
    Rails.logger.info("Sent tweet: '#{text}'")
  end

  def parse_time(tweet)
    Chronic.parse(tweet.text[/for (\S+( (?!in)\S+)*)/i, 1])
  end

  def parse_coordinates(tweet)
    location =
      if tweet.place?
        [tweet.place.name, tweet.place.country].join(', ')
      elsif tweet.geo?
        tweet.geo.coordinates.join(', ')
      elsif tweet.text =~ / in (.+)/
        Regexp.last_match[1]
      end

    Geocoder.search(location).first.try(:coordinates)
  end
end
