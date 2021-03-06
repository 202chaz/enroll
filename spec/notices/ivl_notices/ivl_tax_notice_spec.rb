require 'rails_helper'

RSpec.describe IvlNotices::IvlTaxNotice, dbclean: :after_each do
  let(:person) { FactoryGirl.create(:person, :with_consumer_role, :with_mailing_address)}
  let(:family) {FactoryGirl.create(:family, :with_primary_family_member, person: person)}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'1095A Tax Cover Letter Notice',
                            :notice_template => 'notices/ivl/ivl_tax_notice',
                            :notice_builder => 'IvlNotices::IvlTaxNotice',
                            :event_name => 'ivl_tax_cover_letter_notice',
                            :options => { :is_an_aqhp_hbx_enrollment => true},
                            :mpi_indicator => 'IVL_TAX',
                            :title => "Your 1095-A Health Coverage Tax Form"})
                          }
  let(:valid_params) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :options => { :is_an_aqhp_hbx_enrollment => true},
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{IvlNotices::IvlTaxNotice.new(person.consumer_role, valid_params)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_params.delete(key)
          expect{IvlNotices::IvlTaxNotice.new(person.consumer_role, valid_params)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "deliver" do
    before :each do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @ivl_tax_cover_letter_notice = IvlNotices::IvlTaxNotice.new(person.consumer_role, valid_params)
      @ivl_tax_cover_letter_notice.build
    end

    it "should create a pdf template for address" do
      expect(@ivl_tax_cover_letter_notice.notice.primary_address.present?).to be_truthy
    end

    it "should not receive a primary_fullname" do
      expect(@ivl_tax_cover_letter_notice.notice.primary_fullname).to eq ""
    end

    it "should receive attach_taglines" do
      expect(@ivl_tax_cover_letter_notice).to receive :attach_taglines
      @ivl_tax_cover_letter_notice.attach_taglines
    end

    it "should receive attach_non_discrimination" do
      expect(@ivl_tax_cover_letter_notice).to receive :attach_non_discrimination
      @ivl_tax_cover_letter_notice.attach_non_discrimination
    end

    it "should receive attach_blank_page" do
      notice_path = @ivl_tax_cover_letter_notice.notice_path
      expect(@ivl_tax_cover_letter_notice).to receive :attach_blank_page
      @ivl_tax_cover_letter_notice.attach_blank_page(notice_path)
    end

    it "should receive send_generic_notice_alert" do
      expect(@ivl_tax_cover_letter_notice).to receive :send_generic_notice_alert
      @ivl_tax_cover_letter_notice.send_generic_notice_alert
    end

    it "should receive store_paper_notice" do
      expect(@ivl_tax_cover_letter_notice).to receive :store_paper_notice
      @ivl_tax_cover_letter_notice.store_paper_notice
    end

    it "should have an mpi_indicator" do
      expect(@ivl_tax_cover_letter_notice.mpi_indicator).to eq application_event.mpi_indicator
    end
  end

  describe "render template and generate pdf" do
    before do
      allow(person).to receive("primary_family").and_return(family)
      allow(person).to receive_message_chain("families.first.primary_applicant.person").and_return(person)
      @ivl_tax_cover_letter_notice = IvlNotices::IvlTaxNotice.new(person.consumer_role, valid_params)
    end

    it "should render ivl_tax_cover_letter_notice" do
      expect(@ivl_tax_cover_letter_notice.template).to eq "notices/ivl/ivl_tax_notice"
    end

    it "should generate pdf" do
      @ivl_tax_cover_letter_notice.append_hbe
      @ivl_tax_cover_letter_notice.build
      file = @ivl_tax_cover_letter_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end
end