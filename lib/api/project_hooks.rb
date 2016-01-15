module API
  # Projects API
  class ProjectHooks < Grape::API
    #before { authenticate! }
    #before { authorize_admin_project }
    require 'json'
    require 'net/http'
    require 'open-uri'
    include HttpHelper  

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



      #Add tag push listener hook in the project 
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
        iscas_get_param_form_json(params[:data])

        required_attributes! [:callback]

        @hook = iscas_user_project.hooks.new(url: params[:callback], push_events: false, issues_events: false, merge_requests_events: false, tag_push_events: true, note_events: false, task_id: params[:task_id])

        if @hook.save
          present @hook, with: Entities::ProjectHook
          iscas_reply_workflow(params[:callback])
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end



      #Add merge request listener hook in the project 
      #
      # Parameters:
      #   content:  
      #       - group : group name 
      #       - project : project name
      #   callback (required) - The hook URL
      #   account (required) - private_token
      # Example Request:
      #   POST /projects/iscas/addMergeRequestListener
      post ":iscas/addMergeRequestListener" do
        iscas_get_param_form_json(params[:data])

        required_attributes! [:callback]

        @hook = iscas_user_project.hooks.new(url: params[:callback], push_events: false, issues_events: false, merge_requests_events: true, tag_push_events: false, note_events: false, task_id: params[:task_id])

        if @hook.save
          present @hook, with: Entities::ProjectHook
          iscas_reply_workflow(params[:callback])
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end



      #Add comments hook in the project 
      #
      # Parameters:
      #   content:  
      #       - group : group name    
      #       - project : project name
      #   callback (required) - The hook URL
      #   account (required) - private_token
      # Example Request:
      #   POST /projects/iscas/addCommentsListener
      post ":iscas/addCommentsListener" do
        iscas_get_param_form_json(params[:data])

        required_attributes! [:callback]

        @hook = iscas_user_project.hooks.new(url: params[:callback], push_events: false, issues_events: false, merge_requests_events: false, tag_push_events: false, note_events: true, task_id: params[:task_id])

        if @hook.save
          present @hook, with: Entities::ProjectHook
          iscas_reply_workflow(params[:callback])
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end



      #Add push listener hook in the project 
      #
      # Parameters:
      #   content:  
      #       - group : group name 
      #       - project : project name
      #   callback (required) - The hook URL
      #   account (required) - private_token
      # Example Request:
      #   POST /projects/iscas/addPushListener
      post ":iscas/addPushListener" do
        iscas_get_param_form_json(params[:data])

        required_attributes! [:callback]

        @hook = iscas_user_project.hooks.new(url: params[:callback], push_events: true, issues_events: false, merge_requests_events: false, tag_push_events: false, note_events: false, task_id: params[:task_id])

        if @hook.save
          present @hook, with: Entities::ProjectHook
          iscas_reply_workflow(params[:callback])
        else
          if @hook.errors[:url].present?
            error!("Invalid url given", 422)
          end
          not_found!("Project hook #{@hook.errors.messages}")
        end
      end



      # Create new project event
      #
      # Parameters:
      #   content:
      #       - project (required) - name for new project
      #       - group (required) - defaults to user namespace
      #       - description (optional) - short project description
      #       - issues_enabled (optional)
      #       - merge_requests_enabled (optional)
      #       - wiki_enabled (optional)
      #       - snippets_enabled (optional)
      #       - public (optional) - if true same as setting visibility_level = 20
      #       - visibility_level (optional) - 0 by default
      #       - import_url (optional)
      #   account (required) - private_token
      # Example Request
      #   POST /projects/iscas/createProjectEvent
      post ":iscas/createProjectEvent" do
        iscas_get_param_form_json(params[:data])

        content = params[:content]
        content_temp = JSON.parse(content)

        projectName = content_temp["project"]
        groupName = content_temp["group"]

        group = Namespace.find_by(name: groupName)
        group_id = group.id

        params[:name] = projectName
        params[:namespace_id] = group_id
        params[:private_token] = params[:account]

        required_attributes! [:name]

        attrs = attributes_for_keys [:name,
                                     :path,
                                     :description,
                                     :issues_enabled,
                                     :merge_requests_enabled,
                                     :wiki_enabled,
                                     :namespace_id,
                                     :public,
                                     :visibility_level,
                                     :import_url]
        publik = attrs.delete(:public)
        publik = parse_boolean(publik)
        attrs[:visibility_level] = Gitlab::VisibilityLevel::PUBLIC if !attrs[:visibility_level].present? && publik == true
        # attrs
        @project = ::Projects::CreateService.new(current_user, attrs).execute

        if @project.saved?
          #return success msg
          iscas_reply_workflow(params[:callback])
          #expose project msg
          present @project, with: Entities::Project
          #return sccuess handle msg
          iscas_create_project_post_helper(params[:callback])
          
        else
          if @project.errors[:limit_reached].present?
            error!(@project.errors[:limit_reached], 403)
          end
          render_validation_error!(@project)
        end  
      end


    end
  end
end
