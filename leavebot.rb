require 'rubygems'
require 'data_mapper'
require 'net/http'
require 'json'
require 'yaml'
require  'dm-migrations'
require 'leave_post'

# A MySQL connection:
db_conf = YAML.load_file('./mysql.yml')
DataMapper.setup(:default, "mysql://#{db_conf['name']}:#{db_conf['password']}@#{db_conf['hostname']}/#{db_conf['db']}")
DataMapper.finalize
DataMapper.auto_upgrade!

source = Net::HTTP.get('www.reddit.com', '/search.json?q=i%27ll+just+leave+this+here')
search =  JSON.load source
results= search['data']['children']
results.each  do |result|
  post = Post.create(
      :title      => result['data']['title'],
      :subreddit  => result['data']['subreddit'],
      :post_id    => result['data']['id'],
      :over_18    => result['data']['over_18'],
      :thumbnail  => result['data']['thumbnail'],
      :permalink  => result['data']['permalink'],
      :url        => result['data']['url'],
      :author     => result['data']['author'],
      :score      => result['data']['score'],
      :created_at => Time.now
  )
  puts "title: #{post.title}, from #{post.uthor} in #{post.subreddit}.  url: #{post.url}\nNSFW=#{post.over_18}, post_id=#{post.post_id}, score=#{post.score}"
end