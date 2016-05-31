require 'dispatcher' unless Rails::VERSION::MAJOR >= 3
require_dependency 'users_controller'


module UsersControllerPatch
  def self.included(base) # :nodoc:
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable  # Send unloadable so it will be reloaded in development
      alias_method_chain :create, :superuser
      before_filter :set_user_type, :only => [:update]
    end
  end

  module InstanceMethods
    def create_with_superuser
      binding.pry
      @user = User.new(:language => Setting.default_language, :mail_notification => Setting.default_notification_option)

      # Core method with set_user_type call to set type of user (user/superuser/admin)
      set_user_type

      @user.safe_attributes = params[:user]
      @user.admin = params[:user][:admin] || false
      @user.login = params[:user][:login]
      @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation] unless @user.auth_source_id
      @user.pref.attributes = params[:pref] if params[:pref]

      if @user.save
        Mailer.account_information(@user, @user.password).deliver if params[:send_information]

        respond_to do |format|
          format.html {
            flash[:notice] = l(:notice_user_successful_create, :id => view_context.link_to(@user.login, user_path(@user)))
            if params[:continue]
              attrs = params[:user].slice(:generate_password)
              redirect_to new_user_path(:user => attrs)
            else
              redirect_to edit_user_path(@user)
            end
          }
          format.api  { render :action => 'show', :status => :created, :location => user_url(@user) }
        end
      else
        @auth_sources = AuthSource.all
        # Clear password input
        @user.password = @user.password_confirmation = nil

        respond_to do |format|
          format.html { render :action => 'new' }
          format.api  { render_validation_errors(@user) }
        end
      end
    end

    def set_user_type
      if params[:user_type].present? and @user.present?
        case params[:user_type]
        when 'superuser'
          @user.superuser = true
          @user.admin = false
          params[:user][:superuser] = true
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
      end
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
