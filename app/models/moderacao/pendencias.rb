# Quanto há para moderar: as fotos pendentes e as academias e observações em rascunho
module Moderacao
  class Pendencias
    def self.total
      Foto.pendente.count + Academia.rascunhos.count + Observacao.rascunhos.count
    end
  end
end
