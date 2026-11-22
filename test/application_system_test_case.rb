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

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 320, 712 ]
end
