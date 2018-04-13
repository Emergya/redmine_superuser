require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module Superuser
  module UserPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        alias_method_chain :allowed_to?, :superuser
        alias_method_chain :managed_roles, :superuser
      end
    end

    module ClassMethods
      
    end

    module InstanceMethods
      # Superusers have all admin permissions except specific ones, like admin menu options
      def allowed_to_with_superuser?(action, context, options={}, &block)
        if context && context.is_a?(Project)
          return true if superuser? and context.allows_to?(action) and action != :only_admin
        elsif !(context && context.is_a?(Array)) and options[:global]
          return true if superuser? and action != :only_admin
        end

        allowed_to_without_superuser?(action, context, options, &block)
      end

      # Returns the roles that the user is allowed to manage for the given project
      def managed_roles_with_superuser(project)
        if Setting.plugin_redmine_superuser['manage_members'].present? and superuser?
          @managed_roles ||= Role.givable.to_a
        else
          managed_roles_without_superuser(project)
        end
      end 
    end
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    require_dependency 'principal'
    require_dependency 'user'
    User.send(:include, Superuser::UserPatch)
  end
else
  Dispatcher.to_prepare do
    require_dependency 'principal'
    require_dependency 'user'
    User.send(:include, Superuser::UserPatch)
  end
end
