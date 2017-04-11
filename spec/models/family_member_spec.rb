require 'rails_helper'

describe FamilyMember do
  subject { FamilyMember.new(:is_primary_applicant => nil, :is_coverage_applicant => nil) }

  before(:each) do
    subject.valid?
  end

  it "should validate the presence of a person" do
    expect(subject).to have_errors_on(:person_id)
  end
  it "should validate the presence of is_primary_applicant" do
    expect(subject).to have_errors_on(:is_primary_applicant)
  end
  it "should validate the presence of is_coverage_applicant" do
    expect(subject).to have_errors_on(:is_coverage_applicant)
  end

end

describe FamilyMember, "given a person" do
  let(:person) { Person.new }
  subject { FamilyMember.new(:person => person) }

  it "delegates #ivl_coverage_selected to person" do
    expect(person).to receive(:ivl_coverage_selected)
    subject.ivl_coverage_selected
  end
end

describe FamilyMember, dbclean: :after_each do
  context "a family with members exists" do
    include_context "BradyBunchAfterAll"

    before :each do
      create_brady_families
    end

    let(:family_member_id) {mikes_family.primary_applicant.id}

    it "FamilyMember.find(id) should work" do
      expect(FamilyMember.find(family_member_id).id.to_s).to eq family_member_id.to_s
    end

    it "should be possible to find the primary_relationship" do
      mikes_family.dependents.each do |dependent|
        if brady_children.include?(dependent.person)
          expect(dependent.primary_relationship).to eq "child"
        else
          expect(dependent.primary_relationship).to eq "spouse"
        end
      end
    end
  end

  let(:p0) {Person.create!(first_name: "Dan", last_name: "Aurbach")}
  let(:p1) {Person.create!(first_name: "Patrick", last_name: "Carney")}
  let(:ag) { 
    fam = Family.new
    fam.family_members.build(
      :person => p0,
      :is_primary_applicant => true
    )
    fam.save!
    fam
  }
  let(:family_member_params) {
    { person: p1,
      is_primary_applicant: true,
      is_coverage_applicant: true,
      is_consent_applicant: true,
      is_active: true}
  }

  context "parent" do
    it "should equal to family" do
      family_member = ag.family_members.create(**family_member_params)
      expect(family_member.parent).to eq ag
    end

    it "should raise error with nil family" do
      family_member = FamilyMember.new(**family_member_params)
      expect{family_member.parent}.to raise_error(RuntimeError, "undefined parent family")
    end
  end

  context "person" do
    it "with person" do
      family_member = FamilyMember.new(**family_member_params)
      family_member.person= p1
      expect(family_member.person).to eq p1
    end

    it "without person" do
      expect(FamilyMember.new(**family_member_params.except(:person)).valid?).to be_falsey
    end
  end

  context "broker" do
    let(:broker_role)   {FactoryGirl.create(:broker_role)}
    let(:broker_role2)  {FactoryGirl.create(:broker_role)}

    it "with broker_role" do
      family_member = ag.family_members.create(**family_member_params)
      family_member.broker= broker_role
      expect(family_member.broker).to eq broker_role
    end

    it "without broker_role" do
      family_member = ag.family_members.create(**family_member_params)
      family_member.broker = broker_role
      expect(family_member.broker).to eq broker_role

      family_member.broker = broker_role2
      expect(family_member.broker).to eq broker_role2
    end
  end

  context "comments" do
    it "with blank" do
      family_member = ag.family_members.create({
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true,
        comments: [{priority: 'normal', content: ""}]
      })

      expect(family_member.errors[:comments].any?).to eq true
    end

    it "without blank" do
      family_member = ag.family_members.create({
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true,
        comments: [{priority: 'normal', content: "aaas"}]
      })

      expect(family_member.errors[:comments].any?).to eq false
      expect(family_member.comments.size).to eq 1
    end
  end

  describe "instantiates object." do
    it "sets and gets all basic model fields and embeds in parent class" do
      a = FamilyMember.new(
        person: p0,
        is_primary_applicant: true,
        is_coverage_applicant: true,
        is_consent_applicant: true,
        is_active: true
        )

      a.family = ag

      expect(a.person.last_name).to eql(p0.last_name)
      expect(a.person_id).to eql(p0._id)

      expect(a.is_primary_applicant?).to eql(true)
      expect(a.is_coverage_applicant?).to eql(true)
      expect(a.is_consent_applicant?).to eql(true)
    end
  end
end

describe FamilyMember, "which is inactive" do
  it "can be reactivated with a specified relationship"
end

describe FamilyMember, "given a relationship to update" do
  let(:family) { FactoryGirl.create(:family, :with_primary_family_member)}
  let(:primary_person) {family.primary_applicant}
  let(:relationship) { "spouse" }
  let(:person) { FactoryGirl.build(:person) }
  subject { FactoryGirl.build(:family_member, person: person, family: family) }
  let(:family_member2) {FactoryGirl.create(:family_member, :family => family)}
  let(:family_member3) {FactoryGirl.create(:family_member, :family => family)}

  it "should update the direct relationship" do
    subject.add_relationship(primary_person, relationship)
    rel = family.person_relationships.where(successor_id: primary_person.id, predecessor_id: subject.id).first.kind
    expect(rel).to eq relationship
  end

  it "should create inverse realtionship too" do
    subject.add_relationship(primary_person, relationship)
    rel = family.person_relationships.where(successor_id: subject.id, predecessor_id: primary_person.id).first.kind
    expect(rel).to eq relationship
    expect(family.person_relationships.count).to eq 2
  end

  it "should create the relationships" do
    family_member2.add_relationship(primary_person, "parent")
    family_member3.add_relationship(primary_person, "child")
    family.build_relationship_matrix
    expect(family.person_relationships.count).to eq 6
    family_member2.add_relationship(primary_person, "unrelated") #Test for updating the exisiting relationship
    expect(family.person_relationships.count).to eq 4
    unr_relationship = family.person_relationships.where(successor_id: primary_person.id, predecessor_id: family_member2.id).first.kind
    expect(unr_relationship).to eq "unrelated"
  end

  it "should build relationship" do
    family_member2.build_relationship(primary_person, "spouse")
    family.save
    expect(family.person_relationships.count).to eq 2
  end

  it "should destroy relationships associated to removed family member" do
    family_member2.add_relationship(primary_person, "parent")
    expect(family.person_relationships.count).to eq 2
    family_member2.remove_relationship
    expect(family.person_relationships.count).to eq 0
  end

  it "should return true if same successor exists" do
    family_member2.add_relationship(primary_person, "parent")
    expect(family_member2.same_successor_exists?(primary_person)).to eq true
  end

  it "should not return true if same successor does not exists" do
    family_member2.add_relationship(primary_person, "parent")
    expect(family_member2.same_successor_exists?(primary_person)).not_to eq false
  end
end
