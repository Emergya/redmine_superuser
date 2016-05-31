module Superuser
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development
        class << self
          alias_method_chain :allowed_to_condition, :superuser
        end
      end
    end

    module ClassMethods
      def allowed_to_condition_with_superuser(user, permission, options={})
        original_response = allowed_to_condition_without_superuser(user, permission, options)

        if Setting.plugin_redmine_superuser['view_all_projects'].present? and user.superuser?
          perm = Redmine::AccessControl.permission(permission)
          base_statement = (perm && perm.read? ? "#{Project.table_name}.status <> #{Project::STATUS_ARCHIVED}" : "#{Project.table_name}.status = #{Project::STATUS_ACTIVE}")
          if perm && perm.project_module
            # If the permission belongs to a project module, make sure the module is enabled
            base_statement << " AND #{Project.table_name}.id IN (SELECT em.project_id FROM #{EnabledModule.table_name} em WHERE em.name='#{perm.project_module}')"
          end
          if project = options[:project]
            project_statement = project.project_condition(options[:with_subprojects])
            base_statement = "(#{project_statement}) AND (#{base_statement})"
          end
        	base_statement
        else
          original_response
        end
      end
    end

    module InstanceMethods
   		
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  # use require_dependency if you plan to utilize development mode
  require_dependency 'project'
  Project.send(:include, Superuser::ProjectPatch)
end