module Admin
  class EquipamentosController < BaseController
    include EscolheFotosDaGaleria

    before_action :carregar_equipamento, only: [ :edit, :update ]

    def index
      @equipamentos = Equipamento.order(:nome)
    end

    def new
      @equipamento = Equipamento.new
    end

    def create
      @equipamento = Equipamento.new(equipamento_params)
      aplicar_fotos(@equipamento)

      if @equipamento.save
        redirect_to admin_equipamentos_path, notice: "Equipamento cadastrado."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      @equipamento.assign_attributes(equipamento_params)
      aplicar_fotos(@equipamento)

      if @equipamento.save
        redirect_to admin_equipamentos_path, notice: "Equipamento atualizado."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar_equipamento
      @equipamento = Equipamento.includes(fotos: { imagem: { arquivo_attachment: :blob } })
      .find_by!(slug: params[:slug])
    end

    def equipamento_params
      params.expect(equipamento: [ :nome, :slug, :visivel ])
    end
  end
end
