class Device < ActiveRecord::Base

  belongs_to :user
  validates :user, presence: true
  validates :user_id, readonly: true, on: :update

  validate :single_device_identifier

  def android?
    type && type == :android
  end

  def ios?
    type && type == :ios
  end

  def type
    type = :unknown
    type = :ios if apns_device_id
    type = :android if gcm_registration_id
    type
  end

  private

  def single_device_identifier
    errors.add(:apns_device_id, I18n.t('errors.messages.must_not_be_set_with_gcm_registration_id')) if apns_device_id && gcm_registration_id
    errors.add(:gcm_registration_id, I18n.t('errors.messages.must_not_be_set_with_apns_device_id')) if apns_device_id && gcm_registration_id
  end
end
