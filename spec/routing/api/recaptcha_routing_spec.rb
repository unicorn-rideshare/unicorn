require 'rails_helper'

describe Api::RecaptchaController do
  describe 'routing' do
    it 'routes to #create' do
      expect(post('/api/recaptcha')).to(
          route_to('api/recaptcha#create', format: 'json'))
    end
  end
end
