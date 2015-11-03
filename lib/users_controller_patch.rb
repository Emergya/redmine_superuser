require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require_dependency 'users_controller'


module UsersControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable  # Send unloadable so it will be reloaded in development
      alias_method_chain :update, :superuser
    end
  end

  module InstanceMethods
    def update_with_superuser
      #@user.superuser = params[:user][:superuser] if params[:user][:superuser]
      case params[:user_type]
      when 'superuser'
        @user.superuser = true
        @user.admin = false
        params[:user][:admin] = false
      when 'admin'
        @user.superuser = false
        @user.admin = true
        params[:user][:admin] = true
      when 'user'
        @user.superuser = false
        @user.admin = false
        params[:user][:admin] = false
      end 

    	update_without_superuser
    end
  end

  module ClassMethods
  end
end

if Rails::VERSION::MAJOR >= 3
  ActionDispatch::Callbacks.to_prepare do
    UsersController.send(:include, UsersControllerPatch)
  end
else
  Dispatcher.to_prepare do
    UsersController.send(:include, UsersControllerPatch)
  end
end
