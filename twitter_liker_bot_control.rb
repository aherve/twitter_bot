#!/usr/bin/env ruby

require 'bundler'
require 'daemons'
Bundler.setup(:default)

Daemons.run('twitter_liker_bot.rb')
