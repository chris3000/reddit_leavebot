require 'rubygems'

require 'data_mapper'
require 'net/http'
require 'json'
require 'yaml'
require  'dm-migrations'
require 'snoo'
require_relative 'leave_post.rb'

#parse out the comments url and the thing_id from a very convoluted JSON object that gets returned from reddit
def parse_reply raw_reply
  next_array= false
  comments = nil
  thing_id = nil
  raw_reply.each do |arr|
    if (arr.is_a?(Array) && arr.include?("call") && next_array)
      next_array = false
      arr.each do |comments_arr|
        if comments_arr.is_a?(Array)
          comments = comments_arr[0]
        end
      end
    end
    if (arr.include?("attr") && arr.include?("redirect"))
      next_array = true
    end
  end
  if comments
    id_start = comments.index("comments/") + 9
    id_end = comments.index("\/", id_start)
    thing_id = comments[id_start...id_end]
  end
  thing_id
end

# A MySQL connection:
db_conf = YAML.load_file('./mysql.yml')
DataMapper.setup(:default, "mysql://#{db_conf['name']}:#{db_conf['password']}@#{db_conf['hostname']}/#{db_conf['db']}")
DataMapper.finalize

reddit_conf = YAML.load_file('./reddit.yml')
# Create a new instance of the client
reddit = Snoo::Client.new
# Log into reddit
reddit.log_in reddit_conf['lb_username'], reddit_conf['lb_password']

next_post = Post.first({:posted => false})
title= "#{next_post.title} [#{next_post.subreddit}]"
if (next_post.over_18 || next_post.title.downcase.include?("nsfw") )
  title << " [NSFW]"
end
url = next_post.url
if (url && next_post.title && next_post.subreddit)
  reply = reddit.submit "test5", "sandbox", {:url => "http://i.imgur.com/Iqtvx.jpg"}
  puts "got reply: #{reply.parsed_response['jquery']}"
  comments_id = parse_reply reply.parsed_response['jquery']
  puts title +"  "+url
  if comments_id
    puts "posting comment to #{comments_id}"
    reddit.comment "this is a test of commenting", comments_id
  else
    puts "comments is nil, so not posting comment"
    puts "by the way, this is what I got back from reddit:"
    puts reply
  end
end
next_post.posted = true
next_post.save
reddit.log_out

