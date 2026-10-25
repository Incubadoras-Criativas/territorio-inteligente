module ApplicationHelper
  def login_com_google?
    Rails.application.credentials.dig(:google, :client_id).present?
  end
end
