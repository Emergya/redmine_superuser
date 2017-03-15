module Superuser
  module ProjectPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        class << self
          alias_method_chain :allowed_to_condition, :superuser
        end
      end
    end

    module ClassMethods
      def allowed_to_condition_with_superuser(user, permission, options={})
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

        if user.admin? or (Setting.plugin_redmine_superuser['view_all_projects'].present? and user.superuser?)
          base_statement
        else
          statement_by_role = {}
          unless options[:member]
            role = user.builtin_role
            if role.allowed_to?(permission)
              s = "#{Project.table_name}.is_public = #{connection.quoted_true}"
              if user.id
                s = "(#{s} AND #{Project.table_name}.id NOT IN (SELECT project_id FROM #{Member.table_name} WHERE user_id = #{user.id}))"
              end
              statement_by_role[role] = s
            end
          end
          user.projects_by_role.each do |role, projects|
            if role.allowed_to?(permission) && projects.any?
              statement_by_role[role] = "#{Project.table_name}.id IN (#{projects.collect(&:id).join(',')})"
            end
          end
          if statement_by_role.empty?
            "1=0"
          else
            if block_given?
              statement_by_role.each do |role, statement|
                if s = yield(role, user)
                  statement_by_role[role] = "(#{statement} AND (#{s}))"
                end
              end
            end
            "((#{base_statement}) AND (#{statement_by_role.values.join(' OR ')}))"
          end
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