require 'gitlab' # Load lib/gitlab.rb as soon as possible

class IscasSettings < Settingslogic
  source ENV.fetch('GITLAB_CONFIG') { "#{Rails.root}/config/iscas.yml" }
  namespace Rails.env
end