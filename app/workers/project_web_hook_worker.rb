class ProjectWebHookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :project_web_hook

  def perform(hook_id, data, hook_name)
  	
    data = data.with_indifferent_access
    
    #add data in web_hook to return the data value
    #judge the value of webHook's task_id
    #if nil, execute
    #if has a value, iscas_execute

    if WebHook.find(hook_id).task_id == nil
    	WebHook.find(hook_id).execute(data, hook_name)    	    	

    else
    	WebHook.find(hook_id).iscas_execute(data, hook_name)
    end
    
    #WebHook.find(hook_id).execute(data, hook_name)
  end
end
