module BenefitSponsors
  module Profiles
    class Employers::BrokerAgencyController < ApplicationController
      include Acapi::Notifiers
      before_action :find_employer
      before_action :find_broker_agency, :except => [:index, :active_broker]
      before_action :updateable?, only: [:create, :terminate]

      def index
        @filter_criteria = params.permit(:q, :working_hours, :languages => [])

        if @filter_criteria.empty?
          @orgs = BenefitSponsors::Organizations::Organization.approved_broker_agencies.broker_agencies_by_market_kind(['both', 'shop'])
          @page_alphabets = page_alphabets(@orgs, "legal_name")

          if params[:page].present?
            @page_alphabet = cur_page_no(@page_alphabets.first)
            @organizations = @orgs.where("legal_name" => /^#{@page_alphabet}/i)
          else
            @organizations = @orgs.limit(12).to_a
          end
          @broker_agency_profiles = Kaminari.paginate_array(@organizations.map(&:broker_agency_profile).uniq).page(params[:organization_page] || 1).per(10)
        else
          results = BenefitSponsors::Organizations::Organization.broker_agencies_with_matching_agency_or_broker(@filter_criteria)
          if results.first.is_a?(Person)
            @filtered_broker_roles  = results.map(&:broker_role)
            @broker_agency_profiles = Kaminari.paginate_array(results.map{|broker| broker.broker_role.broker_agency_profile}.uniq).page(params[:organization_page] || 1).per(10)
          else
            @broker_agency_profiles = Kaminari.paginate_array(results.map(&:broker_agency_profile).uniq).page(params[:organization_page] || 1).per(10)
          end
        end

        respond_to do |format|
          format.js
        end
      end

      def show
      end

      def active_broker
        @broker_agency_account = @employer_profile.active_broker_agency_account
      end

      def create
        @broker_managenement_form = BenefitSponsors::Organizations::Forms::BrokerManagementForm.for_create(params)
        @broker_managenement_form.save

        flash[:notice] = "Your broker has been notified of your selection and should contact you shortly. You can always call or email them directly. If this is not the broker you want to use, select 'Change Broker'."
        redirect_to profiles_employers_employer_profile_path(@employer_profile, tab: 'brokers')
      rescue => e
        error_msg = @broker_managenement_form.errors.map(&:full_messages) if @broker_managenement_form.errors
        redirect_to(:back, :flash => {error: error_msg})
        log("#4095 #{e.message}; employer_profile: #{@broker_managenement_form.employer_profile_id}; #{error_msg}", {:severity => "error"})
      end

      def terminate
        if params["termination_date"].present?
          termination_date = DateTime.strptime(params["termination_date"], '%m/%d/%Y').try(:to_date)
          @employer_profile.fire_broker_agency(termination_date)
          #TODO fix this during GAs implementation
          # @employer_profile.fire_general_agency!(termination_date)
          @fa = @employer_profile.save!
        end

        respond_to do |format|
          format.js {
            if params["termination_date"].present? && @fa
              flash[:notice] = "Broker terminated successfully."
              render text: true
            else
              render text: false
            end
          }
          format.all {
            flash[:notice] = "Broker terminated successfully."
            if params[:direct_terminate]
              redirect_to profiles_employers_employer_profile_path(@employer_profile, tab: "brokers")
            else
              redirect_to profiles_employers_employer_profile_path(@employer_profile)
            end
          }
        end
      end

      private

      def updateable?
        authorize @employer_profile, :updateable?
      end

      def send_broker_successfully_associated_email broker_role_id
        id = BSON::ObjectId.from_string(broker_role_id)
        @broker_person = Person.where(:'broker_role._id' => id).first
        body = "You have been selected as a broker by #{@employer_profile.try(:legal_name)}"

        # from_provider = HbxProfile.current_hbx
        message_params = {
          sender_id: @employer_profile.try(:id),
          parent_message_id: @broker_person.id,
          from: @employer_profile.try(:legal_name),
          to: @broker_person.try(:full_name),
          body: body,
          subject: 'You have been select as the Broker'
        }

        create_secure_message(message_params, @broker_person, :inbox)
      end

      def send_general_agency_assign_msg(general_agency, employer_profile, broker_agency_profile, status)
        subject = "You are associated to #{broker_agency_profile.organization.legal_name}- #{general_agency.legal_name} (#{status})"
        body = "<br><p>Associated details<br>General Agency : #{general_agency.legal_name}<br>Employer : #{employer_profile.legal_name}<br>Status : #{status}</p>"
        secure_message(broker_agency_profile, general_agency, subject, body)
        secure_message(broker_agency_profile, employer_profile, subject, body)
      end

      def send_broker_assigned_msg(employer_profile, broker_agency_profile)
        broker_subject = "#{employer_profile.organization.legal_name} has selected you as the broker on DC Health Link"
        broker_body = "<br><p>Please contact your new client representative:<br> Employer Name: #{employer_profile.organization.legal_name}<br>Representative: #{employer_profile.staff_roles.first.try(:full_name)}<br>Email: #{employer_profile.staff_roles.first.try(:work_email_or_best)}<br>Phone: #{employer_profile.staff_roles.first.try(:work_phone).to_s}<br>Address: #{employer_profile.organization.primary_office_location.address.full_address}</p>"
        employer_subject = "You have selected #{broker_agency_profile.primary_broker_role.person.full_name} as your broker on DC Health Link."
        employer_body = "<br><p>Your new Broker: #{broker_agency_profile.primary_broker_role.person.full_name}<br> Phone: #{broker_agency_profile.phone.to_s}<br>Email: #{broker_agency_profile.primary_broker_role.person.emails.first.address}<br>Address: #{broker_agency_profile.organization.primary_office_location.address.full_address}</p>"
        secure_message(employer_profile, broker_agency_profile, broker_subject, broker_body)
        secure_message(broker_agency_profile, employer_profile, employer_subject, employer_body)
      end

      def find_employer
        @employer_profile = BenefitSponsors::Organizations::Profile.find(params["employer_profile_id"])
      end

      def find_broker_agency
        id = params[:id] || params[:broker_agency_id]
        @broker_agency_profile = BrokerAgencyProfile.find(id)
      end
    end
  end
end