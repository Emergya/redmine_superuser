module Superuser
  module CustomFieldPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        alias_method_chain :visible_by?, :superuser
        alias_method_chain :visibility_by_project_condition, :superuser

        class << self
          alias_method_chain :visibility_condition, :superuser
        end
      end
    end

    module ClassMethods
      def visibility_condition_with_superuser
        if Setting.plugin_redmine_superuser['view_all_custom_fields'].present? and user.superuser?
          "1=1"
        else
          visibility_condition_without_superuser
        end
      end
    end

    module InstanceMethods
   		def visible_by_with_superuser?(project, user=User.current)
        if Setting.plugin_redmine_superuser['view_all_custom_fields'].present? 
          visible_by_without_superuser?(project, user) || user.superuser?
        else
          visible_by_without_superuser?(project, user)
        end
      end

      def visibility_by_project_condition_with_superuser(project_key=nil, user=User.current, id_column=nil)
        if Setting.plugin_redmine_superuser['view_all_custom_fields'].present? and user.superuser?
          "1=1"
        else
          visibility_by_project_condition_without_superuser(project_key, user, id_column)
        end
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  # use require_dependency if you plan to utilize development mode
  require_dependency 'custom_field'
  CustomField.send(:include, Superuser::CustomFieldPatch)
end