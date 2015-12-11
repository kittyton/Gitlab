module IscasSearchService
	include HttpHelper

  #Method name:addProject
  #Des:Enclose the addProject operation to search interface
  #Author Name:liuqingqing
  def addProject(projectId,projectName,projectCreator,projectDes,date)
    url="#{IscasSettings.codeSearch_url}/project/"
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
  def addMergeRequest(id,title,projectId,date)
    url="#{IscasSettings.codeSearch_url}/merge"
    data=construct_add_mergeRequest_data(id,title,projectId,date)
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
  def addIssue(id,title,projectId,date)
    url="#{IscasSettings.codeSearch_url}/issue"
    data=construct_add_issue_data(id,title,projectId,date)
    send_http(url,data)
  end

end