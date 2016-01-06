class ProjectWebHookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :project_web_hook

    # Entrance of hook execute.
    #  Add data in web_hook to return the data value.
    #  Judge the value of webHook's task_id.
    # => if nil, execute;
    # => if has a value, iscas_execute.
    #
    # Parameters:
    #   hook_id (required) - The id of the hook
    #   data (required) - The data required by method execute and iscas_execute
    #   hook_name (required) - The category of hook to be dealed with 

  def perform(hook_id, data, hook_name)
  	
    data = data.with_indifferent_access
    
    #add data in web_hook to return the data value
    #judge the value of webHook's task_id
    #if nil, execute
    #if has a value, iscas_execute
    webhook_instance = WebHook.find(hook_id)

    if webhook_instance.task_id == nil
    	webhook_instance.execute(data, hook_name)    	    	

    else
    	webhook_instance.iscas_execute(data, hook_name, webhook_instance)
    end
    
  end
end
