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
  require 'net/http'
  require 'json' 

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
    Rails.logger.info "hook_name is #{hook_name}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # if hook_name is note_hooks, put it in a method, 
    # parse its noteable type whether it is MergeRequest OR  Issue
    # the type of iscas_execute param----->data is json
    if hook_name == "note_hooks"
      note_type = iscas_note_judge(data)
    end

    task_id = webhook_instance.task_id
    project_id = webhook_instance.project_id

    Rails.logger.info "project_id is #{project_id}~~~~~~~~~~~~~~~~~~~~~~~~~~```"
    project = Project.find_by(id: project_id)
    Rails.logger.info "project to the hook is #{project}"
    project_url = "gitlab code repository address is : ".concat(project.web_url)
    Rails.logger.info "url of the project is #{project_url}"
    field_value = "output data"
    task_data = {
      msg: project_url,
      field1: field_value
    }

    Rails.logger.info "task_data is #{task_data}"

    back_cmd = "cmd"
    back_account = "account"
    back_password = "password"
    back_task_id = task_id
    back_content = "content"
    back_callback = nil
    back_task_data = task_data.to_json

    Rails.logger.info "back_task_data is #{back_task_data}"

    data_value = {
          cmd: back_cmd,
          account: back_account,
          password: back_password,
          task_id: back_task_id,
          content: back_content,
          callback: back_callback,
          task_data: back_task_data
        }
    data_value = data_value.to_json
    data["data"] = data_value 
    Rails.logger.info "data in iscas_execute is #{data}"
     
    parsed_url = URI.parse(url)
    Rails.logger.info "parsed_url is #{parsed_url}~~~~~~~~~~~~~~~~~~~~url is #{url}"
    
    if hook_name == "note_hooks"
      if note_type != "MergeRequest"
        Rails.logger.info "it is not a MergeRequest comment"
        # execute null
      else
        res = iscas_post_handler(parsed_url, data)
        Rails.logger.info "res in note_hooks iscas_execute is  #{res}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`"

        Rails.logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
        Rails.logger.info "res note_hooks code is #{res.code}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        Rails.logger.info "res note_hooks body is #{res.body}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        body = res.body
        Rails.logger.info "body note_hooks is #{body}~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        result = JSON.parse(body)
        code = result["code"]
        Rails.logger.info "code note_hooks is #{code}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        msg = result["msg"]
        Rails.logger.info "msg note_hooks is #{msg}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        id = webhook_instance.id
        Rails.logger.info "webhook id note_hooks is #{id}~~~~~~~~~~~~~~~~~~~~~~~~"
        iscas_delete_hook(id, code, msg)
        # Rails.logger.info "res_new body is #{res_new.body}"
        Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      end
    else
      res = iscas_post_handler(parsed_url, data)
      Rails.logger.info "res in iscas_execute is  #{res}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~`"

      Rails.logger.info "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      Rails.logger.info "res code is #{res.code}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      Rails.logger.info "res body is #{res.body}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      body = res.body
      Rails.logger.info "body is #{body}~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      result = JSON.parse(body)
      code = result["code"]
      Rails.logger.info "code is #{code}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      msg = result["msg"]
      Rails.logger.info "msg is #{msg}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      id = webhook_instance.id
      Rails.logger.info "webhook id is #{id}~~~~~~~~~~~~~~~~~~~~~~~~"
      iscas_delete_hook(id, code, msg)
      # Rails.logger.info "res_new body is #{res_new.body}"
      Rails.logger.info "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end

  
  rescue SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED, Net::OpenTimeout => e
    logger.error("WebHook Error => #{e}")
    false
  end

  def iscas_post_handler(url, data)
    Rails.logger.info "start post in iscas_post_handler ~~~~~~~~~~~~~~~~~~~~"
    # res =  Net::HTTP.post_form(url, data)
    # Rails.logger.info "res in iscas_post_handler is #{res}"
    # puts res.body
    # Rails.logger.info "finish post in iscas_post_handler~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    # res


      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info "url is #{url}~~~~~~~~~~~~~"

      uri = url
      Rails.logger.info "uri is #{uri}"
      http = Net::HTTP.new(uri.host, uri.port)
      Rails.logger.info "http is #{http}"
      request = Net::HTTP::Post.new(uri.request_uri)
      Rails.logger.info "request is request"
      request.set_form_data(data)
      response = http.request(request)
      Rails.logger.info "response is #{response}"
      return response
  end

    # when code=10000 and msg = success
    # delete the hook from db whose id is hook_id
    #

    def iscas_delete_hook(hook_id, code, msg)
      if code == "10000" && msg == "success"
        Rails.logger.info "complete!~~~~~~~~~~~~~~~start delete"
        WebHook.find_by(id: hook_id).destroy
      else
        Rails.logger.info "not success, resend the post"
      end
    end

  def iscas_note_judge(data)
    Rails.logger.info "data is #{data} in iscas_note_judge~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    noteable_type_one = data[:object_attributes][:noteable_type]
    Rails.logger.info "noteable_type_one is #{noteable_type_one}~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    noteable_type_one
  end


  def async_execute(data, hook_name)
    Sidekiq::Client.enqueue(ProjectWebHookWorker, id, data, hook_name)
  end
end
