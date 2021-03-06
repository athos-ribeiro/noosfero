class AdminPanelController < AdminController

  protect 'view_environment_admin_panel', :environment

  def boxes_holder
    environment
  end

  def site_info
    @no_design_blocks = true
    if request.post?
      if params[:environment][:languages]
        params[:environment][:languages] = params[:environment][:languages].map {|lang, value| lang if value=='true'}.compact
      end
      if @environment.update_attributes(params[:environment])
        session[:notice] = _('Environment settings updated')
        redirect_to :action => 'index'
      end
    end
  end

  def manage_portal_community
    params[:activate] == '1' ? environment.enable('use_portal_community') : environment.disable('use_portal_community')
    environment.save
    redirect_to :action => 'set_portal_community'
  end

  def unset_portal_community
    environment.unset_portal_community!
    redirect_to :action => 'set_portal_community'
  end

  def set_portal_community
    env = environment
    @portal_community = env.portal_community || Community.new
    if request.post?
      portal_community = env.communities.find_by_identifier(params[:portal_community_identifier])
      if portal_community
        if (env.portal_community != portal_community)
          env.portal_community = portal_community
          env.portal_folders = []
          env.save
        end
        redirect_to :action => 'set_portal_folders'
      else
        session[:notice] = _('Community not found. You must insert the identifier of a community from this environment')
      end
    end
  end

  def set_portal_folders
     @selected = (environment.portal_folders || [])
     @available_portal_folders = environment.portal_community.folders - @selected

     if request.post?
       env = environment
       folders = params[:folders].map{|fid| Folder.find(:first, :conditions => {:profile_id => env.portal_community, :id => fid})} if params[:folders]
       env.portal_folders = folders
       if env.save
         session[:notice] = _('Saved the portal folders')
         redirect_to :action => 'set_portal_news_amount'
       end
     end
  end

  def set_portal_news_amount
    if request.post?
      if @environment.update_attributes(params[:environment])
        session[:notice] = _('Saved the number of news on folders')
        redirect_to :action => 'index'
      end
    end
  end

  def manage_organizations_status
    scope = environment.organizations
    @filter = params[:filter] || 'any'
    @title = "Organization profiles"
    @title = @title+" - "+@filter if @filter != 'any'

    if @filter == 'enabled'
      scope = scope.visible
    elsif @filter == 'disabled'
      scope = scope.disabled
    end

    scope = scope.order('name ASC')

    @q = params[:q]
    @collection = find_by_contents(:organizations, environment, scope, @q, {:per_page => 10, :page => params[:npage]})[:results]
  end
end
