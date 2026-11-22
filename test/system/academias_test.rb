require "application_system_test_case"

class AcademiasTest < ApplicationSystemTestCase

  test "o mapa aparece na ficha, com o pino" do
    visit academia_path(academias(:publicada))

    assert_selector ".mapa-ficha.leaflet-container"
    assert_selector ".mapa-ficha .pino"
  end
end
