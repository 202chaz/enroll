class PersonRelationship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person

  MaleRelationships   = %W(father grandfather grandson uncle nephew adopted\ child stepparent
                              foster\ child son-in-law brother-in-law father-in-law brother ward
                              stepson child sponsored\ dependent dependent\ of\ a\ minor\ dependent
                              guardian court\ appointed\ guardian collateral\ dependent life\ partner)

  FemaleRelationships = %W(mother grandmother granddaughter aunt niece adopted\ child stepparent
                              foster\ child daughter-in-law sister-in-law mother-in-law sister ward
                              stepdaughter child sponsored\ dependent dependent\ of\ a\ minor\ dependent
                              guardian court\ appointed\ guardian collateral\ dependent life\ partner)
    Relationships = [
    "spouse",
    "child",
    "domestic_partner",
    "parent",
    "sibling",
    "ward",
    "guardian",
    "unrelated",
    "other tax dependent"
  ]

  InverseMap = {
    "child" => "parent",
    "parent" => "child",
    "guardian" => "ward",
    "ward" => "guardian",

    # bi directional
    "self" => "self",
    "sibling" => "sibling",
    "domestic_partner" => "domestic_partner",
    "spouse" => "spouse",
    "unrelated" => "unrelated",
    "other tax dependent" => "other tax dependent"

    #one directional
  }

  SymmetricalRelationships = %W[head\ of\ household spouse ex-spouse cousin ward trustee annuitant other\ relationship other\ relative self]

  Kinds = SymmetricalRelationships | Relationships

  field :relative_id, type: BSON::ObjectId
  field :kind, type: String

	validates_presence_of :relative_id, message: "Choose a relative"
  validates :kind,
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: Kinds, message: "%{value} is not a valid person relationship"}

  def parent
    raise "undefined parent class: Person" unless person?
    self.person
  end

  def relative=(new_person)
    raise ArgumentError.new("expected Person") unless new_person.is_a? Person
    self.relative_id = new_person._id
    @relative = new_person
  end

  def relative
    return @relative if defined? @relative
    @relative = Person.find(self.relative_id) unless self.relative_id.blank?
  end

  def invert_relationship
    self.kind = InverseMap[self.kind]
    self
  end
end
