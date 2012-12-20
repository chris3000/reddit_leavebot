require 'rubygems'

require 'data_mapper'
require 'net/http'
require 'json'
require 'yaml'
require  'dm-migrations'
require 'snoo'
require_relative 'leave_post.rb'

# A MySQL connection:
db_conf = YAML.load_file('./mysql.yml')
DataMapper.setup(:default, "mysql://#{db_conf['name']}:#{db_conf['password']}@#{db_conf['hostname']}/#{db_conf['db']}")
DataMapper.finalize
DataMapper.auto_upgrade!

#get last record
last_post = Post.last
reddit_conf = YAML.load_file('./reddit.yml')
# Create a new instance of the client
reddit = Snoo::Client.new
# Log into reddit
reddit.log_in reddit_conf['lb_username'], reddit_conf['lb_password']
search_args = {:limit => 100, :sort => "relevance" }
search_args[:after] = last_post.name if last_post
puts search_args
search= reddit.search "i'll just leave this here", search_args
results = search['data']['children']
reddit.log_out

results.each  do |result|
  post = Post.first_or_create({ :post_id => result['data']['id'] }, {
      :title      => result['data']['title'],
      :subreddit  => result['data']['subreddit'],
      :post_id    => result['data']['id'],
      :name       => result['data']['name'],
      :over_18    => result['data']['over_18'],
      :thumbnail  => result['data']['thumbnail'],
      :permalink  => result['data']['permalink'],
      :url        => result['data']['url'],
      :author     => result['data']['author'],
      :score      => result['data']['score'],
      :created_at => Time.now
  })
  puts "title: #{post.title}, from #{post.author} in #{post.subreddit}.  url: #{post.url}\nNSFW=#{post.over_18}, post_id=#{post.post_id}, score=#{post.score}"
end

