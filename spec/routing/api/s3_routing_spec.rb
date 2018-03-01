require 'rails_helper'

describe Api::S3Controller do
  describe 'routing' do
    it 'routes to #presign' do
      expect(get('/api/s3/presign')).to(
          route_to('api/s3#presign', format: 'json'))
    end
  end
end
