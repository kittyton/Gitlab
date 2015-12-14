module HttpHelper
  require 'net/http'
  require 'uri'
#Method name:send_http
#Des:Enclose Http request
#Author Name:liuqingqing
def send_http(url,data)  
    url = URI.parse(url)  
    req = Net::HTTP::Put.new(url.path,{'Content-Type' => 'application/json'})
    req.body = data  
    begin
    http=Net::HTTP.new(url.host,url.port)
    #set the connection  time threshold
    http.open_timeout=1
    res=http.request(req)
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~res.code=#{res.code}"
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~res.body=#{res.body}" 
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~request data = #{data}" 
    rescue
     Rails.logger.info "********************WRONG*****************************"
     Rails.logger.info "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  #{$!}"
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

#Method Name:construct_add_project_data
#Des: Enclose the add project related http request params
#Author Name:liuqingqing
def construct_add_project_data(projectId,projectName,projectCreator,projectDes,date)
  data={
         "id"=>projectId,
         "name"=>projectName,
         "user"=>projectCreator,
         "content"=>projectDes,
         "opDate"=>date}.to_json
end

#Method Name:construct_update_project_data
#Des: Enclose the update project related http request params
#Author Name:liuqingqing
def construct_update_project_data(projectId,projectMembers,date)
   data={
         "id"=>projectId,
         "user"=>projectMembers,
         "commitdate"=>date}.to_json
  
end

#Method Name:construct_add_mergeRequest_data
#Des: Enclose the add mergeRequest related http request params
#Author Name:liuqingqing
def construct_add_mergeRequest_data(id,title,projectId,date)
  data={
         "id"=>id,
         "title"=>title,
         "projectid"=>projectId,
         "commitdate"=>date}.to_json

end

#Method Name:construct_add_commit_data
#Des: Enclose the add commit related http request params
#Author Name:liuqingqing
def construct_add_commit_data(id,message,projectId,date)
   data={
         "id"=>id,
         "message"=>message,
         "projectid"=>projectId,
         "commitdate"=>date}.to_json
 
end

#Method Name:construct_add_issue_data
#Des: Enclose the add issue related http request params
#Author Name:liuqingqing
def construct_add_issue_data(id,title,projectId,date)
 data={
         "id"=>id,
         "title"=>title,
         "projectid"=>projectId,
         "commitdate"=>date}.to_json
end

end