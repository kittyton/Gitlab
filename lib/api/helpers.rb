module API
  require 'net/http'
  require "open-uri"
  require 'json' 
  require 'uri'
  module APIHelpers
    PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN"
    PRIVATE_TOKEN_PARAM = :private_token
    SUDO_HEADER ="HTTP_SUDO"
    SUDO_PARAM = :sudo

# Checks the occurrences of required attributes, each attribute must be present in the user hash
# or a Bad Request error is invoked.
#
# Parameters:
#   user_hash (required) - A hash consisting of a single user infos
#   keys (required) - A hash consisting of keys that must be present
# Author Name:liujinxia
    def required_attributes_user!(user_hash, keys)
      keys.each do |key|
        bad_request!(key) unless user_hash[key].present?
      end
    end
    
    def parse_boolean(value)
      [ true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON' ].include?(value)
    end

    def current_user
      private_token = (params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]).to_s
      @current_user ||= (User.find_by(authentication_token: private_token) || doorkeeper_guard)

      unless @current_user && Gitlab::UserAccess.allowed?(@current_user)
        return nil
      end

      identifier = sudo_identifier()

      # If the sudo is the current user do nothing
      if identifier && !(@current_user.id == identifier || @current_user.username == identifier)
        render_api_error!('403 Forbidden: Must be admin to use sudo', 403) unless @current_user.is_admin?
        @current_user = User.by_username_or_id(identifier)
        not_found!("No user id or username for: #{identifier}") if @current_user.nil?
      end

      @current_user
    end

    def sudo_identifier()
      identifier ||= params[SUDO_PARAM] ||= env[SUDO_HEADER]

      # Regex for integers
      if !!(identifier =~ /^[0-9]+$/)
        identifier.to_i
      else
        identifier
      end
    end

    def user_project
      @project ||= find_project(params[:id])
      @project || not_found!("Project")
    end


    def find_project(id)
      project = Project.find_with_namespace(id) || Project.find_by(id: id)

      if project && can?(current_user, :read_project, project)
        project
      else
        nil
      end
    end

    def iscas_user_project
      content = params[:content]

      content_temp = JSON.parse(content)

      projectName = content_temp["project"]
      groupName = content_temp["group"]

      private_token_value = params[:account]

      params[:private_token] = private_token_value

      @project ||= iscas_find_project(projectName, groupName)

      @project || not_found!("Project")
    end

    def iscas_find_project(projectName, groupName)
      namespace = Namespace.find_by(name: groupName)
      Rails.logger.info "namespace is #{namespace}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      namespace_id = namespace.id
      Rails.logger.info "namespace_id in helpers is #{namespace_id}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      # project = Project.find_by(name: projectName).where(namespace_id: namespace_id)
      project = Project.where(namespace_id: namespace_id, name: projectName).first
      Rails.logger.info "project is #{project}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      Rails.logger.info "project_id is #{project.id}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"

      if project && can?(current_user, :read_project, project)
        project
      end
    end

    def project_service
      @project_service ||= begin
        underscored_service = params[:service_slug].underscore

        if Service.available_services_names.include?(underscored_service)
          user_project.build_missing_services

          service_method = "#{underscored_service}_service"
          
          send_service(service_method)
        end
      end
   
      @project_service || not_found!("Service")
    end

    def send_service(service_method)
      user_project.send(service_method)
    end

    def service_attributes
      @service_attributes ||= project_service.fields.inject([]) do |arr, hash|
        arr << hash[:name].to_sym
      end
    end

    def find_group(id)
      begin
        group = Group.find(id)
      rescue ActiveRecord::RecordNotFound
        group = Group.find_by!(path: id)
      end

      if can?(current_user, :read_group, group)
        group
      else
        forbidden!("#{current_user.username} lacks sufficient "\
        "access to #{group.name}")
      end
    end

    def paginate(relation)
      per_page  = params[:per_page].to_i
      paginated = relation.page(params[:page]).per(per_page)
      add_pagination_headers(paginated, per_page)

      paginated
    end

    def authenticate!
      unauthorized! unless current_user
    end

    def authenticate_by_gitlab_shell_token!
      input = params['secret_token'].try(:chomp)
      unless Devise.secure_compare(secret_token, input)
        unauthorized!
      end
    end

    def authenticated_as_admin!
      forbidden! unless current_user.is_admin?
    end

    def authorize!(action, subject)
      unless abilities.allowed?(current_user, action, subject)
        forbidden!
      end
    end

    def authorize_push_project
      authorize! :push_code, user_project
    end

    def authorize_admin_project
      authorize! :admin_project, user_project
    end

    def can?(object, action, subject)
      abilities.allowed?(object, action, subject)
    end

    # Checks the occurrences of required attributes, each attribute must be present in the params hash
    # or a Bad Request error is invoked.
    #
    # Parameters:
    #   keys (required) - A hash consisting of keys that must be present
    def required_attributes!(keys)
      keys.each do |key|
        bad_request!(key) unless params[key].present?
      end
    end

    def attributes_for_keys(keys, custom_params = nil)
      params_hash = custom_params || params
      attrs = {}
      keys.each do |key|
        if params[key].present? or (params.has_key?(key) and params[key] == false)
          attrs[key] = params[key]
        end
      end
      ActionController::Parameters.new(attrs).permit!
    end

    def iscas_attributes_for_keys(keys, custom_params = nil)
      params_hash = custom_params || params
      attrs = {}
      keys.each do |key|
        if (params[key].present? or (params.has_key?(key) and params[key] == false)) and (key != "content")
          attrs[key] = params[key]
        end
      end
      ActionController::Parameters.new(attrs).permit!
    end

    # Helper method for validating all labels against its names
    def validate_label_params(params)
      errors = {}

      if params[:labels].present?
        params[:labels].split(',').each do |label_name|
          label = user_project.labels.create_with(
            color: Label::DEFAULT_COLOR).find_or_initialize_by(
              title: label_name.strip)

          if label.invalid?
            errors[label.title] = label.errors
          end
        end
      end

      errors
    end

    def validate_access_level?(level)
      Gitlab::Access.options_with_owner.values.include? level.to_i
    end

    def issuable_order_by
      if params["order_by"] == 'updated_at'
        'updated_at'
      else
        'created_at'
      end
    end

    def issuable_sort
      if params["sort"] == 'asc'
        :asc
      else
        :desc
      end
    end

    def filter_by_iid(items, iid)
      items.where(iid: iid)
    end

    # error helpers

    def forbidden!(reason = nil)
      message = ['403 Forbidden']
      message << " - #{reason}" if reason
      render_api_error!(message.join(' '), 403)
    end

    def bad_request!(attribute)
      message = ["400 (Bad request)"]
      message << "\"" + attribute.to_s + "\" not given"
      render_api_error!(message.join(' '), 400)
    end

    def not_found!(resource = nil)
      message = ["404"]
      message << resource if resource
      message << "Not Found"
      render_api_error!(message.join(' '), 404)
    end

    def unauthorized!
      render_api_error!('401 Unauthorized', 401)
    end

    def not_allowed!
      render_api_error!('405 Method Not Allowed', 405)
    end

    def conflict!(message = nil)
      render_api_error!(message || '409 Conflict', 409)
    end

    def render_validation_error!(model)
      if model.errors.any?
        render_api_error!(model.errors.messages || '400 Bad Request', 400)
      end
    end

    def render_api_error!(message, status)
      error!({ 'message' => message }, status)
    end

    # Projects helpers

    def filter_projects(projects)
      # If the archived parameter is passed, limit results accordingly
      if params[:archived].present?
        projects = projects.where(archived: parse_boolean(params[:archived]))
      end

      if params[:search].present?
        projects = projects.search(params[:search])
      end

      if params[:ci_enabled_first].present?
        projects.includes(:gitlab_ci_service).
          reorder("services.active DESC, projects.#{project_order_by} #{project_sort}")
      else
        projects.reorder(project_order_by => project_sort)
      end
    end

    def project_order_by
      order_fields = %w(id name path created_at updated_at last_activity_at)

      if order_fields.include?(params['order_by'])
        params['order_by']
      else
        'created_at'
      end
    end

    def project_sort
      if params["sort"] == 'asc'
        :asc
      else
        :desc
      end
    end

    private

    def add_pagination_headers(paginated, per_page)
      request_url = request.url.split('?').first

      links = []
      links << %(<#{request_url}?page=#{paginated.current_page - 1}&per_page=#{per_page}>; rel="prev") unless paginated.first_page?
      links << %(<#{request_url}?page=#{paginated.current_page + 1}&per_page=#{per_page}>; rel="next") unless paginated.last_page?
      links << %(<#{request_url}?page=1&per_page=#{per_page}>; rel="first")
      links << %(<#{request_url}?page=#{paginated.total_pages}&per_page=#{per_page}>; rel="last")

      header 'Link', links.join(', ')
    end

    def abilities
      @abilities ||= begin
                       abilities = Six.new
                       abilities << Ability
                       abilities
                     end
    end

    def secret_token
      File.read(Gitlab.config.gitlab_shell.secret_file).chomp
    end

    def handle_member_errors(errors)
      error!(errors[:access_level], 422) if errors[:access_level].any?
      not_found!(errors)
    end

    # http post helper
    # Parameters:
    #   url: Des of the url
    #   data: data want to be added in the post body
    #
    def iscas_create_post_helper(url, data)
      Rails.logger.info "data in iscas_create_post_helper is #{data}"
      Rails.logger.info "url is #{url}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      url = URI.parse(url)
      Rails.logger.info "url is #{url}@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
      req = Net::HTTP::Post.new(url.path,{'Content-Type' => 'application/json'})
      Rails.logger.info "req is #{req}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      req.body = data  
      Rails.logger.info "req.body is #{req.body}~~~~~~~~~~~~~~~~~~~~~~~~"
      Rails.logger.info "req is #{req}!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      begin
      http=Net::HTTP.new(url.host,url.port)
      Rails.logger.info "http is #{http}~~~~~~~~~~~~~~~~~~~~~~~~"
      #set the connection  time threshold
      http.open_timeout=1
      res = http.request(req)
      Rails.logger.info "res in iscas_create_post_helper is #{res}~~~~~~~~~~~~~~`"
      Rails.logger.info "res.code is #{res.code}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      Rails.logger.info "res.body is #{res.body}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      
      res

      rescue
      end
    end

    def iscas_post_handler(url, data)
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info "url is #{url}~~~~~~~~~~~~~"

      uri = URI.parse(url)
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


    #   def iscas_post_handler(url, data)
    #     Rails.logger.info "start post in iscas_post_handler ~~~~~~~~~~~~~~~~~~~~"
    #     res =  Net::HTTP.post_form(url, data)
    #     Rails.logger.info "res in iscas_post_handler is #{res}"
    #     puts res.body
    #     Rails.logger.info "finish post in iscas_post_handler~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
        
    #     res
    # end



    def iscas_get_param_form_json(params_data)
        res = JSON.parse(params_data)

        json_task_id = res["task_id"]
        json_callback = res["callback"]
        json_content = res["content"]
        json_account = res["account"]
        # json_task_data = res["task_data"]

        params[:callback] = json_callback
        params[:task_id] = json_task_id
        params[:content] = json_content
        params[:account] = json_account
    end


  def iscas_create_project_post_helper(project_url)
      Rails.logger.info "params[:data] is #{params[:data]}********************************************~~~~~~~~~~~~~!!!!!!!!"

      msg_value =  "gitlab code repository address is : ".concat(project_url)
      Rails.logger.info "msg_value is #{msg_value}~~~~~~~~~~~~~~~~~~~~~~~"
      field_value = "output data"

      task_data = {
        msg: msg_value,
        field1: field_value
      }

      task_data_value = task_data.to_json

      res = JSON.parse(params[:data])
      res["task_data"] = task_data_value
      params[:data] = res.to_json
      Rails.logger.info "new params[:data] is #{params[:data]}"
      Rails.logger.info "new params[:data] is #{params[:data].to_json}"
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      Rails.logger.info " "
      post_data = {
        data: params[:data]
      }

      Rails.logger.info "post_data is #{post_data}"

        # return to url by json_callback to post json_task_id
        # put task_id into data in the of iscas_execute in web_hook
        # Net::HTTP.post_form(url, data)
        # url = URI.parse(json_callback) 
      Rails.logger.info "start post in iscas/createProjectEvent ~~~~~~~~~~~~~~~~~~~~"
      # Rails.logger.info "params[:data] is #{params[:data]}!!!!!!!!!!!!!BEFORE POST ~~~~~~~"
      # res = iscas_create_post_helper(params[:callback], post_data.to_json)
      res = iscas_post_handler(params[:callback], post_data)
      Rails.logger.info "res is #{res}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      Rails.logger.info "finish post in iscas/createProjectEvent~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    end

    
    def iscas_reply_workflow(callback)
      code_value = "10000"
      msg_value = "success"

      reply = {
        code: code_value,
        msg: msg_value
      }
      Rails.logger.info "reply is #{reply}~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      reply = reply.to_json
      Rails.logger.info "reply new is #{reply}~~~~~~~~~~~~~~~~~~~~~~~"

      iscas_create_post_helper(callback, reply)
    end

  end
end
