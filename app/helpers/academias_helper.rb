module AcademiasHelper
  # Os pontos do mapa da ficha. Hoje, só a academia; a API do CulturaEduca vai acrescentar o entorno.
  def pontos_do_mapa(academia)
    [
      { lat: academia.latitude.to_f, lng: academia.longitude.to_f, titulo: academia.titulo, tipo: "academia" }
    ]
  end
end
