module HttpHelper
	#Method name:send_http
  #Des:Enclose Http request
  #Author Name:liuqingqing
def send_http(url,data)  
    url = URI.parse(url)  
    req = Net::HTTP::Put.new(url.path,{'Content-Type' => 'application/json'})
    req.body = data  
    #res = Net::HTTP.new(url.host,url.port).start{|http| http.request(req)}
    begin
    http=Net::HTTP.new(url.host,url.port)
    #set the connection  time threshold
    http.open_timeout=1
    res=http.request(req)
    log_info("response code:#{res.code}")
    log_info("response body:#{res.body}")
    log_info("request  data:#{data}")
    log_info("Mac   address:#{Mac.addr}")  
    rescue
    logger.info "*************************************************"
    logger.info "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  #{$!}"
    end                                                                                               
end 

#Method Name:construct_http_data
#Des:Enclose http request params
#Author Name:liuqingqing
def construct_http_data(appID,appVersion,fileID,fileName,filePath,opDate,opUser,opType,message,macIP,devInfo)
   http_data={"appID" =>appID,
               "appVersion" => appVersion,
               "fileID"=>fileID,
               "fileName"=>fileName,
               "filePath"=>filePath,
               "opDate"=>opDate,
               "opUser"=>opUser,
               "opType"=>opType,
               "message"=>message,
               "macIP"=>macIP,
               "devInfo"=>devInfo}.to_json
  
end

end