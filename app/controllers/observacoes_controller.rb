class ObservacoesController < ApplicationController
  before_action :authenticate_user!
  before_action :carregar_academia
  before_action :carregar_observacao, only: [ :edit, :update ]
  before_action :exigir_permissao_de_edicao, only: [ :edit, :update ]

  def new
    @observacao = @academia.observacoes.build
  end

  def create
    @observacao = @academia.observacoes.build(observacao_params)
    @observacao.autor = current_user

    if @observacao.save
      redirect_to @academia, notice: aviso_de_cadastro
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @observacao.update(observacao_params)
      redirect_to @academia, notice: "Observação atualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def carregar_academia
    @academia = Academia.permitidas_para(current_user).find(params[:academia_id])
  end

  def carregar_observacao
    @observacao = @academia.observacoes.permitidas_para(current_user).find(params[:id])
  end

  def exigir_permissao_de_edicao
    redirect_to @academia, alert: "Você não pode editar esta observação." unless @observacao.editavel_por?(current_user)
  end

  def aviso_de_cadastro
    return "Observação registrada." if @observacao.visivel?

    "Observação registrada. Ela aparece para todos depois da revisão de um moderador."
  end

  # Só quem modera pode publicar: para os outros, o campo visivel é ignorado
  def observacao_params
    campos = [ :data_da_visita, *Observacao::CONDICOES, :uso, :relato, :exibir_autor, :termo_fotos ]
    campos << :visivel if current_user.pode_moderar?

    params.expect(observacao: [ *campos, fotos: [] ])
  end
end
