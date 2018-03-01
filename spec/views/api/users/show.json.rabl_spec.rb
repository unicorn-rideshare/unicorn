require 'rails_helper'

describe 'api/users/show' do
  let(:user) { FactoryGirl.create(:user, name: 'Joe User', email: 'joe@gmail.com') }

  context 'when the user has an attached profile image' do
    before do
      FactoryGirl.create(:attachment,
                         attachable: user,
                         url: 'http://attachments.example.com/photo.jpg',
                         tags: %w(profile_image default))
    end

    it 'should render the attached :profile_image_url' do
      @user = user
      render
      expect(JSON.parse(rendered)).to eq(
                                          'id' => user.id,
                                          'name' => 'Joe User',
                                          'email' => 'joe@gmail.com',
                                          'profile_image_url' => 'http://attachments.example.com/photo.jpg',
                                          'company_ids' => [],
                                          'provider_ids' => [],
                                          'default_company_id' => nil,
                                          'stripe_customer_id' => nil,
                                          'last_checkin_at' => nil,
                                          'last_checkin_heading' => nil,
                                          'last_checkin_latitude' => nil,
                                          'last_checkin_longitude' => nil,
                                          'wallets' => [],
                                      )
    end
  end

  context 'when the user does not have an attached profile image' do
    it 'should render nil as the :profile_image_url' do
      @user = user
      render
      expect(JSON.parse(rendered)).to eq(
                                          'id' => user.id,
                                          'name' => 'Joe User',
                                          'email' => 'joe@gmail.com',
                                          'profile_image_url' => nil,
                                          'company_ids' => [],
                                          'provider_ids' => [],
                                          'default_company_id' => nil,
                                          'stripe_customer_id' => nil,
                                          'last_checkin_at' => nil,
                                          'last_checkin_heading' => nil,
                                          'last_checkin_latitude' => nil,
                                          'last_checkin_longitude' => nil,
                                          'wallets' => [],
                                      )
    end
  end
end
