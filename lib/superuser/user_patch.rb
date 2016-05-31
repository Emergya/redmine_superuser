require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

module Superuser
  module UserPatch
    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, InstanceMethods)

      # Same as typing in the class
      base.class_eval do
        unloadable # Send unloadable so it will be reloaded in development

        alias_method_chain :allowed_to?, :superuser
      end
    end

    module ClassMethods
      
    end

    module InstanceMethods
      # Superusers have all admin permissions except specific ones, like admin menu options
      def allowed_to_with_superuser?(action, context, options={}, &block)
        if context && context.is_a?(Project)
          return true if superuser? and context.allows_to?(action)
        elsif !(context && context.is_a?(Array)) and options[:global]
          return true if superuser?
        end

        allowed_to_without_superuser?(action, context, options, &block)
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
