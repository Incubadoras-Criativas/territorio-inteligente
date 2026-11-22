require "application_system_test_case"
require "test_helper"

require "capybara/selenium/driver"

# O Chrome 158 passou a recusar a origem "*" que o Capybara usa para limpar
# o navegador entre os testes. Enquanto o Capybara não corrige, limpamos os
# cookies por outro comando, que o Chrome aceita.
# Remover quando o Capybara for atualizado com a correção.
module LimpezaDoChromeCompativel
  def execute_cdp(comando, **parametros)
    if comando == "Storage.clearDataForOrigin" && parametros[:origin] == "*"
      return super("Network.clearBrowserCookies")
    end

    super
  end
end

Capybara::Selenium::Driver::ChromeDriver.prepend(LimpezaDoChromeCompativel)

class AcademiasTest < ApplicationSystemTestCase

  test "o mapa aparece na ficha, com o pino" do
    visit academia_path(academias(:publicada))

    assert_selector ".mapa-ficha.leaflet-container"
    assert_selector ".mapa-ficha .pino"
  end
end
