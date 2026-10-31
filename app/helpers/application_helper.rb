module ApplicationHelper
  def login_com_google?
    Rails.application.credentials.dig(:google, :client_id).present?
  end

  def icone(nome)
    svg = Rails.root.join("app/assets/images/icones/#{nome}.svg").read
    svg.sub("<svg", '<svg class="icone" aria-hidden="true" focusable="false"').html_safe
  end
end
