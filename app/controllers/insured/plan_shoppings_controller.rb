class Insured::PlanShoppingsController < ApplicationController
  include Acapi::Notifiers
  before_action :set_current_person, :only => [:receipt, :thankyou, :waive, :show, :plans]
  before_action :set_kind_for_market_and_coverage, only: [:thankyou, :show, :plans, :checkout, :receipt]

  def checkout
    plan = Plan.find(params.require(:plan_id))
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    hbx_enrollment.update_current(plan_id: plan.id)
    hbx_enrollment.inactive_related_hbxs

    if hbx_enrollment.employee_role.present?
      benefit_group = hbx_enrollment.benefit_group
      reference_plan = benefit_group.reference_plan
      decorated_plan = PlanCostDecorator.new(plan, hbx_enrollment, benefit_group, reference_plan)
    else
      get_aptc_info_from_session
      hbx_enrollment.update_current(elected_aptc_pct: @elected_aptc_pct, elected_amount: @elected_aptc_pct*@max_aptc)
      decorated_plan = UnassistedPlanCostDecorator.new(plan, hbx_enrollment, hbx_enrollment.elected_amount)
    end
    # notify("acapi.info.events.enrollment.submitted", hbx_enrollment.to_xml)

    if hbx_enrollment.employee_role.present? && hbx_enrollment.employee_role.hired_on > TimeKeeper.date_of_record
      flash[:error] = "You are attempting to purchase coverage prior to your date of hire on record. Please contact your Employer for assistance"
      redirect_to family_account_path
    elsif hbx_enrollment.may_select_coverage?
      hbx_enrollment.update_current(aasm_state: "coverage_selected")
      hbx_enrollment.propogate_selection
      UserMailer.plan_shopping_completed(current_user, hbx_enrollment, decorated_plan).deliver_now if hbx_enrollment.employee_role.present?
      redirect_to receipt_insured_plan_shopping_path(change_plan: params[:change_plan], enrollment_kind: params[:enrollment_kind])
    else
      redirect_to :back
    end
  end

  def receipt
    person = @person
    @enrollment = HbxEnrollment.find(params.require(:id))
    plan = @enrollment.plan
    if @enrollment.employee_role.present?
      benefit_group = @enrollment.benefit_group
      reference_plan = benefit_group.reference_plan
      @plan = PlanCostDecorator.new(plan, @enrollment, benefit_group, reference_plan)
    else
      @plan = UnassistedPlanCostDecorator.new(plan, @enrollment, @enrollment.elected_amount)
      @market_kind = "individual"
    end
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''

    if @person.employee_roles.any?
      @employer_profile = @person.employee_roles.first.employer_profile
    end
    send_receipt_emails
  end

  def thankyou
    @plan = Plan.find(params.require(:plan_id))
    @enrollment = HbxEnrollment.find(params.require(:id))

    if @enrollment.employee_role.present?
      @benefit_group = @enrollment.benefit_group
      @reference_plan = @benefit_group.reference_plan
      @plan = PlanCostDecorator.new(@plan, @enrollment, @benefit_group, @reference_plan)
    else
      get_aptc_info_from_session
      elected_amount = @max_aptc * @elected_aptc_pct

      @plan = UnassistedPlanCostDecorator.new(@plan, @enrollment, elected_amount)
    end
    @family = @person.primary_family
    #FIXME need to implement can_complete_shopping? for individual
    @enrollable = @market_kind == 'individual' ? true : @enrollment.can_complete_shopping?
    @waivable = @enrollment.can_complete_shopping?
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''

    if @person.employee_roles.any?
      @employer_profile = @person.employee_roles.first.employer_profile
    end

    respond_to do |format|
      format.html { render 'thankyou.html.erb' }
    end
  end

  def waive
    person = @person
    hbx_enrollment = HbxEnrollment.find(params.require(:id))
    waiver_reason = params[:waiver_reason]

    if hbx_enrollment.may_waive_coverage? and waiver_reason.present? and hbx_enrollment.valid?
      hbx_enrollment.update_current(aasm_state: "inactive", waiver_reason: waiver_reason)
      hbx_enrollment.propogate_waiver
      redirect_to print_waiver_insured_plan_shopping_path(hbx_enrollment), notice: "Waive Successful"
    else
      redirect_to print_waiver_insured_plan_shopping_path(hbx_enrollment), alert: "Waive Failure"
    end
  end

  def print_waiver
    @hbx_enrollment = HbxEnrollment.find(params.require(:id))
  end

  def terminate
    hbx_enrollment = HbxEnrollment.find(params.require(:id))

    if hbx_enrollment.may_terminate_coverage?
      hbx_enrollment.update_current(aasm_state: "coverage_terminated", terminated_on: TimeKeeper.date_of_record.end_of_month)
      hbx_enrollment.propogate_terminate

      redirect_to family_account_path
    else
      redirect_to :back
    end
  end

  def show
    hbx_enrollment_id = params.require(:id)
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''

    set_plans_by(hbx_enrollment_id: hbx_enrollment_id)

    @carriers = @carrier_names_map.values
    @waivable = @hbx_enrollment.can_complete_shopping?
    @max_total_employee_cost = thousand_ceil(@plans.map(&:total_employee_cost).map(&:to_f).max)
    @max_deductible = thousand_ceil(@plans.map(&:deductible).map {|d| d.is_a?(String) ? d.gsub(/[$,]/, '').to_i : 0}.max)

    #TODO get max_aptc from EligibilityDetermination
    if @person.has_active_consumer_role?
      @max_aptc = 300
      session[:max_aptc] = @max_aptc
      session[:selected_aptc_pct] = 0.8
    end
  end

  def set_elected_pct
    session[:elected_aptc_pct] = params[:elected_pct].to_f rescue 0.8
    render json: 'ok'
  end

  def plans
    set_plans_by(hbx_enrollment_id: params.require(:id))
    @plans = @plans.sort_by(&:total_employee_cost)
    @plan_hsa_status = Products::Qhp.plan_hsa_status_map(plan_ids: @plans.map(&:id))
    @change_plan = params[:change_plan].present? ? params[:change_plan] : ''
    @enrollment_kind = params[:enrollment_kind].present? ? params[:enrollment_kind] : ''
  end

  private

  def send_receipt_emails
    UserMailer.generic_consumer_welcome(@person.first_name, @person.hbx_id, @person.emails.first.address).deliver_now
    body = render_to_string 'user_mailer/secure_purchase_confirmation.html.erb', layout: false
    from_provider = HbxProfile.find_by_state_abbreviation('DC')
    message_params = {
      sender_id: from_provider.try(:id),
      parent_message_id: @person.id,
      from: from_provider.try(:legal_name),
      to: @person.full_name,
      body: body,
      subject: 'Your Secure Purchase Confirmation'
    }
    create_secure_message(message_params, @person, :inbox)
  end

  def set_plans_by(hbx_enrollment_id:)
    Caches::MongoidCache.allocate(CarrierProfile)
    @hbx_enrollment = HbxEnrollment.find(hbx_enrollment_id)
    if @market_kind == 'shop'
      @benefit_group = @hbx_enrollment.benefit_group
      @plans = @benefit_group.decorated_elected_plans(@hbx_enrollment)
    elsif @market_kind == 'individual'
      elected_plans = Plan.individual_plans(coverage_kind: @coverage_kind, active_year: TimeKeeper.date_of_record.year)
      #FIXME need benefit_package for individual
      @plans = elected_plans.collect() do |plan|
        UnassistedPlanCostDecorator.new(plan, @hbx_enrollment)
      end
    end
    # for carrier search options
    carrier_profile_ids = @plans.map(&:carrier_profile_id).map(&:to_s).uniq
    @carrier_names_map = Organization.valid_carrier_names.select{|k, v| carrier_profile_ids.include?(k)}
  end

  def thousand_ceil(num)
    return 0 if num.blank?
    (num.fdiv 1000).ceil * 1000
  end

  def set_kind_for_market_and_coverage
    @market_kind = params[:market_kind].present? ? params[:market_kind] : 'shop'
    @coverage_kind = params[:coverage_kind].present? ? params[:coverage_kind] : 'health'
  end

  def get_aptc_info_from_session
    @max_aptc = session[:max_aptc].to_f rescue 0
    elected_aptc_pct = session[:elected_aptc_pct]
    @elected_aptc_pct = elected_aptc_pct.present? ? elected_aptc_pct.to_f : 0.8
  end
end
