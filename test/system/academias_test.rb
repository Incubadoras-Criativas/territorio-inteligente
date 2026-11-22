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
end
