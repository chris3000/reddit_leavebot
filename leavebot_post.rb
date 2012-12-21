require 'rubygems'

require 'data_mapper'
require 'net/http'
require 'json'
require 'yaml'
require  'dm-migrations'
require 'snoo'
require_relative 'leave_post.rb'
require_relative 'allow_post.rb'
#set up logger
require 'logger'
this_path = File.expand_path(File.dirname(__FILE__))
log_path = File.join(this_path,'logs/leavebot_post.log')
logger = Logger.new(log_path, 'weekly')
logger.level = Logger::INFO
#parse out the comments url and the thing_id from a very convoluted JSON object that gets returned from reddit

#fix snoo to send api_type: json on comments
module Snoo
  class Client
    def comment text, id
      logged_in?
      post('/api/comment', body: { text: text, thing_id: id, uh: @modhash, api_type: 'json'})
    end
  end
end

def parse_errors rep_json
  logger.error "Got some errors from Reddit on submission:"
  if reply_json['ratelimit']
    #do something to halt posting
    wait_seconds = rep_json['ratelimit']
    logger.error "I need to wait #{wait_seconds} seconds until I can post again"
    next_allowed_post.next_post = Time.now + wait_seconds
    next_allowed_post.save
  end
  rep_json['errors'].each do |error|
    error_type = error[0]
    error_msg = error[1]
    logger.error "Error Type: #{error_type}, '#{error_msg}'"
    if error_type.downcase.include? "QUOTA"
      #set for 1 hour
      next_allowed_post.next_post = Time.now + 600
      next_allowed_post.save
    end
  end
end

# A MySQL connection:
db_conf = YAML.load_file('./mysql.yml')
DataMapper.setup(:default, "mysql://#{db_conf['name']}:#{db_conf['password']}@#{db_conf['hostname']}/#{db_conf['db']}")
DataMapper.finalize
DataMapper.auto_upgrade!

reddit_conf = YAML.load_file('./reddit.yml')
# Create a new instance of the client
reddit = Snoo::Client.new(reddit_conf['url'], reddit_conf['user_agent'])

#do I need to pause?
next_allowed_post = AllowPost.first_or_create({},{:next_post => (Time.now-10)})
if next_allowed_post.next_post > Time.now
  pause_sec = (next_allowed_post - Time.now).to_i
  logger.warn "pausing #{pause_sec} seconds"
  sleep pause_sec if pause_sec > 0
end

# Log into reddit
reddit.log_in reddit_conf['lb_username'], reddit_conf['lb_password']
#grab a random posting
next_post = Post.first({:posted => false, :offset => rand(Post.count(:posted => false))})
title= "#{next_post.title} [#{next_post.subreddit}]"
if (next_post.over_18 || next_post.title.downcase.include?("nsfw") )
  title << " [NSFW]"
end
url = next_post.url
post_success = false
if (url && next_post.title && next_post.subreddit)
  reply = reddit.submit title, "illjustleavethishere", {:url => url, :api_type => "json"}
  logger.debug "submission reply: #{reply}"
  reply_json = reply.parsed_response['json']
  if reply_json['errors'].empty? #it succeeded!
    post_success = true
    submit_name = reply_json['data']['name']
    sleep 2
    comment_md = "Originally submitted [here](#{next_post.permalink}) by user [#{next_post.author}](/u/#{next_post.author})."
    comment_reply = reddit.comment comment_md, submit_name
    logger.debug "here's the reply from reddit on comment submission..."
    logger.debug comment_reply
    comment_reply_json = comment_reply.parsed_response['json']
    if comment_reply_json['errors'].empty?  #comment posting was successful!
      comment_id = comment_reply_json['data']['things'][0]['data']['id']
      logger.debug "comment_id = #{comment_id}"
      if comment_id
        sleep 2
        reddit.distinguish comment_id, :yes
        logger.info "successfully posted #{reply_json}"
      else
        logger.error "distinguish not set because comment_id was not parsed"
      end

    else #comment errors!
      parse_errors comment_reply_json
    end
  else  #errors!
    parse_errors reply_json
  end
end
if post_success
  next_post.posted = true
  next_post.save
end
sleep 2
reddit.log_out

