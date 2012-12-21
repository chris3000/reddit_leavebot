require 'rubygems'
require 'data_mapper'

class Post
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :title, Text
  property :subreddit, String
  property :post_id, String, :unique => true
  property :name, String
  property :over_18, Boolean
  property :thumbnail, Text
  property :permalink, Text
  property :url, Text
  property :author, String
  property :score, Integer
  property :posted, Boolean, :default => false
  property :created_at, DateTime  # A DateTime, for any date you might like.
end
