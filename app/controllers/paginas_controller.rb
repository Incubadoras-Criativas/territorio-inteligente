class PaginasController < ApplicationController
  def inicio
    @academias = Academia.visiveis.select(:id, :nome, :referencia, :latitude, :longitude)
  end

  def privacidade
  end
end
