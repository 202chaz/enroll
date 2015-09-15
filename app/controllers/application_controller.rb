class ApplicationController < ActionController::Base
  # before_filter :require_login, unless: :devise_controller?

  before_filter :require_login, unless: :authentication_not_required?
  after_action :update_url


  # force_ssl

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  ## Devise filters
  before_filter :authenticate_user_from_token!
  before_filter :authenticate_me!

  # for i18L
  before_action :set_locale

  # for current_user
  before_action :set_current_user

  # before_action do
  #   resource = controller_name.singularize.to_sym
  #   method = "#{resource}_params"
  #   params[resource] &&= send(method) if respond_to?(method, true)
  # end

  #cancancan access denied
  rescue_from CanCan::AccessDenied, with: :access_denied

  def authenticate_me!
    # Skip auth if you are trying to log in
    return true if ["welcome","saml", "broker_roles", "office_locations", "invitations"].include?(controller_name.downcase)
    authenticate_user!
  end

  def access_denied
    render file: 'public/403.html', status: 403
  end

  def create_sso_account(user, personish, timeout, account_role = "individual")
    idp_account_created = nil
    if user.idp_verified?
      idp_account_created = :created
    else
      idp_account_created = IdpAccountManager.create_account(user.email, stashed_user_password, personish, account_role, timeout)
    end
    case idp_account_created
    when :created
      session[:person_id] = personish.id
      session.delete("stashed_password")
      user.switch_to_idp!
      yield
    else
      respond_to do |format|
        format.html { render 'shared/idp_unavailable' }
      end
    end
  end

  private


  def secure_message(from_provider, to_provider, subject, body)
    message_params = {
      sender_id: from_provider.id,
      parent_message_id: to_provider.id,
      from: from_provider.legal_name,
      to: to_provider.legal_name,
      subject: subject,
      body: body
    }

    create_secure_message(message_params, to_provider, :inbox)
    create_secure_message(message_params, from_provider, :sent)
  end

  def create_secure_message(message_params, inbox_provider, folder)
    message = Message.new(message_params)
    message.folder =  Message::FOLDER_TYPES[folder]
    msg_box = inbox_provider.inbox
    msg_box.post_message(message)
    msg_box.save
  end

  def set_locale
    requested_locale = params[:locale] || user_preferred_language || extract_locale_from_accept_language_header || I18n.default_locale
    requested_locale = I18n.default_locale unless I18n.available_locales.include? requested_locale.try(:to_sym)
    I18n.locale = requested_locale
  end

  def extract_locale_from_accept_language_header
    if request.env['HTTP_ACCEPT_LANGUAGE']
      request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
    else
      nil
    end
  end

  def update_url
    if (controller_name == "employer_profiles" && action_name == "show") ||
        (controller_name == "families" && action_name == "home") ||
        (controller_name == "profiles" && action_name == "new")
        if current_user.last_portal_visited != request.original_url
          current_user.last_portal_visited = request.original_url
          current_user.save
        end
    end
  end

  def user_preferred_language
    current_user.try(:preferred_language)
  end

  protected

  # Broker Signup form should be accessibile for anonymous users
  def authentication_not_required?
    devise_controller? || (controller_name == "broker_roles") || (controller_name == "office_locations") || (controller_name == "invitations") || (controller_name == "saml")
  end

  def require_login
    unless current_user
      session[:portal] = url_for(params)
      redirect_to new_user_registration_path
    end
  end

  def after_sign_in_path_for(resource)
    session[:portal] || request.referer || root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    return SamlInformation.saml_logout_url if Rails.env == "production"
    root_path
  end

  def authenticate_user_from_token!
    user_token = params[:user_token].presence
    user = user_token && User.find_by_authentication_token(user_token.to_s)
    if user
      sign_in user, store: false
    end
  end

  def cur_page_no(alph="a")
    page_string = params.permit(:page)[:page]
    page_string.blank? ? alph : page_string.to_s
  end

  def page_alphabets(source, field)
    if fields = field.split(".") and fields.count > 1
      word_arr = source.map do |s|
        fields.each do |f|
          s = s.send(f)
        end
        s
      end
      word_arr.uniq.collect {|word| word.first.upcase}.uniq.sort
    else
      source.distinct(field).collect {|word| word.first.upcase}.uniq.sort
    end
  rescue
    ("A".."Z").to_a
  end

  def set_current_user
    User.current_user = current_user
  end

  def set_current_person
    if current_user.try(:person).try(:agent?)
      @person = Person.find(session[:person_id])
    else
      @person = current_user.person
    end
  end

  def actual_user
    if current_user.try(:person).try(:agent?)
      real_user = nil
    else
      real_user = current_user
    end
    real_user
  end

  def set_employee_bookmark_url(url=nil)
    set_current_person
    role = @person.try(:employee_roles).try(:last)
    bookmark_url = url || request.original_url
    if role && bookmark_url && (role.try(:bookmark_url) != family_account_path)
      role.bookmark_url = bookmark_url
      role.try(:save!)
    end
  end

  def set_consumer_bookmark_url(url=nil)
    set_current_person
    role = @person.try(:consumer_role)
    bookmark_url = url || request.original_url
    #no bookmark after visiting family_account_path
    if role && bookmark_url && (role.try(:bookmark_url) != family_account_path)
      role.bookmark_url = bookmark_url
      role.try(:save!)
    end
  end

  def stashed_user_password
    session["stashed_password"]
  end

end
