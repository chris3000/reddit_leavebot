require 'rubygems'
require 'data_mapper'
require 'net/http'
require 'json'

# A MySQL connection:
DataMapper.setup(:default, 'mysql://user:password@hostname/database')
source = Net::HTTP.get('www.reddit.com', '/search.json?q=i%27ll+just+leave+this+here')
search =  JSON.load source
results= search['data']['children']
results.each  do |result|
  title= result['data']['title']
  subreddit = result['data']['subreddit']
  post_id = result['data']['id']
  over_18 = result['data']['over_18']
  thumbnail = result['data']['thumbnail']
  permalink = result['data']['permalink']
  url = result['data']['url']
  author = result['data']['author']
  score = result['data']['score']
  puts "title: #{title}, from #{author} in #{subreddit}.  url: #{url}\nNSFW=#{over_18}, post_id=#{post_id}, score=#{score}"
end