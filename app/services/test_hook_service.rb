class TestHookService
  def execute(hook, current_user)
    data = Gitlab::PushDataBuilder.build_sample(hook.project, current_user)
    Rails.logger.info "!!!!!!!!test tag push events!!!!!!!!!!!!!!!"
    Rails.logger.info "data is #{data}"
    hook.execute(data, 'push_hooks')
  end
end
