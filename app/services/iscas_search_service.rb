module IscasSearchService
	include HttpHelper

  #Method name:addProject
  #Des:Enclose the addProject operation to search interface
  #Author Name:liuqingqing
  def addProject(projectId,projectName,projectCreator,projectDes,date)
    url="#{IscasSettings.codeSearch_url}/project"
    data=construct_add_project_data(projectId,projectName,projectCreator,projectDes,date)
    send_http(url,data)
  end

  #Method name:updateProject
  #Des:Enclose the updateProject operation to search interface
  #Author Name:liuqingqing
  def updateProject(projectId,projectMember,date)
    url="#{IscasSettings.codeSearch_url}/project/update"
    data=construct_update_project_data(projectId,projectMember,date)
    send_http(url,data)
  end

  #Method name:addMergeRequest
  #Des:Enclose the addMergeRequest operation to search interface
  #Author Name:liuqingqing
  def addMergeRequest(id,title,assignTo,status,projectId,des,date)
    url="#{IscasSettings.codeSearch_url}/merge"
    data=construct_add_mergeRequest_data(id,title,assignTo,status,projectId,des,date)
    send_http(url,data)
  end

  #Method name:addCommit
  #Des:Enclose the addCommit operation to search interface
  #Author Name:liuqingqing
  def addCommit(id,message,projectId,date)
    url="#{IscasSettings.codeSearch_url}/commit"
    data=construct_add_commit_data(id,message,projectId,date)
    send_http(url,data)

  end

  #Method name:addIssue
  #Des:Enclose the addIssue operation to search interface
  #Author Name:liuqingqing
  def addIssue(id,title,des,assignTo,projectId,date)
    url="#{IscasSettings.codeSearch_url}/issue"
    data=construct_add_issue_data(id,title,des,assignTo,projectId,date)
    send_http(url,data)
  end

 #Method name:deleteProject
 #Des:Enclose the deleteProject operation to search interface
 #Author Name:liuqingqing
 def deleteProject(id)
  url="#{IscasSettings.codeSearch_url}/project/delete"
  delete_http(url,id)
 end

 #Method name:deleteIssue
 #Des:Enclose the deleteIssue operation to search interface
 #Author Name:liuqingqing
 def deleteIssue(id,projectId)
  url="#{IscasSettings.codeSearch_url}/issue/delete"
  data=construct_delete_data(id,projectId)
  delete_http_with_body(url,data)
 end


 #Method name:deleteMergeRequest
 #Des:Enclose the deleteMergeRequest operation to search interface
 #Author Name:liuqingqing
 def deleteMergeRequest(id,projectId)
  url="#{IscasSettings.codeSearch_url}/merge/delete"
  data=construct_delete_data(id,projectId)
  delete_http_with_body(url,data)
 end


 #Method name:deleteCommit
 #Des:Enclose the deleteCommit operation to search interface
 #Author Name:liuqingqing
 def deleteCommit(id,projectId)
  url="#{IscasSettings.codeSearch_url}/commit/delete"
  data=construct_delete_data(id,projectId)
  delete_http_with_body(url,data)
 end

end