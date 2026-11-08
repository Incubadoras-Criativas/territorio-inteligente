# Anexos de imagem: só JPG, PNG ou WebP, com até 10 MB cada.
# Uso no model: valida_imagens :capa, :fotos
module ValidaImagens
  extend ActiveSupport::Concern

  TIPOS_DE_IMAGEM = %w[image/jpeg image/png image/webp].freeze
  TAMANHO_MAXIMO = 10.megabytes

  class_methods do
    def valida_imagens(*nomes)
      validate { validar_imagens(nomes) }
    end
  end

  private

  def validar_imagens(nomes)
    nomes.each do |nome|
      anexo = public_send(nome)
      anexos = anexo.respond_to?(:attachments) ? anexo.attachments.to_a : [ anexo.attachment ].compact

      anexos.each do |item|
        errors.add(nome, "precisa ser uma imagem JPG, PNG ou WebP") unless item.blob.content_type.in?(TIPOS_DE_IMAGEM)
        errors.add(nome, "precisa ter no máximo 10 MB") if item.blob.byte_size > TAMANHO_MAXIMO
      end
    end
  end
end
