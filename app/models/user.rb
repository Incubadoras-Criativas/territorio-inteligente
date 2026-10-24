class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  enum :role, { admin: 0, moderador: 1, comum: 2 }, default: :comum, validate: true

  normalizes :login, with: ->(login) { login.strip.downcase }

  before_validation :gerar_login, on: :create

  validates :nome, presence: true, length: { maximum: 80 }
  validates :login, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ },
                    length: { maximum: 30 }

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
