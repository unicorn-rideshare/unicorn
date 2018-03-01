require 'rails_helper'

describe 'api/invitations/show' do
  let(:invitation) { FactoryGirl.create(:invitation) }

  it 'should render invitation' do
    @invitation = invitation
    render
    expect(JSON.parse(rendered)).to eq(
                                        'id' => invitation.id,
                                        'user' => {
                                            'id' => invitation.invitable.id,
                                            'email' => invitation.invitable.email,
                                            "name" => invitation.invitable.name,
                                        }
                                    )
  end
end
