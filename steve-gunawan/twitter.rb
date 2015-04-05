# Steve Gunawan
# MediaMath Developer Relations Engineer task

require 'rubygems'
require 'oauth'
require 'json'
require 'date'

# Parse user response from the API
def parse_user_response(response)
  user = nil

  # Check for a successful request
  if response.code == '200'
    # Parse the response body, which is in JSON format.
    user = JSON.parse(response.body)
   
    # Print the user screen_name for confirmation
    puts 'Stats for ' + user["screen_name"]
  else
    # There was an error issuing the request.
    puts 'Expected a response of 200 but got #{response.code} instead'
  end
end


# Parse friends' list response from the API and return hash table containing [id,screen_name] of friends.
def parse_user_friends(response)
  users = nil
  sum = 0     #variable to store total of friends' account age
  count = 0   #variable to store number of friends
  usersList = Hash.new  #hash table variable to store [id,screen_name]

  # Check for a successful request
  if response.code == '200'
    # Parse the response body, which is in JSON format.
    users = JSON.parse(response.body)["users"]

    # For each user, store the user info in hash table, calculate account age, and then add to sum variable
    users.each do |user|
      # Add user to hash table with Twitter user id as key and screen_name as value. We will use this info later to get tweets of each user.
      usersList[user["id"]] = user["screen_name"]

      # Calculate account age (in days)
      age = DateTime.now-DateTime.parse(user["created_at"])
      
      # Add the account age in years to the sum variable 
      sum += age/365
      
      # Increase the count of number of friends
      count += 1
    end

    # Print Statistics
    if count > 0
      puts 'Average account age of friends = ' + (sum/count).to_f.round(2).to_s + ' years'
    else
      puts 'No friends found, thus average account age of friends is N/A'
    end
    return usersList
  else
    # There was an error issuing the request.
    puts 'Expected a response of 200 but got #{response.code} instead'
  end
end

# Parse user's timeline response from the API and return an array containing [max_id,tweetCount,retweetCount] of current response.
def parse_user_tweets(response)
  maxID = nil      #variable to store the maxID of the current request, will be used to requery to get the next list of tweets on user's timeline
  tweetCount = 0    #variable to store the total number of tweets in this response
  retweetCount = 0  #variable to store the total number of retweets in this response
  
  # Check for a successful request
  if response.code == '200'
    # Parse the response body, which is in JSON format.
    tweets = JSON.parse(response.body)

    # For each tweet, check the timestamp to make sure we're only including the data from the past 7 days then increase count as needed
    tweets.each do |tweet|
        if DateTime.parse(tweet["created_at"]) > DateTime.now-7
            
            # Tweet is from the past 7 days, increase count
            tweetCount += 1
            
            maxID = tweet["id"]-1    # Subtract 1 before storing maxID so the next request won't include duplicate
            
            # Check if tweet contains retweeted_status info
            if tweet["retweeted_status"] != nil
                # Increase count if tweet is verified as a retweet
                retweetCount += 1
            end
        end
    end
    
    # Return result as an array of maxID, count of number of tweets, and count of number of retweets
    return [maxID, tweetCount, retweetCount]
  else
    # There was an error issuing the request.
    puts 'Expected a response of 200 but got #{response.code} instead'
  end
end


# All requests will be sent to this server.
baseurl = "https://api.twitter.com/1.1"
address = URI("#{baseurl}")

# Set up HTTP.
http             = Net::HTTP.new address.host, address.port
http.use_ssl     = true
http.verify_mode = OpenSSL::SSL::VERIFY_PEER

# API credentials
consumer_key = OAuth::Consumer.new(
    "g5eEPOg3lS3zmrBHFqiGhLkvP",
    "gZcTAXn9EDWF8GD2VQEs7QEkkfTCHpCCjnRXpfXS4Jh1ArpH2K")
access_token = OAuth::Token.new(
    "15100385-cbGhlhtEZGSuw6zwrgROcH1FOJL9HZVpNzCL0dXHj",
    "3bWXB7Y4bM2drA0hmrOMJMGlYx3glvoGWbYZXbSZj3dcx")
    
# Verify credentials returns the current user in the body of the response
address = URI("#{baseurl}/account/verify_credentials.json")
request = Net::HTTP::Get.new address.request_uri
request.oauth! http, consumer_key, access_token
http.start
response = http.request(request)
user = parse_user_response(response)

# Request list of friends / people followed by the user
address = URI("#{baseurl}/friends/list.json")
request = Net::HTTP::Get.new address.request_uri
request.oauth! http, consumer_key, access_token
response = http.request(request)
usersList = parse_user_friends(response)

# For each of friends, request the friend's timeline to count number of tweets and retweets
usersList.each do |id,user|

    # For very first request of a user's timeline, just do a simple request without max_id to get the first page of tweets. 
    query = URI.encode_www_form(
        "screen_name" => user,
        "count" => 200,     #max count is 200, use max to reduce API call
        "include_rts" => true
    )
    address = URI("#{baseurl}/statuses/user_timeline.json?#{query}")
    request = Net::HTTP::Get.new address.request_uri
    request.oauth! http, consumer_key, access_token
    response = http.request(request)
    
    # Returned variable is an array, break it down to individual data component
    maxID_tweetCount_retweetCount = parse_user_tweets(response)
    maxID = maxID_tweetCount_retweetCount[0]
    tweetCount = maxID_tweetCount_retweetCount[1]
    retweetCount = maxID_tweetCount_retweetCount[2]

    # For subsequent request of a user's timeline, pass max_id from previous request to get the next page of tweets. Loop will stop when the response is empty, thus nil maxID
    while maxID != nil
        query = URI.encode_www_form(
            "screen_name" => user,
            "count" => 200,     #max count is 200, use max to reduce API call
            "include_rts" => true,
            "max_id" => maxID
        )
        address = URI("#{baseurl}/statuses/user_timeline.json?#{query}")
        request = Net::HTTP::Get.new address.request_uri
        request.oauth! http, consumer_key, access_token
        response = http.request(request)

        # Returned variable is an array, break it down to individual data component
        maxID_tweetCount_retweetCount = parse_user_tweets(response)
        maxID = maxID_tweetCount_retweetCount[0]
        
        # Add tweetCount of the new response to the previous cumulative total of tweetCount
        tweetCount += maxID_tweetCount_retweetCount[1]

        # Add retweetCount of the new response to the previous cumulative total of retweetCount
        retweetCount += maxID_tweetCount_retweetCount[2]
    end

    # Calculate average number of tweets by dividing the total number of tweets by 7, then do a rounding for readability    
    tweetAvg = (tweetCount.to_f/7).round(2)    
    puts 'Average Tweets/day for #{user} \t = ' + tweetCount.to_s + '/7 = ' + tweetAvg.to_s

    # Calculate average number of retweets by dividing the total number of retweets by 7, then do a rounding for readability
    retweetAvg = (retweetCount.to_f/7).round(2)
    puts 'Average ReTweets/day for #{user} \t = ' + retweetCount.to_s + '/7 = ' + retweetAvg.to_s

end
