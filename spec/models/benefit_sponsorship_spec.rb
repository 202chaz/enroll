require 'rails_helper'

RSpec.describe BenefitSponsorship, :type => :model do

  context "an Employer is instantiated as the benefit sponsor" do
  end

  context "an HBX is instantiated as a benefit sponsor" do
    let(:hbx_profile)             { FactoryGirl.create(:hbx_profile) }
    let(:service_markets)         { %w(individual) }

    let(:valid_params){
      {
        hbx_profile:      hbx_profile,
        service_markets:  service_markets,
      }
    }

    context "with no arguments" do
      let(:params) {{}}

      it "should not save" do
        expect(BenefitSponsorship.create(**params).valid?).to be_falsey
      end
    end

    context "with no service market" do
      let(:params) {valid_params.except(:service_markets)}

      it "should fail validation" do
        expect(BenefitSponsorship.create(**params).errors[:service_markets].any?).to be_truthy
      end
    end

    context "with all required arguments" do
      let(:params)              { valid_params }
      let(:benefit_sponsorship) { BenefitSponsorship.new(**params) }
      let(:geographic_rating_area)  { FactoryGirl.build(:geographic_rating_area) }

      it "should be valid" do
        expect(benefit_sponsorship.valid?).to be_truthy
      end

      it "should save" do
        expect(benefit_sponsorship.save).to be_truthy
      end

      context "and it is saved" do
        before { benefit_sponsorship.save }

        it "should be findable by ID" do
          expect(BenefitSponsorship.find(benefit_sponsorship.id)).to eq benefit_sponsorship
        end

        context "and a benefit coverage period is defined" do
          let(:benefit_coverage_period) { FactoryGirl.build(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record - 10.days, open_enrollment_end_on: TimeKeeper.date_of_record + 10.days) }

          context "when under open enrollment" do
            before do
              benefit_sponsorship.benefit_coverage_periods = benefit_coverage_period.to_a
            end

            it 'is_under_open_enrollment should return true' do 
              expect(benefit_sponsorship.is_under_open_enrollment?).to be_truthy
            end
          end

          context "when open enrollment is closed" do
            let(:benefit_coverage_period) { FactoryGirl.build(:benefit_coverage_period, open_enrollment_start_on: TimeKeeper.date_of_record + 10.days, open_enrollment_end_on: TimeKeeper.date_of_record + 40.days) }

            before do
              benefit_sponsorship.benefit_coverage_periods = benefit_coverage_period.to_a
            end

            it 'is_under_open_enrollment should return false' do 
              expect(benefit_sponsorship.is_under_open_enrollment?).to be_falsey
            end
          end
        end

        context "and benefit coverage periods are defined for the current and following years" do
          let(:benefit_coverage_period_this_year) { 
              FactoryGirl.build(:benefit_coverage_period, 
                start_on: TimeKeeper.date_of_record.beginning_of_year, 
                end_on:   TimeKeeper.date_of_record.end_of_year,
                open_enrollment_start_on: (TimeKeeper.date_of_record.beginning_of_year - 1.month),
                open_enrollment_end_on:   (TimeKeeper.date_of_record.beginning_of_year + 1.month),
              ) 
            }
          let(:benefit_coverage_period_next_year) { 
              FactoryGirl.build(:benefit_coverage_period, 
                start_on: (TimeKeeper.date_of_record + 1.year).beginning_of_year, 
                end_on: (TimeKeeper.date_of_record + 1.year).end_of_year,
                open_enrollment_start_on: ((TimeKeeper.date_of_record + 1.year).beginning_of_year - 2.months),
                open_enrollment_end_on:   ((TimeKeeper.date_of_record + 1.year).beginning_of_year + 1.month),              
              )
            }

          before do
            benefit_sponsorship.benefit_coverage_periods = [benefit_coverage_period_this_year, benefit_coverage_period_next_year]
          end

          it 'should return this year as the current benefit coverage period' do 
            expect(benefit_sponsorship.current_benefit_coverage_period).to eq(benefit_coverage_period_this_year)
          end

          it 'should return next year as the renewal benefit coverage period' do 
            expect(benefit_sponsorship.renewal_benefit_coverage_period).to eq(benefit_coverage_period_next_year)
          end
        end



      end
    end
  end

end
