require 'superuser/user_patch'
require 'superuser/users_controller_patch'
require 'superuser/project_patch'
require 'superuser/custom_field_patch'
require 'superuser/issue_patch'

Redmine::Plugin.register :redmine_superuser do
  name 'Redmine Superuser'
  author 'jresinas'
  description 'Allow to create superuser profiles'
  version '0.0.1'
  author_url 'http://www.emergya.es'

  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'

  settings :default => {}, :partial => 'settings/superuser_settings'
end