class DeleteUserService
  include IscasAuditService
  attr_accessor :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  def execute(user)
    if user.solo_owned_groups.present?
      user.errors[:base] << 'You must transfer ownership or delete groups before you can remove user'
      user
    else
      user.personal_projects.each do |project|
        # Skip repository removal because we remove directory with namespace
        # that contain all this repositories
        ::Projects::DestroyService.new(project, current_user, skip_repo: true).execute
      end

      user.destroy
      #iscas_audit
      enableAudit=IscasSettings.enableAudit
      if enableAudit==true
        record_gitlab_related_operation(current_user,"deleteUser",user.id,user.name,"this is the path")
        record_gitlab_related_operation(current_user,"deleteUserNamespace",user.id,user.name,"this is the path")
      end
    end
  end
end
