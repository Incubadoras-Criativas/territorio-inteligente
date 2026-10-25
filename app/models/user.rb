class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  enum :role, { admin: 0, moderador: 1, comum: 2 }, default: :comum, validate: true

  normalizes :login, with: ->(login) { login.strip.downcase }

  before_validation :gerar_login, on: :create

  validates :nome, presence: true, length: { maximum: 80 }
  validates :login, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ },
                    length: { maximum: 30 }

  def self.from_omniauth(auth)
    # 1. Já entrou com o Google antes?
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    verificado = auth.info.email_verified

    # 2. Já tem conta com este e-mail? Só junta se o Google garantir o e-mail
    user = find_by(email: auth.info.email) if verificado
    if user
      user.update!(provider: auth.provider, uid: auth.uid)
      user.confirm unless user.confirmed?
      return user
    end

    # 3. Conta nova
    create(provider: auth.provider,
           uid: auth.uid,
           email: auth.info.email,
           nome: auth.info.name,
           password: Devise.friendly_token[0, 20]) do |novo|
      novo.skip_confirmation! if verificado
    end
  end

  private

  def gerar_login
    return if login.present?

    base = nome.to_s.split.first.to_s.parameterize.tr("_", "-").first(20).presence || "usuario"
    existentes = User.where("login ~* ?", "^#{base}(-\\d+)?$").pluck(:login)

    if existentes.none? { |l| l.casecmp?(base) }
      self.login = base
    else
      maior = existentes.filter_map { |l| l[/-(\d+)\z/, 1]&.to_i }.max || 0
      self.login = "#{base}-#{maior + 1}"
    end
  end
end
