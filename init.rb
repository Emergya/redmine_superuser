require 'user_patch'
require 'users_controller_patch'

Redmine::Plugin.register :redmine_superuser do
  name 'Redmine Superuser'
  author 'jresinas'
  description 'Allow to create superuser profiles'
  version '0.0.1'
  author_url 'http://www.emergya.es'

  requires_redmine_plugin :redmine_base_deface, :version_or_higher => '0.0.1'
end