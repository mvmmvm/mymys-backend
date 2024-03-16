class ApplicationController < ActionController::API
  # def take_name(count)
  #   url = "https://green.adam.ne.jp/roomazi/cgi-bin/randomname.cgi?n=#{count}&callback=players"
  #   uri = URI.parse(url)
  #   request = Net::HTTP::Get.new(uri)
  #   response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
  #       http.request(request)
  #   end
  #   body = response.body
  #   callback_name = 'players' 
  #   parsed_data = JSON.parse(body.sub(/^#{callback_name}\((.*)\)$/, '\1'))
  #   parsed_data["name"].each do |name|
  #     
  #   end
  # end
end
