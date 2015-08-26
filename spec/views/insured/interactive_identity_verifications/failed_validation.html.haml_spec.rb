require "rails_helper"

describe "insured/interactive_identity_verifications/failed_validation" do
  let(:mock_response) { instance_double("IdentityVerification::InteractiveVerificationResponse", :transaction_id => "the_transaction_id") }

  it "should show a message about the user failing validation and providing contact info" do
    assign :verification_response, mock_response
    render :template => "insured/interactive_identity_verifications/failed_validation.html.haml"
    expect(rendered).to include("You have not passed identity validation.  To proceed please contact the exchange at #XXX-XXX-XXXX, and provide them with reference number #the_transaction_id.")
  end

  it "should show a link to invoke fars" do
    assign :verification_response, mock_response
    render :template => "insured/interactive_identity_verifications/failed_validation.html.haml"
    expect(rendered).to include("Please click here once you have contacted the exchange and been told to proceed.")
    expect(rendered).to include("href=\"/insured/interactive_identity_verifications/the_transaction_id\"")
  end
end
