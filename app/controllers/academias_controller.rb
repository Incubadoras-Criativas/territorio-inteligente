class AcademiasController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :carregar_academia, only: [ :show, :edit, :update ]
  before_action :exigir_permissao_de_edicao, only: [ :edit, :update ]

  def index
    @academias = Academia.permitidas_para(current_user).order(:nome)
  end

  def show
    @observacoes = @academia.observacoes.permitidas_para(current_user).recentes
    .with_rich_text_relato.with_attached_fotos.includes(:autor)
  end

  def new
    @academia = Academia.new(categorias: Categoria.where(slug: "academia-ao-ar-livre"))
  end

  def create
    @academia = current_user.academias.build(academia_params)

    if @academia.save
      redirect_to new_academia_observacao_path(@academia),
        notice: "#{aviso_de_cadastro} Agora, registre o que você observou."
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

  def carregar_academia
    @academia = Academia.permitidas_para(current_user).find(params[:id])
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
    campos = [ :nome, :referencia, :latitude, :longitude ]
    campos << :visivel if current_user.pode_moderar?

    params.expect(academia: [ *campos, categoria_ids: [], quantidades: {} ])
  end
end
