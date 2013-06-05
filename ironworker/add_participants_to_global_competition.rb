require 'net/http'

url = URI.parse('http://racetipper.herokuapp.com/competitions/add_participants_to_global_competition')
req = Net::HTTP::Get.new(url.path)
res = Net::HTTP.start(url.host, url.port) {|http|
  http.request(req)
}
puts res.body