#!/usr/bin/env ruby

require 'bundler'
require 'twitter'
require 'pry'
require 'yaml'
Bundler.setup(:default)

class TwitterLikerBot

  def credentials
    @creds ||= YAML.load_file(
      File.expand_path('../credentials.yml',__FILE__)
    )
  end

  def sleep_for
    credentials["settings"]["sleep_for_in_minutes"].to_i * 60
  end

  def min_favorites_count
    credentials["settings"]["min_favorites_count"]
  end

  def min_retweets_count
    credentials["settings"]["min_retweets_count"]
  end

  def last_tweets_count
    credentials["settings"]["last_tweets_count"].to_i
  end

  def time_limit_in_seconds
    credentials["settings"]["time_limit_in_minutes"].to_i * 60
  end

  def client
    @client ||= Twitter::REST::Client.new do |config|
      config.consumer_key        = credentials["twitter_creds"]["consumer_key"]
      config.consumer_secret     = credentials["twitter_creds"]["consumer_secret"]
      config.access_token        = credentials["twitter_creds"]["access_token"]
      config.access_token_secret = credentials["twitter_creds"]["access_token_secret"]
    end
  end

  def timeline_selection
    client.home_timeline(count: last_tweets_count)
    .select{|t| t.created_at > Time.now - time_limit_in_seconds}
    .select{|t| t.retweet_count > min_retweets_count and t.favorite_count > min_favorites_count}
    .reject(&:favorited?)
  end

  def favorite_feed_selection!
    puts "favoriting tweets"
    # Favorite already favorited tweets:
    timeline_selection.each{|t| 
      print "favoriting tweet #{t} ..." ;
      client.favorite t
      print "...done\n"
    }
    puts 'favoriting done'
  end

  def sleep!
    puts "going to sleep for #{sleep_for/60} minutes"
    sleep(sleep_for)
  end

  def self.favorite_feed_selection!
    self.new.favorite_feed_selection!
  end

  def self.loop_favorite_feed_selection!
    loop do 
      tw = TwitterLikerBot.new
      tw.favorite_feed_selection!
      tw.sleep!
    end
  end

end

TwitterLikerBot.loop_favorite_feed_selection!
