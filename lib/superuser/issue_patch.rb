module Superuser
  module IssuePatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
          alias_method_chain :new_statuses_allowed_to, :superuser
      end
    end

    module ClassMethods
      
    end

    module InstanceMethods
   		def new_statuses_allowed_to_with_superuser(user=User.current, include_default=false)
        if Setting.plugin_redmine_superuser['access_all_statuses'].present? and user.superuser?
          if new_record? && @copied_from
            [default_status, @copied_from.status].compact.uniq.sort
          else
            initial_status = nil
            if new_record?
              # nop
            elsif tracker_id_changed?
              if Tracker.where(:id => tracker_id_was, :default_status_id => status_id_was).any?
                initial_status = default_status
              elsif tracker.issue_status_ids.include?(status_id_was)
                initial_status = IssueStatus.find_by_id(status_id_was)
              else
                initial_status = default_status
              end
            else
              initial_status = status_was
            end

            initial_assigned_to_id = assigned_to_id_changed? ? assigned_to_id_was : assigned_to_id
            assignee_transitions_allowed = initial_assigned_to_id.present? &&
              (user.id == initial_assigned_to_id || user.group_ids.include?(initial_assigned_to_id))

            statuses = []
            statuses += IssueStatus.new_statuses_allowed(
              initial_status,
              (user.admin or user.superuser) ? Role.all.to_a : user.roles_for_project(project),
              tracker,
              author == user,
              assignee_transitions_allowed
            )
            statuses << initial_status unless statuses.empty?
            statuses << default_status if include_default || (new_record? && statuses.empty?)
            statuses = statuses.compact.uniq.sort
            if blocked?
              statuses.reject!(&:is_closed?)
            end
            statuses
          end
        else
          new_statuses_allowed_to_without_superuser(user, include_default)
        end
      end
    end
  end
end

ActionDispatch::Callbacks.to_prepare do
  # use require_dependency if you plan to utilize development mode
  require_dependency 'project'
  Issue.send(:include, Superuser::IssuePatch)
end