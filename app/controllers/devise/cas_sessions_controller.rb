class Devise::CasSessionsController < Devise::SessionsController  
  unloadable
  
  def new
    unless returning_from_cas?
      redirect_to(cas_login_url)
    end
  end
  
  def service
    warden.authenticate!(:scope => resource_name)
    redirect_to redirect_location(resource_name, current_user)
  end
  
  def unregistered
  end
  
  def destroy
    # if :cas_create_user is false a CAS session might be open but not signed_in
    # in such case we destroy the session here
    if signed_in?(resource_name)
      sign_out(resource_name)
    else
      reset_session
    end
    destination = request.protocol
    destination << request.host
    destination << ":#{request.port.to_s}" unless request.port == 80
    destination << after_sign_out_path_for(resource_name)
    redirect_to(::Devise.cas_client.logout_url(destination))
  end
  
  private  
  def returning_from_cas?
    params[:ticket] || request.referer =~ /^#{::Devise.cas_client.cas_base_url}/
  end
  
  def cas_login_url
    ::Devise.cas_client.add_service_to_login_url(::Devise.cas_service_url(request.url, devise_mapping))
  end
  helper_method :cas_login_url
end
