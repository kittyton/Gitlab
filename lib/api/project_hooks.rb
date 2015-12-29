module API
  # Projects API
  class ProjectHooks < Grape::API
    #before { authenticate! }
    #before { authorize_admin_project }
    require 'json'

    resource :projects do
      # Get project hooks
      #
      # Parameters:
      #   id (required) - The ID of a project
      # Example Request:
      #   GET /projects/:id/hooks
      get ":id/hooks" do
        @hooks = paginate user_project.hooks
        present @hooks, with: Entities::ProjectHook
      end

      # Get a project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      # Example Request:
      #   GET /projects/:id/hooks/:hook_id
      get ":id/hooks/:hook_id" do
        @hook = user_project.hooks.find(params[:hook_id])
        present @hook, with: Entities::ProjectHook
      end


      # Add hook to project
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   url (required) - The hook URL
      # Example Request:
      #   POST /projects/:id/hooks
      post ":id/hooks" do
        required_attributes! [:url]
        attrs = attributes_for_keys [
          :url,
          :push_events,
          :issues_events,
          :merge_requests_events,
          :tag_push_events,
          :note_events
        ]
        @hook = user_project.hooks.new(attrs)

        if @hook.save
          present @hook, with: Entities::ProjectHook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end


      #temp test
      #Add tag push listenor hook in the project 
      #
      # Parameters:
      #   content:  
      #       - group : group name 
      #       - project : project name
      #       - private_token : private_token
      #   callback (required) - The hook URL
      # Example Request:
      #   POST /projects/iscas/addTagPushListener
      post ":iscas/addTagPushListener" do
        Rails.logger.info "!!!!!start!!!!"
        Rails.logger.info "params[:data] is #{params[:data]}"

        res = JSON.parse(params[:data])
        Rails.logger.info "params[:data] is #{params[:data]}"
        Rails.logger.info "res is #{res}"
        # tid = res["task_id"]
        # Rails.logger.info "tid is #{tid}"
        # tidd = res[task_id]
        json_task_id = res["task_id"]
        json_callback = res["callback"]
        json_content = res["content"]

        Rails.logger.info "res[:task_id] is #{json_task_id}"
        Rails.logger.info "res[:callback] is #{json_callback}"
        Rails.logger.info "res[:content] is #{json_content}"
        
        params[:callback] = json_callback
        params[:task_id] = json_task_id
        params[:content] = json_content

        Rails.logger.info "params[:callback] is #{params[:callback]}"
        Rails.logger.info "params[:task_id] is #{params[:task_id]}"
        Rails.logger.info "params[:content] is #{params[:content]}"

        # Rails.logger.info "res is #{res}"

        required_attributes! [:callback]
        Rails.logger.info "params[:callback] is #{params[:callback]}"

        #add json handle part, we find callback, task_id and content from json 


        # attrs = attributes_for_keys [
        #   :url,

        #   :push_events,
        #   :issues_events,
        #   :merge_requests_events,
        #   :tag_push_events,
        #   :note_events
        # ]

        @hook = iscas_user_project.hooks.new(url: params[:callback], push_events: false, issues_events: false, merge_requests_events: false, tag_push_events: true, note_events: false, task_id: params[:task_id])

        if @hook.save
          present @hook, with: Entities::ProjectHook
          # present "task_id: " + params[:task_id]
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end


      # Update an existing project hook
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of a project hook
      #   url (required) - The hook URL
      # Example Request:
      #   PUT /projects/:id/hooks/:hook_id
      put ":id/hooks/:hook_id" do
        @hook = user_project.hooks.find(params[:hook_id])
        required_attributes! [:url]
        attrs = attributes_for_keys [
          :url,
          :push_events,
          :issues_events,
          :merge_requests_events,
          :tag_push_events,
          :note_events
        ]

        if @hook.update_attributes attrs
          present @hook, with: Entities::ProjectHook
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end

      # Deletes project hook. This is an idempotent function.
      #
      # Parameters:
      #   id (required) - The ID of a project
      #   hook_id (required) - The ID of hook to delete
      # Example Request:
      #   DELETE /projects/:id/hooks/:hook_id
      delete ":id/hooks/:hook_id" do
        required_attributes! [:hook_id]

        begin
          @hook = ProjectHook.find(params[:hook_id])
          @hook.destroy
        rescue
          # ProjectHook can raise Error if hook_id not found
        end
      end
    end
  end
end
