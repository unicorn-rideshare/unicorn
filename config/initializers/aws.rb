Aws.config.update(
    credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'] || 'accesskeyid', ENV['AWS_SECRET_ACCESS_KEY'] || 'secretaccesskey'),
    region: ENV['AWS_REGION'] || 'us-east-1',
    http_wire_trace: Rails.env.development?,
)
