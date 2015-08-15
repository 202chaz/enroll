class CsrRole
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person
  field :organization, type: String
  field :shift, type: String
  field :cac, type: Boolean, default: false
  class << self
    
    def find(id)
      return nil if id.blank?
      people = Person.where("assister_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].assister_role : nil
    end

    def list_csrs(person_list)
      person_list.reduce([]) { |csrs, person| csrs << person.csr_role }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      # criteria = Mongoid::Criteria.new(Person)
      list_csrs(Person.where(csr_role: true))
    end

    def first
      all.first
    end

    def last
      all.last
    end

  end  

end
