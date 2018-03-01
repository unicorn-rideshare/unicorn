class ApplicationController < ActionController::Base
  include Unicorn::HttpErrors
  include Unicorn::TokenAuthenticatable

  protect_from_forgery with: :exception

  skip_before_action :verify_authenticity_token, unless: :verify_authenticity_token?
  after_action :set_csrf_cookie_for_ng

  after_action :set_x_frame_options

  private

  def json_request?
    request.format.json?
  end

  def xml_request?
    request.format.xml?
  end

  def raw_request
    raw_request = "#{request.method} #{request.fullpath} #{request.headers['SERVER_PROTOCOL']}\r\n"
    request.headers.env.select { |key| key =~ /^HTTP_/ }.reject { |key| key =~ /^HTTP_VERSION$/ }.each { |name, value| raw_request += "#{name.gsub(/^HTTP_/i, '').gsub(/_/i, '-').downcase}: #{value}\r\n" }
    raw_request += "\r\n#{request.body.read}"
    raw_request
  end

  def raw_response
    raw_response = "#{request.headers['HTTP_VERSION']} #{response.code} #{response.status_message}\r\n"
    raw_response += "date: #{response.date ? response.date.httpdate : DateTime.now.httpdate}\r\n"
    raw_response += "server: #{request.env['SERVER_SOFTWARE']}\r\n"
    raw_response += "content-type: #{response.content_type}\r\n"
    raw_response += "content-length: #{response.body.bytesize}\r\n"
    response.headers.each { |name, value| raw_response += "#{name.downcase}: #{value}\r\n" }
    raw_response += "\r\n#{response.body}"
    raw_response
  end

  def request_headers
    headers = {}
    request.headers.env.select { |key| key =~ /^HTTP_/ }.reject { |key| key =~ /^HTTP_VERSION$/ }.each { |name, value| headers[name.gsub(/^HTTP_/i, '').gsub(/_/i, '-').downcase] = value }
    headers
  end

  def request_ip
    request_headers['x-real-ip'] || request.remote_ip
  end

  def set_csrf_cookie_for_ng
    cookies['XSRF-TOKEN'] = form_authenticity_token if protect_against_forgery?
  end

  def set_x_frame_options
    response.headers['x-frame-options'] = "ALLOW-FROM #{Settings.app.x_frame_options_allow_from}" if Settings.app.x_frame_options_allow_from
    response.headers.except! 'X-Frame-Options' if current_user.nil? && Settings.app.x_frame_options_sent_only_if_authenticated
  end

  def verified_request?
    form_authenticity_token == request.headers['X-XSRF-TOKEN'] || super
  end

  def verify_authenticity_token?
    !json_request? && !xml_request?
  end
end
