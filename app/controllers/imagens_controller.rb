# A galeria pessoal: cada pessoa só vê e só mexe nas próprias imagens.
class ImagensController < ApplicationController
  before_action :authenticate_user!

  def index
    @imagens = current_user.imagens.recentes.with_attached_arquivo
    @espaco_usado = current_user.espaco_usado
  end

  def show
    @imagem = current_user.imagens.find(params[:id])
  end

  # Aceita várias imagens de uma vez: cada arquivo vira uma Imagem.
  def create
    envio = params.expect(imagem: [ :termo_fotos, arquivos: [] ])
    arquivos = Array(envio[:arquivos]).compact_blank

    if arquivos.empty?
      redirect_to imagens_path, alert: "Escolha pelo menos uma imagem.", status: :see_other
      return
    end

    imagens = arquivos.map do |arquivo|
      current_user.imagens.create(arquivo: arquivo, termo_fotos: envio[:termo_fotos])
    end
    recusadas = imagens.reject(&:persisted?)

    if recusadas.empty?
      redirect_to imagens_path, notice: "#{imagens.size} imagem(ns) enviada(s) para a sua galeria.", status: :see_other
    else
      erros = recusadas.flat_map { |imagem| imagem.errors.full_messages }.uniq.to_sentence
      redirect_to imagens_path, alert: "#{imagens.size - recusadas.size} de #{imagens.size} enviada(s). #{erros}", status: :see_other
    end
  end

  def destroy
    current_user.imagens.find(params[:id]).destroy
    redirect_to imagens_path, notice: "Imagem removida.", status: :see_other
  end
end
