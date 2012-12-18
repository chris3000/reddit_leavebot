require 'rubygems'
require 'data_mapper' # requires all the gems listed above

class Post
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :title, String
  property :subreddit, String
  property :post_id, String #unique?
  property :over_18, Boolean
  property :thumbnail, String
  property :permalink, String
  property :url, String
  property :author, String
  property :score, Integer
  property :created_at, DateTime  # A DateTime, for any date you might like.
end
