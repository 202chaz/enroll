module BenefitSponsors
  module Organizations
    class HbxProfile < BenefitSponsors::Organizations::Profile

      # field :benefit_sponsorship_id,  type: BSON::ObjectId
      field :cms_id,                  type: String
      field :us_state_abbreviation,   type: String

      private

      def initialize_profile
        return unless is_benefit_sponsorship_eligible.blank?

        write_attribute(:is_benefit_sponsorship_eligible, true)
        @is_benefit_sponsorship_eligible = true
        self
      end

      def build_nested_models
        return if inbox.present?
        build_inbox
      end
    end
  end
end