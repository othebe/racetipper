require 'net/http'

url = 'https://worker-aws-us-east-1.iron.io/2/projects/516968bc2267d85351001a8d/tasks/webhook?code_name=add_participants_to_global_competition&oauth=sDMGz4n9RX85PZoi27Y4CuCHcNk'
uri = URI.parse(url)
req = Net::HTTP::Post.new(url)
res = Net::HTTP.start(
	uri.host, uri.port, 
	:use_ssl => true,
	:verify_mode => OpenSSL::SSL::VERIFY_PEER,
	:ca_file => File.join('..', "cacert.pem")) {|http| http.request(req)}
puts res.body