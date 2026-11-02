class AcademiasController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :carregar_academia, only: [ :show, :edit, :update ]
  before_action :exigir_permissao_de_edicao, only: [ :edit, :update ]

  def index
    @academias = academias_permitidas.includes(:territorio).order(:nome)
  end

  def show
  end

  def new
    @academia = Academia.new(categorias: Categoria.where(slug: "academia-ao-ar-livre"))
  end

  def create
    @academia = current_user.academias.build(academia_params)

    if @academia.save
      redirect_to @academia, notice: aviso_de_cadastro
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @academia.update(academia_params)
      redirect_to @academia, notice: "Academia atualizada."
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  # Visitante: só as publicadas. Comum: as publicadas e os próprios rascunhos. Moderador e admin: todas.
  def academias_permitidas
    return Academia.visiveis unless user_signed_in?
    return Academia.all if current_user.pode_moderar?

    Academia.visiveis.or(Academia.where(autor: current_user))
  end

  def carregar_academia
    @academia = academias_permitidas.find(params[:id])
  end

  def exigir_permissao_de_edicao
    redirect_to @academia, alert: "Você não pode editar esta academia." unless @academia.editavel_por?(current_user)
  end

  def aviso_de_cadastro
    return "Academia cadastrada." if @academia.visivel?

    "Academia cadastrada. Ela aparece para todos depois da revisão de um moderador."
  end

  # Só quem modera pode publicar: para os outros, o campo visivel é ignorado
  def academia_params
    campos = [ :nome, :referencia, :territorio_id, :latitude, :longitude ]
    campos << :visivel if current_user.pode_moderar?

    params.expect(academia: [ *campos, categoria_ids: [], quantidades: {} ])
  end
end
