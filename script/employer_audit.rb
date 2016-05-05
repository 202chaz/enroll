include Employers::EmployerHelper

all_employers = Organization.where(:employer_profile => {"$ne" => nil})

def elected_plans_choice(benefit_group)
	option = benefit_group.plan_option_kind
	if option == "single_plan"
		return benefit_group.elected_plans.first.name
	elsif option == "single_carrier"
		return benefit_group.reference_plan.carrier_profile.legal_name
	elsif option == "metal_level"
		return benefit_group.reference_plan.metal_level.titleize
	end
end

CSV.open("employer_audit_data_tab1.csv", "w") do |csv|
	csv << ["Legal Name", "DBA", "FEIN", "AASM State", "Coverage Year Start", "Coverage Year End",
			"Plan Offerings", "Reference Plan Name", "Reference Plan HIOS", "Reference Plan Metal Level",
			"", "", "Employer Contribution", "", "",
			"Employee Count","Address"]
	csv << ["","","","","","","","","","",
			"Employee", "Spouse", "Domestic Partner","Child Under 26", "Child Over 26"]
	all_employers.each do |employer|
		begin
		legal_name = employer.legal_name
		dba = employer.dba
		fein = employer.fein
		state = employer.employer_profile.aasm_state
		plan_years = employer.employer_profile.plan_years
		employee_count = employer.employer_profile.roster_size
		office_locations = employer.office_locations
		addresses = []
		if office_locations != nil
			office_locations.each do |location|
				next if location.is_primary == false
				addresses.push(location.try(:address).try(:full_address))
			end
		end
		plan_years.each do |plan_year|
			start_date = plan_year.start_on
			end_date = plan_year.end_on
			benefit_groups = plan_year.benefit_groups
			benefit_groups.each do |benefit_group|
				elected_plans = elected_plans_choice(benefit_group)
				reference_plan = benefit_group.reference_plan
				reference_plan_name = reference_plan.name
				reference_plan_hios = reference_plan.hios_id
				reference_plan_metal = reference_plan.metal_level
				benefits_hashes_array = []
				benefit_group.relationship_benefits.each do |benefit|
					benefits_hashes_array.push({benefit.relationship => benefit.premium_pct})
				end
				emp_contrib = benefits_hashes_array.detect{|benefit_hash| benefit_hash["employee"]}
				if emp_contrib != nil
					emp_contrib = emp_contrib["employee"].to_s
				end
				spouse_contrib = benefits_hashes_array.detect{|benefit_hash| benefit_hash["spouse"]}
				if spouse_contrib != nil
					spouse_contrib = spouse_contrib["spouse"].to_s
				end
				dp_contrib = benefits_hashes_array.detect{|benefit_hash| benefit_hash["domestic_partner"]}
				if dp_contrib != nil
					dp_contrib = dp_contrib["domestic_partner"].to_s
				end
				under_26_contrib = benefits_hashes_array.detect{|benefit_hash| benefit_hash["child_under_26"]}
				if under_26_contrib != nil
					under_26_contrib = under_26_contrib["child_under_26"].to_s
				end
				over_26_contrib = benefits_hashes_array.detect{|benefit_hash| benefit_hash["child_26_and_over"]}
				if over_26_contrib != nil
					over_26_contrib = over_26_contrib["child_26_and_over"]
				end
				csv << [legal_name, dba, fein, state, start_date, end_date,
						elected_plans, reference_plan_name, reference_plan_hios, reference_plan_metal,
						emp_contrib,spouse_contrib,dp_contrib,under_26_contrib,over_26_contrib,
						employee_count, addresses.first]
			end
		end
		rescue Exception=>e
			puts e.backtrace
			puts "----------------------------"
		end
	end
end

count = 0

CSV.open("employer_audit_data_tab2.csv","w") do |csv|
	csv << ["Employer Name", "Employer FEIN", "Employee Name", "HBX ID",
			"Hire Date", "Date Added to Roster", "Coverage State",
			"Coverage Status"]
	all_employers.each do |employer|
			employer_name = employer.legal_name
			fein = employer.fein
			census_employees = employer.employer_profile.census_employees
			census_employees.each do |census_employee|
				begin
				count += 1
				name = "#{census_employee.first_name} #{census_employee.last_name}"
				employee_role = census_employee.employee_role
				unless employee_role == nil
					hbx_id = employee_role.hbx_id
				end
				hire_date = census_employee.hired_on
				roster_added = census_employee.created_at
				coverage_state = census_employee.active_benefit_group_assignment.try(:aasm_state)
				if coverage_state.present?
					coverage_state = coverage_state.humanize
				end
				state_of_enrollment = enrollment_state(census_employee)
				csv << [employer_name, fein, name, hbx_id, hire_date, roster_added, coverage_state, state_of_enrollment]
				rescue Exception=>e
					puts "#{count} - #{census_employee.first_name} #{census_employee.last_name}"
					puts e.backtrace
					puts "---"*50
				end
			end
	end
end
