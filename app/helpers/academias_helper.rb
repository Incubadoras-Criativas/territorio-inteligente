module AcademiasHelper
  # Uma academia no formato que o mapa entende
  def ponto_da_academia(academia)
    {
      lat: academia.latitude.to_f,
      lng: academia.longitude.to_f,
      titulo: academia.titulo,
      tipo: "academia",
      url: academia_path(academia)
    }
  end

  # Os pontos do mapa da ficha. Hoje, só a academia; a API do CulturaEduca vai acrescentar o entorno.
  def pontos_do_mapa(academia)
    [ ponto_da_academia(academia) ]
  end
end
