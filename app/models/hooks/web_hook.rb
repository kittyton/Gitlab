# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#  note_events           :boolean          default(FALSE), not null
#

class WebHook < ActiveRecord::Base
  include Sortable
  include HTTParty
  #include HttpHelper
  require "open-uri" 

  default_value_for :push_events, true
  default_value_for :issues_events, false
  default_value_for :note_events, false
  default_value_for :merge_requests_events, false
  default_value_for :tag_push_events, false
  default_value_for :enable_ssl_verification, true

  # HTTParty timeout
  default_timeout Gitlab.config.gitlab.webhook_timeout

  validates :url, presence: true,
                  format: { with: /\A#{URI.regexp(%w(http https))}\z/, message: "should be a valid url" }

  def execute(data, hook_name)
    parsed_url = URI.parse(url)

    if parsed_url.userinfo.blank?
      WebHook.post(url,
                   body: data.to_json,
                   headers: {
                     "Content-Type" => "application/json",
                     "X-Gitlab-Event" => hook_name.singularize.titleize
                   },
                   verify: enable_ssl_verification)
    else        
      post_url = url.gsub("#{parsed_url.userinfo}@", "")
      auth = {
        username: URI.decode(parsed_url.user),
        password: URI.decode(parsed_url.password),
      }
      WebHook.post(post_url,
                   body: data.to_json,
                   headers: {
                     "Content-Type" => "application/json",
                     "X-Gitlab-Event" => hook_name.singularize.titleize
                   },
                   verify: enable_ssl_verification,
                   basic_auth: auth)
    end

  rescue SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout => e
    logger.error("WebHook Error => #{e}")
    false
  end

  #Execute Web hooks. Like tag push event
  #   It is now mainly invoked to deal with tag push events.
  #   This method is just like method execute above.
  #   When the system find a listened event, this mehtod will be invoked.
  #   Besides the data deliever through parameter, we will add "data" field in data.
  #   The content of "data" is data_value mainly used for work flow.
  #
  # Parameters:
  #   data (required) - requied data content pushed in PushDataBuilder
  #   hook_name (required) - the category of hook to be dealed with
  #   webhook_instance (required) - mainly used to get certain field in webhook
  #
  #Invoked Example:
  # => invoked by proform in class ProjectWebHookWorker in path "app/works/project_web_hook_worker.rb".

  def iscas_execute(data, hook_name, webhook_instance)
    task_id = webhook_instance.task_id

    back_cmd = "cmd"
    back_account = "account"
    back_password = "password"
    back_task_id = task_id
    back_content = "content"
    back_callback = nil

    data_value = {
          cmd: back_cmd,
          account: back_account,
          password: back_password,
          task_id: back_task_id,
          content: back_content,
          callback: back_callback
        }
    data_value = data_value.to_json
    data["data"] = data_value 
     
    parsed_url = URI.parse(url)
    
    res = iscas_post_handler(parsed_url, data)

  rescue SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout => e
    logger.error("WebHook Error => #{e}")
    false
  end

  def iscas_post_handler(url, data)
    res =  Net::HTTP.post_form(url, data)
    puts res.body
  end

  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data, hook_name)
  end
end
