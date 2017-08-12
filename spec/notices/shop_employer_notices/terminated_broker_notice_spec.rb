require 'rails_helper'

RSpec.describe TerminatedBrokerNotice do
  before(:all) do
    @employer_profile = FactoryGirl.create(:employer_profile)
    @broker_role =  FactoryGirl.create(:broker_role, aasm_state: 'active')
    @organization = FactoryGirl.create(:broker_agency, legal_name: "broker_agency_one")
    @organization.broker_agency_profile.update_attributes(primary_broker_role: @broker_role)
    @broker_role.update_attributes(broker_agency_profile_id: @organization.broker_agency_profile.id)
    @organization.broker_agency_profile.approve!
    @employer_profile.broker_role_id = @broker_role.id
    @employer_profile.hire_broker_agency(@organization.broker_agency_profile)
    @employer_profile.broker_agency_accounts.detect {|account| account.is_active?}.update_attributes({is_active: false,end_on:TimeKeeper.date_of_record})
    @employer_profile.save!(validate: false)
  end

  let(:organization) { @organization }
  let(:employer_profile){@employer_profile }
  let(:person) { @broker_role.person }
  let(:broker_role) { @broker_role }
  let(:broker_agency_account) {FactoryGirl.create(:broker_agency_account, broker_agency_profile: @organization.broker_agency_profile,employer_profile: @employer_profile)}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let!(:plan_year) { FactoryGirl.create(:plan_year, employer_profile: employer_profile, start_on: start_on, :aasm_state => 'draft', :fte_count => 55) }
  let!(:active_benefit_group) { FactoryGirl.create(:benefit_group, plan_year: plan_year, title: "Benefits #{plan_year.start_on.year}") }
  let(:end_on) {TimeKeeper.date_of_record}

  #add broker to broker agency profile
  let(:application_event){ double("ApplicationEventKind",{
      :name =>'Employee termination notice by employer',
      :notice_template => 'notices/shop_employer_notices/broker_termination_notice.html.erb',
      :notice_builder => 'TerminatedBrokerNotice',
      :mpi_indicator => 'MPI_SHOP_D050',
      :event_name => 'broker_termination_notice',
      :title => "Broker Terminated by Employer"})
  }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "Construct Terminated Notice" do
    context "valid params" do
      it "should initialze" do
        expect{TerminatedBrokerNotice.new(employer_profile, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{TerminatedBrokerNotice.new(employer_profile, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "build notice data" do
    before do
      @broker_agency_notice = TerminatedBrokerNotice.new(employer_profile, valid_params)
    end
    it "should build notice with all necessary info" do
      @broker_agency_notice.build
      expect(@broker_agency_notice.notice.mpi_indicator).to eq application_event.mpi_indicator
      expect(@broker_agency_notice.notice.employer_profile).to eq employer_profile
      expect(@broker_agency_notice.notice.broker_agency_profile).to eq organization.broker_agency_profile
    end
  end

end