require 'rails_helper'

module BenefitSponsors
  RSpec.describe Organizations::OrganizationForms::BrokerManagementForm, type: :model, dbclean: :after_each do
    let(:broker_management_form_class) { BenefitSponsors::Organizations::OrganizationForms::BrokerManagementForm }

    subject { broker_management_form_class.new }

    let(:model_attributes) { [:employer_profile_id, :broker_agency_profile_id, :broker_role_id, :termination_date, :direct_terminate] }
    let!(:broker_agency_profile1) { FactoryGirl.create(:benefit_sponsors_organizations_broker_agency_profile, market_kind: 'shop', legal_name: 'Legal Name1') }
    let!(:person1) { FactoryGirl.create(:person) }
    let!(:broker_role1) { FactoryGirl.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile1.id, person: person1) }

    let!(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_site, :with_aca_shop_dc_employer_profile)}
    let(:employer_profile) { organization.employer_profile }

    let(:create_params) {
      {
        :broker_agency_id => broker_agency_profile1.id.to_s,
        :broker_role_id => broker_role1.id.to_s,
        :employer_profile_id => employer_profile.id.to_s
      }
    }

    let(:broker_management_form_create) { broker_management_form_class.for_create(create_params) }

    let(:terminate_params) {
      {
        :direct_terminate => "true",
        :termination_date => TimeKeeper.date_of_record.strftime('%m/%d/%Y'),
        :employer_profile_id => employer_profile.id.to_s,
        :broker_agency_id => broker_agency_profile1.id.to_s
       }
    }

    let(:broker_management_form_terminate) { broker_management_form_class.for_terminate(terminate_params) }

    before :each do
      broker_agency_profile1.update_attributes!(primary_broker_role_id: broker_role1.id)
      broker_agency_profile1.approve!
    end

    describe 'for form model attributes' do
      it 'should have all the attributes' do
        model_attributes.each do |attribute|
          expect(subject.attributes.keys).to include(attribute)
        end
      end
    end

    describe 'for_create' do
      it 'should create the form instance and assign the values from create_params' do
        expect(broker_management_form_create.broker_agency_profile_id).to eq create_params[:broker_agency_id]
        expect(broker_management_form_create.broker_role_id).to eq create_params[:broker_role_id]
        expect(broker_management_form_create.employer_profile_id).to eq create_params[:employer_profile_id]
      end

      it 'should have strings as the values for all the attributes related to for_create' do
        [:employer_profile_id, :broker_agency_profile_id, :broker_role_id].each do |attribute|
          expect(broker_management_form_create.send(attribute).class).to eq String
        end
      end
    end

    describe 'save/persist!' do
      before :each do
        broker_management_form_create.save
        organization.reload
      end

      it 'should return true once it sucessfully assigns broker agency to the employer_profile' do
        expect(broker_management_form_create.save).to eq true
      end

      it 'should assign broker agency to the employer_profile' do
        expect(employer_profile.active_benefit_sponsorship.active_broker_agency_account.benefit_sponsors_broker_agency_profile_id).to eq broker_agency_profile1.id
      end
    end

    describe 'for_terminate' do
      it 'should create the form instance and assign the values from terminate_params' do
        expect(broker_management_form_terminate.broker_agency_profile_id).to eq terminate_params[:broker_agency_id]
        expect(broker_management_form_terminate.employer_profile_id).to eq terminate_params[:employer_profile_id]
        expect(broker_management_form_terminate.direct_terminate.to_s).to eq terminate_params[:direct_terminate]
        expect(broker_management_form_terminate.termination_date.strftime('%m/%d/%Y')).to eq terminate_params[:termination_date]
      end

      it 'should have strings as the values for all the attributes related to for_terminate' do
        [:employer_profile_id, :broker_agency_profile_id].each do |attribute|
          expect(broker_management_form_terminate.send(attribute).class).to eq String
        end
      end
    end

    describe 'terminate/terminate!' do
      before :each do
        broker_management_form_create.save
        organization.reload
      end

      it 'should return true once it sucessfully terminates broker agency of the employer_profile' do
        expect(broker_management_form_terminate.terminate).to eq true
      end

      it 'should termiante active broker agency of the employer_profile' do
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts).not_to eq []
        broker_management_form_terminate.terminate
        expect(employer_profile.active_benefit_sponsorship.broker_agency_accounts).to eq []
      end
    end
  end
end