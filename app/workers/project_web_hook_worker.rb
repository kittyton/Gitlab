class ProjectWebHookWorker
  include Sidekiq::Worker

  sidekiq_options queue: :project_web_hook

  def perform(hook_id, data, hook_name)
  	Rails.logger.info "start perform in project_web_hook.rb"
  	Rails.logger.info "data is #{data}"
    data = data.with_indifferent_access
    Rails.logger.info "data is #{data}"
    Rails.logger.info "WebHook.find(hook_id) is #{WebHook.find(hook_id)}"
    #add data in web_hook to return the data value
    WebHook.find(hook_id).execute(data, hook_name)
  end
end
