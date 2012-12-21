require 'rubygems'
require 'data_mapper'

class AllowPost
  include DataMapper::Resource

  property :id,         Serial    # An auto-increment integer key
  property :next_post,  Time
end
