module IscasAuditService
	
  #Method name:send_http
  #Des:Enclose Http request
  #Author Name:liuqingqing
def record_user_related_operation(opType)
  #The audit interface url
  #url="#{AuditSettings.audit_url}"
  url="#{IscasSettings.audit_url}"
  #Handle user register
  opUser="userRegister"
  #Record the create user operation by the audit interface
  if(self.created_by!=nil)
    opUser=self.created_by.username
  end
    data=construct_http_data("appID","V2.0",self.id,self.name,"this is the path",Time.now.strftime("%Y-%m-%d %H:%M:%S"),
    opUser,opType,"This is a #{opType} event",Mac.addr,"liuqingqing")
    send_http(url,data)
  end
end