require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationsController, type: :controller, dbclean: :after_each do

    routes { BenefitSponsors::Engine.routes }

    let(:form_class)  { BenefitSponsors::Forms::BenefitApplicationForm }
    let(:user) { FactoryGirl.create :user}
    let!(:site)  { FactoryGirl.create(:benefit_sponsors_site, :with_owner_exempt_organization, :with_benefit_market, :with_benefit_market_catalog, :dc) }
    let(:organization) { FactoryGirl.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_dc_employer_profile, site: site) }
    let(:benefit_sponsorship) { FactoryGirl.create(:benefit_sponsors_benefit_sponsorship, organization: organization,benefit_market: site.benefit_markets[0]) }
    let(:benefit_sponsorship_id) { benefit_sponsorship.id.to_s }
    let(:effective_period_start_on) { TimeKeeper.date_of_record.end_of_month + 1.day + 1.month }
    let(:effective_period_end_on)   { effective_period_start_on + 1.year - 1.day }
    let(:open_enrollment_period_start_on) { effective_period_start_on.prev_month }
    let(:open_enrollment_period_end_on)   { open_enrollment_period_start_on + 9.days }

    let(:benefit_application_params) {

      {
        :start_on => effective_period_start_on,
        :end_on => effective_period_end_on,
        :fte_count => "1",
        :pte_count => "1",
        :msp_count => "1",
        :open_enrollment_start_on => open_enrollment_period_start_on,
        :open_enrollment_end_on => open_enrollment_period_end_on,
        :benefit_sponsorship_id => benefit_sponsorship_id
      }
    }

    before do
      benefit_sponsorship.benefit_market.update_attributes!(:site_urn => site.site_key)
    end

    describe "GET new", dbclean: :after_each do

      it "should initialize the form" do
        sign_in_and_do_new
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      it "should be a success" do
        sign_in_and_do_new
        expect(response).to have_http_status(:success)
      end

      it "should render new template" do
        sign_in_and_do_new
        expect(response).to render_template("new")
      end

      def sign_in_and_do_new
        sign_in user
        get :new, :benefit_sponsorship_id => benefit_sponsorship_id
      end
    end

    describe "POST create", dbclean: :after_each do

      it "should redirect" do
        sign_in_and_do_create
        expect(response).to have_http_status(:redirect)
      end

      it "should redirect to benefit packages new" do
        sign_in_and_do_create
        expect(response.location.include?("benefit_packages/new")).to eq true
      end

      it "should initialize form" do
        sign_in_and_do_create
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      context "when create fails" do

        before do
          benefit_application_params.merge!({
              open_enrollment_end_on: nil
            })
        end

        it "should redirect to new" do
          sign_in_and_do_create
          expect(response).to render_template("new")
        end

        it "should return error messages" do
          sign_in_and_do_create
          expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
        end
      end

      def sign_in_and_do_create
        sign_in user
        post :create, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "GET edit", dbclean: :after_each do

      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(params) }

      before do
        ben_app.save
      end

      it "should be a success" do
        sign_in user
        get :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(response).to have_http_status(:success)
      end

      it "should render edit template" do
        sign_in user
        get :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(response).to render_template("edit")
      end

      it "should initialize form" do
        sign_in user
        get :edit, :benefit_sponsorship_id => benefit_sponsorship_id, id: ben_app.id.to_s, :benefit_application => benefit_application_params
        expect(form_class).to respond_to(:for_edit)
      end
    end

    describe "POST update" do
      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:ben_app_params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(ben_app_params) }

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.save
      end

      it "should be a success" do
        sign_in_and_do_update
        # expect(response).to have_http_status(:success)
      end

      it "should initialize form" do
        sign_in_and_do_update
        expect(assigns(:benefit_application_form).class).to eq form_class
      end

      it "should redirect to benefit packages index" do
        sign_in_and_do_update
        expect(response.location.include?("benefit_packages")).to eq true
      end

      context "when update fails" do

        before do
          benefit_application_params.merge!({
              open_enrollment_end_on: nil
            })
        end

        it "should redirect to edit" do
          sign_in_and_do_update
          expect(response).to render_template("edit")
        end

        it "should return error messages" do
          sign_in_and_do_update
          expect(flash[:error]).to match(/Open enrollment end on can't be blank/)
        end
      end

      def sign_in_and_do_update
        sign_in user
        post :update, :id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id, :benefit_application => benefit_application_params
      end
    end

    describe "POST publish" do

      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:ben_app_params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let!(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(ben_app_params) }

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.benefit_packages.build
        ben_app.save
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_publish
        sign_in user
        post :publish, :benefit_application_id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      context "benefit application published sucessfully" do
        it "should redirect with success message" do
          sign_in_and_publish
          expect(flash[:notice]).to eq "Benefit Application successfully published."
        end
      end

      context "benefit application published sucessfully but with warning" do

        before do
          allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplication).to receive_message_chain('assigned_census_employees_without_owner.present?').and_return(false)
        end

        it "should redirect with success message" do
          sign_in_and_publish
          expect(flash[:notice]).to eq "Benefit Application successfully published."
          expect(flash[:error]).to eq "<li>Warning: You have 0 non-owner employees on your roster. In order to be able to enroll under employer-sponsored coverage, you must have at least one non-owner enrolled. Do you want to go back to add non-owner employees to your roster?</li>"
        end
      end

      context "benefit application did not publish due to warnings" do

        before :each do
          allow_any_instance_of(BenefitSponsors::Organizations::AcaShopDcEmployerProfile).to receive(:is_primary_office_local?).and_return(false)
        end

        it "should display warnings" do
          sign_in_and_publish
          expect(flash[:error]).to match(/Primary office location Has its principal business address in the #{Settings.aca.state_name} and offers coverage to all full time employees through #{Settings.site.short_name} or Offers coverage through #{Settings.site.short_name} to all full time employees whose Primary worksite is located in the #{Settings.aca.state_name}/)
        end
      end

      context "benefit application did not publish due to errors" do
        before :each do
          ben_app.benefit_packages.destroy
        end

        it "should redirect with errors" do
          sign_in_and_publish
          expect(flash[:error]).to match(/Benefit Application failed to publish/)
        end
      end
    end

    describe "POST force publish", dbclean: :after_each do

      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:ben_app_params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let!(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(ben_app_params) }

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.benefit_packages.build
        ben_app.save
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_force_publish
        sign_in user
        post :force_publish, :benefit_application_id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      it "should redirect" do
        sign_in_and_force_publish
        expect(response).to have_http_status(:redirect)
      end

      it "should expect benefit application state to be publish_pending" do
        allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplication).to receive(:is_application_eligible?).and_return(false)
        sign_in_and_force_publish
        ben_app.reload
        expect(ben_app.aasm_state).to eq "publish_pending"
      end

      it "should display errors" do
        allow_any_instance_of(BenefitSponsors::BenefitApplications::BenefitApplication).to receive(:is_application_eligible?).and_return(false)
        sign_in_and_force_publish
        expect(flash[:error]).to match(/this application is ineligible for coverage/)
      end
    end

    describe "POST revert", dbclean: :after_each do

      let(:effective_period)                { effective_period_start_on..effective_period_end_on }
      let(:open_enrollment_period)          { open_enrollment_period_start_on..open_enrollment_period_end_on }

      let(:ben_app_params) {
          {
            effective_period: effective_period,
            open_enrollment_period: open_enrollment_period
          }
        }
      let!(:ben_app)       { BenefitSponsors::BenefitApplications::BenefitApplication.new(ben_app_params) }

      before do
        benefit_sponsorship.benefit_applications = [ben_app]
        ben_app.benefit_packages.build
        ben_app.save
        benefit_sponsorship.update_attributes(:profile_id => benefit_sponsorship.organization.profiles.first.id)
      end

      def sign_in_and_revert
        sign_in user
        post :revert, :benefit_application_id => ben_app.id.to_s, :benefit_sponsorship_id => benefit_sponsorship_id
      end

      context "when there is no eligible application to revert" do
        it "should redirect" do
          sign_in_and_revert
          expect(response).to have_http_status(:redirect)
        end

        it "should display error message" do
          sign_in_and_revert
          expect(flash[:error]).to match(/Benefit Application is not eligible to revert/)
        end
      end

      context "when there is an eligible application to revert" do

        before do
          ben_app.update_attributes(:aasm_state => "enrolled")
        end

        it "should revert benefit application" do
          sign_in_and_revert
          ben_app.reload
          expect(ben_app.aasm_state).to eq "draft"
        end

        it "should redirect to employer profiles benefits tab" do
          sign_in_and_revert
          expect(response.location.include?("tab=benefits")).to eq true
        end
      end
    end
  end
end