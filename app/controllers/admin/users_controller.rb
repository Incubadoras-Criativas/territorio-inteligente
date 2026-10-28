module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :edit, :update ]

    def index
      usuarios = User.order(:nome)

      if params[:q].present?
        termo = "%#{User.sanitize_sql_like(params[:q])}%"
        usuarios = usuarios.where("nome ILIKE :termo OR login ILIKE :termo", termo: termo)
      end

      @pagy, @users = pagy(:offset, usuarios, limit: 20)
    end

    def edit
    end

    def update
      if @user == current_user && user_params[:role] != "admin"
        redirect_to admin_users_path, alert: "Você não pode remover o seu próprio acesso de administrador."
      elsif @user.update(user_params)
        redirect_to admin_users_path, notice: "Nível de acesso de #{@user.nome} atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.expect(user: [ :role ])
    end
  end
end
