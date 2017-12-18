module Notifier
  module ApplicationHelper
    include Config::SiteConcern
    include Config::AcaConcern
    include Config::ContactCenterConcern

    def portal_display_name(controller)
      if current_user.nil?
        "<a class='portal'>#{Settings.site.header_message}</a>".html_safe
      elsif current_user.try(:has_hbx_staff_role?)
        link_to "#{image_tag 'icons/icon-exchange-admin.png'} &nbsp; I'm an Admin".html_safe, main_app.exchanges_hbx_profiles_root_path, class: "portal"
      elsif current_user.person.try(:broker_role)
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id), class: "portal"
      elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Trained Expert".html_safe, home_exchanges_agents_path, class: "portal"
      elsif current_user.person && current_user.person.active_employee_roles.any?
        link_to "#{image_tag 'icons/icon-individual.png'} &nbsp; I'm an #{controller=='employer_profiles'? 'Employer': 'Employee'}".html_safe, family_account_path, class: "portal"
      elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?))
        if current_user.identity_verified_date.present?
          link_to "#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family".html_safe, family_account_path, class: "portal"
        else
          "<a class='portal'>#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family</a>".html_safe
        end
      elsif current_user.try(:has_broker_agency_staff_role?)
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe, broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id), class: "portal"
      elsif current_user.try(:has_employer_staff_role?)
        link_to "#{image_tag 'icons/icon-business-owner.png'} &nbsp; I'm an Employer".html_safe, employers_employer_profile_path(id: current_user.person.active_employer_staff_roles.first.employer_profile_id), class: "portal"
      elsif current_user.has_general_agency_staff_role?
        link_to "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a General Agency".html_safe, general_agencies_root_path, class: "portal"
      else
        "<a class='portal'>#{Settings.site.header_message}</a>".html_safe
      end
    end

    def get_header_text(controller_name)
      portal_display_name(controller_name)
    end

    def site_faqs_url
      Settings.site.faqs_url
    end

    def site_help_url
      Settings.site.help_url
    end

    def contact_center_email_address
      Settings.contact_center.email_address
    end

    def contact_center_phone_number
      number_to_phone(Settings.contact_center.phone_number.gsub(/^./, "").gsub('-',''), area_code: true)
    end

  end
end
