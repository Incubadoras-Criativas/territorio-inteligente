require "application_system_test_case"

class AcademiasTest < ApplicationSystemTestCase
  test "o mapa aparece na ficha, com o pino" do
    visit academia_path(academias(:publicada))

    assert_selector ".mapa-ficha.leaflet-container"
    assert_selector ".mapa-ficha .pino"
  end

  test "a capa mostra o mapa e o botão Perto de mim" do
    visit root_path

    assert_selector ".mapa-capa.leaflet-container"
    assert_button "Perto de mim"
  end

  test "o formulário de academia tem o mapa, e tocar nele marca o ponto" do
    login_as users(:ana)
    visit new_academia_path

    assert_selector ".mapa-formulario.leaflet-container"

    find(".mapa-formulario").click
    assert_selector ".mapa-formulario .pino"
    assert_not_empty find_field("Latitude").value
  end
end
