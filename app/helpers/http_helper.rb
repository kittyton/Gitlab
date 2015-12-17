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
    #http.open_timeout=1
    res=http.request(req)
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~res.code=#{res.code}"
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~res.body=#{res.body}" 
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~request data = #{data}" 
    rescue
     Rails.logger.info "********************WRONG*****************************"
     Rails.logger.info "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  #{$!}"
    end                                                                                               
end


#Method Name:delete_http
#Des: Enclose delete request without body
#Author Name:liuqingqing
def delete_http(url,data)
  uri = URI.parse(url)
  path="#{url}/#{data}"
  req = Net::HTTP::Delete.new(path) 
  begin
    http=Net::HTTP.new(uri.host,uri.port)
    #set the connection  time threshold
    #http.open_timeout=1
    res=http.request(req)
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~res.code=#{res.code}"
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~res.body=#{res.body}" 
    Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~request data = #{data}" 
    rescue
     Rails.logger.info "********************WRONG*****************************"
     Rails.logger.info "XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX  #{$!}"
    end       
end

#Method Name:delete_http
#Des: Enclose delete request with body
#Author Name:liuqingqing
def delete_http_with_body(url,data)
  url = URI.parse(url)  
  req = Net::HTTP::Delete.new(url.path,{'Content-Type' => 'application/json'})
  req.body = data  
  begin
    http=Net::HTTP.new(url.host,url.port)
    #set the connection  time threshold
    #http.open_timeout=1
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
def construct_add_mergeRequest_data(id,title,assignTo,status,projectId,des,date)
  data={
         "id"=>id,
         "title"=>title,
         "assignto"=>assignTo,
         "status"=>status,
         "projectid"=>projectId,
         "description"=>des,
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
def construct_add_issue_data(id,title,des,assignTo,projectId,date)
 data={
         "id"=>id,
         "title"=>title,
         "description"=>des,
         "assignto"=>assignTo,
         "projectid"=>projectId,
         "commitdate"=>date}.to_json
end

#Method Name:construct_delete_data
#Des: Enclose the delete data of issue mergeRequest commit
#Author Name: liuqingqing
def construct_delete_data(id,projectId)
  data={
         "id"=>id,  
         "projectid"=>projectId}.to_json
end

end