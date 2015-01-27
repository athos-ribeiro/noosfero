class ProfileEditorController < MyProfileController

  protect 'edit_profile', :profile, :except => [:destroy_profile]
  protect 'destroy_profile', :profile, :only => [:destroy_profile]

  def index
    @pending_tasks = Task.to(profile).pending.without_spam.select{|i| user.has_permission?(i.permission, profile)}
  end

  helper :profile

  # edits the profile info (posts back)
  def edit
    @profile_data = profile
    @possible_domains = profile.possible_domains
    if request.post?
      if profile.person? && params[:profile_data].is_a?(Hash)
        params[:profile_data][:fields_privacy] ||= {}
        params[:profile_data][:custom_fields] ||= {}
      end
      Profile.transaction do
        Image.transaction do
          begin
            params[:profile_data][:visible] = params[:profile_data][:visible] == '0' unless profile.person?
            @plugins.dispatch(:profile_editor_transaction_extras)
            @profile_data.update_attributes!(params[:profile_data])
            redirect_to :action => 'index', :profile => profile.identifier
          rescue Exception => ex
            profile.identifier = params[:profile] if profile.identifier.blank?
          end
        end
      end
    end
  end

  def enable
    @to_enable = profile
    if request.post? && params[:confirmation]
      unless @to_enable.update_attribute('enabled', true)
        session[:notice] = _('%s was not enabled.') % @to_enable.name
      end
      redirect_to :action => 'index'
    end
  end

  def disable
    @to_disable = profile
    if request.post? && params[:confirmation]
      unless @to_disable.update_attribute('enabled', false)
        session[:notice] = _('%s was not disabled.') % @to_disable.name
      end
      redirect_to :action => 'index'
    end
  end

  def update_categories
    @object = profile
    @categories = @toplevel_categories = environment.top_level_categories
    if params[:category_id]
      @current_category = Category.find(params[:category_id])
      @categories = @current_category.children
    end
    render :template => 'shared/update_categories', :locals => { :category => @current_category, :object_name => 'profile_data' }
  end

  def header_footer
    @no_design_blocks = true
    if request.post?
      @profile.update_header_and_footer(params[:custom_header], params[:custom_footer])
      redirect_to :action => 'index'
    else
      @header = boxes_holder.custom_header
      @footer = boxes_holder.custom_footer
    end
  end

  def destroy_profile
    if request.post?
      if @profile.destroy
        session[:notice] = _('The profile was deleted.')
        if(params[:return_to])
          redirect_to params[:return_to]
        else
          redirect_to :controller => 'home'
        end
      else
        session[:notice] = _('Could not delete profile')
      end
    end
  end

  def deactivate_profile
    if environment.admins.include?(current_person)
      profile = environment.profiles.find(params[:id])
      if profile.disable
        profile.save
        session[:notice] = _("The profile '#{profile.name}' was deactivated.")
      else
        session[:notice] = _('Could not deactivate profile.')
      end
    end

    redirect_to_previous_location
  end

  def activate_profile
    if environment.admins.include?(current_person)
      profile = environment.profiles.find(params[:id])

      if profile.enable
        session[:notice] = _("The profile '#{profile.name}' was activated.")
      else
        session[:notice] = _('Could not activate the profile.')
      end
    end

    redirect_to_previous_location
  end

  protected

  def redirect_to_previous_location
    back = request.referer
    back = "/" if back.nil?

    redirect_to back
  end
end
