class DestroyGroupService
  include IscasAuditService
  attr_accessor :group, :current_user

  def initialize(group, user)
    @group, @current_user = group, user
  end

  def execute
    @group.projects.each do |project|
      # Skip repository removal because we remove directory with namespace
      # that contain all this repositories
      ::Projects::DestroyService.new(project, current_user, skip_repo: true).execute
    end

    
    @group.destroy
    #iscas_audit
    enableAudit=IscasSettings.enableAudit
    if enableAudit==true
        record_gitlab_related_operation(current_user,"deleteGroupNamespace",@group.id,@group.name,@group.path)
    end


  end
end
