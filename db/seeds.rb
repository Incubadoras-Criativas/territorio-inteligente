# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Administrador de DESENVOLVIMENTO. A senha fica no código, então
# este bloco nunca roda em produção: lá o admin é criado de outro jeito.
if Rails.env.development?
    User.find_or_create_by!(email: "admin@territorio.local") do |u|
        u.nome = "Admin"
        u.login = "admin"
        u.password = "123456"
        u.role = :admin
        u.skip_confirmation!
    end

    # Usuários de exemplo, para ver a lista com volume
    if User.count < 50
        Faker::Config.locale = "pt-BR"

        200.times do |i|
            User.create!(nome: "#{Faker::Name.first_name} #{Faker::Name.last_name}",
                         email: "exemplo#{i}@exemplo.com",
                         password: "123456") do |u|
                u.skip_confirmation!
            end
        end
    end
end

# Equipamentos das academias ao ar livre (lista provisória: ajustar com o levantamento de campo)
[
    "Simulador de caminhada",
    "Simulador de cavalgada",
    "Remada sentada",
    "Puxador alto",
    "Leg press",
    "Surf",
    "Esqui",
    "Rotação diagonal",
    "Rotação vertical",
    "Multiexercitador",
    "Alongador"
].each do |nome|
    Equipamento.find_or_create_by!(nome: nome)
end

Categoria.find_or_create_by!(nome: "Academia ao ar livre")
