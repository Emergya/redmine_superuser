require 'dispatcher' unless Rails::VERSION::MAJOR >= 3

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
    def allowed_to_with_superuser?(action, context, options={}, &block)
      if options[:global]
        return true if superuser?
      else
        allowed_to_without_superuser?(action, context, options={}, &block)
      end
    end
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    # use require_dependency if you plan to utilize development mode
    require_dependency 'principal'
    require_dependency 'user'
    User.send(:include, UserPatch)
  end
else
  Dispatcher.to_prepare do
    require_dependency 'principal'
    require_dependency 'user'
    User.send(:include, UserPatch)
  end
end
