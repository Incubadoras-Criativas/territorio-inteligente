class ApplicationController < ActionController::Base
  include Pagy::Method

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :configure_permitted_parameters, if: :devise_controller?

  default_form_builder FormularioBuilder

  helper_method :pendencias_de_moderacao

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :nome, :aceite_privacidade ])
  end

  # Só quem modera vê o contador. Calculado uma vez por pedido, mesmo usado em dois lugares do layout.
  def pendencias_de_moderacao
    return 0 unless current_user&.pode_moderar?

    @pendencias_de_moderacao ||= Moderacao::Pendencias.total
  end
end
