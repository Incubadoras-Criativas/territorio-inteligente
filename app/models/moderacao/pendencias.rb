# Quanto há para moderar: as fotos pendentes e as academias e observações em rascunho
module Moderacao
  class Pendencias
    def self.por_tipo
      {
        fotos: Foto.pendente.count,
        academias: Academia.rascunhos.count,
        observacoes: Observacao.rascunhos.count
      }
    end

    def self.total = por_tipo.values.sum
  end
end
