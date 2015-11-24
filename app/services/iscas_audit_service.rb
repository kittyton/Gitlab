module IscasAuditService
	include HttpHelper

  #Method name:record_gitlab_related_operation
  #Des:Enclose record gitlab related operation to audit
  #Author Name:liuqingqing
  def record_gitlab_related_operation(opUser,opType,fileID,fileName,filePath)
    url="#{IscasSettings.audit_url}"
    if opType=="createUser"
      opUser="userRegister"
      if(self.created_by!=nil)
        opUser=self.created_by
      end
    end
    data=construct_http_data("appID","v2.0",fileID,fileName,filePath,Time.now.strftime("%Y-%m-%d %H:%M:%S"),
      opUser.username,opType,"This is a #{opType} event",Mac.addr,"liuqingqing")
    send_http(url,data)
  end
end