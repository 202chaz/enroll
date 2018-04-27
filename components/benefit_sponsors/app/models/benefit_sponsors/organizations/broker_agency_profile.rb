module BenefitSponsors
  module Organizations
    class BrokerAgencyProfile < BenefitSponsors::Organizations::Profile
      include SetCurrentUser
      include AASM

      MARKET_KINDS = [:individual, :shop, :both]

      MARKET_KINDS_OPTIONS = {
        "Individual & Family Marketplace ONLY" => "individual",
        "Small Business Marketplace ONLY" => "shop",
        "Both – Individual & Family AND Small Business Marketplaces" => "both"
      }

      field :entity_kind, type: Symbol
      field :market_kind, type: Symbol
      field :corporate_npn, type: String
      field :primary_broker_role_id, type: BSON::ObjectId
      field :default_general_agency_profile_id, type: BSON::ObjectId

      field :languages_spoken, type: Array, default: ["en"] # TODO
      field :working_hours, type: Boolean, default: false
      field :accept_new_clients, type: Boolean

      field :aasm_state, type: String

      field :home_page, type: String

      embeds_many :documents, as: :documentable
      accepts_nested_attributes_for :inbox

      has_many :broker_agency_contacts, class_name: "Person", inverse_of: :broker_agency_contact
      accepts_nested_attributes_for :broker_agency_contacts, reject_if: :all_blank, allow_destroy: true

      validates_presence_of :market_kind, :entity_kind #, :primary_broker_role_id

      validates :corporate_npn,
        numericality: {only_integer: true},
        length: { minimum: 1, maximum: 10 },
        uniqueness: true,
        allow_blank: true

      validates :market_kind,
        inclusion: { in: Organizations::BrokerAgencyProfile::MARKET_KINDS, message: "%{value} is not a valid practice area" },
        allow_blank: false

      validates :entity_kind,
        inclusion: { in: Organizations::Organization::ENTITY_KINDS[0..3], message: "%{value} is not a valid business entity kind" },
        allow_blank: false

      after_initialize :build_nested_models

      scope :active,      ->{ any_in(aasm_state: ["is_applicant", "is_approved"]) }
      scope :inactive,    ->{ any_in(aasm_state: ["is_rejected", "is_suspended", "is_closed"]) }

      # has_one primary_broker_role
      def primary_broker_role=(new_primary_broker_role = nil)
        if new_primary_broker_role.present?
          raise ArgumentError.new("expected BrokerRole class") unless new_primary_broker_role.is_a? BrokerRole
          self.primary_broker_role_id = new_primary_broker_role._id
        else
          unset("primary_broker_role_id")
        end
        @primary_broker_role = new_primary_broker_role
      end

      def primary_broker_role
        return @primary_broker_role if defined? @primary_broker_role
        @primary_broker_role = BrokerRole.find(self.primary_broker_role_id) unless primary_broker_role_id.blank?
      end

      def employer_clients
      end

      def family_clients
      end

      def market_kinds
        BrokerAgencyProfile::MARKET_KINDS_OPTIONS
      end

      def language_options
        LanguageList::COMMON_LANGUAGES
      end

      def primary_office_location
        office_locations.detect(&:is_primary?)
      end

      def phone
        office = primary_office_location
        office && office.phone.to_s
      end

      ## Class methods
      class << self

        def find(id)
          organizations = BenefitSponsors::Organizations::GeneralOrganization.broker_agency_profiles.where(:"profiles._id" =>  BSON::ObjectId.from_string(id)).to_a
          organizations.size > 0 ? organizations.first.profiles.where(_type: /.*BrokerAgencyProfile$/, _id: id ).first: nil
        end

      end

      aasm do #no_direct_assignment: true do
        state :is_applicant, initial: true
        state :is_approved
        state :is_rejected
        state :is_suspended
        state :is_closed

        event :approve do
          transitions from: [:is_applicant, :is_suspended], to: :is_approved
        end

        event :reject do
          transitions from: :is_applicant, to: :is_rejected
        end

        event :suspend do
          transitions from: [:is_applicant, :is_approved], to: :is_suspended
        end

        event :close do
          transitions from: [:is_approved, :is_suspended], to: :is_closed
        end
      end

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, false)
        @is_benefit_sponsorship_eligible = false
        self
      end

      def build_nested_models
        build_inbox if inbox.nil?
      end

    end
  end
end