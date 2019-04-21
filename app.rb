require 'bundler'
require 'json'
Bundler.require

if Sinatra::Base.production?
  configure do
    redis_uri = URI.parse(ENV['REDISCLOUD_URL'])
    REDIS = Redis.new(host: redis_uri.host, port: redis_uri.port, password: redis_uri.password)
  end
  rabbit = Bunny.new(ENV['CLOUDAMQP_URL'])
  EVEN_OR_ODD = ENV['EVEN_OR_ODD']
else
  REDIS = Redis.new
  rabbit = Bunny.new(automatically_recover: false)
  set :port, ARGV[0].to_i
  EVEN_OR_ODD = ARGV[1]
end

rabbit.start
channel = rabbit.create_channel
RABBIT_EXCHANGE = channel.default_exchange

NEW_TWEET_QUEUE = channel.queue("new_tweet.tweet_html.#{EVEN_OR_ODD}")

NEW_TWEET_QUEUE.subscribe(block: false) do |delivery_info, properties, body|
  write_tweet(JSON.parse(body))
end

def write_tweet(body)
  tweet_id = body['tweet_id']
  tweet_html = '' # TODO: Write HTML
  REDIS.set(tweet_id, tweet_html)
end

# TODO: Write route to return tweet as HTML, determine failure case
# Route: /get_tweet/:tweet_id
