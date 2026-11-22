# 0270 — O mapa na ficha da academia

> **Neste capítulo:** a ficha da academia ganha um **mapa próprio**, no lugar do link que levava para fora do site. O mapa recebe uma **lista de pontos**: hoje, a academia; depois, também os equipamentos culturais do entorno, vindos da API do CulturaEduca. O mapa de fundo e o pino, que o formulário já usava, ganham um **módulo JavaScript compartilhado**. No caminho, cuidamos da rolagem no celular, protegemos o balão do pino contra **XSS** e aprendemos a reconhecer quando a falha está na ferramenta de teste, e não no nosso código.

**Tag deste capítulo:** `cap-0270`

> O número 0270 ficou reservado para o mapa desde antes dos capítulos 0280 a 0310. Por isso, ele aparece depois deles na ordem em que o projeto foi feito.

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bundle install
bin/rails db:migrate
bin/rails test
```

Este capítulo não tem migrations: o `db:migrate` não vai fazer nada. Ele fica na lista para manter o costume.

> 🕰️ **Opcional: estudar o projeto exatamente como neste capítulo.**
> Se você está atrasado ou quer rever, crie uma branch de estudo a partir da tag do capítulo. Antes, **desligue o servidor** (Ctrl+C) e **desconecte o pgAdmin** (botão direito no servidor → *Disconnect Server*), porque o banco vai ser recriado.
>
> **1. Guarde uma cópia do seu banco** (um *dump*), para recuperar os seus dados na volta:
>
> ```bash
> pg_dump -Fc -f ~/banco-antes-do-estudo.dump territorio_inteligente_development
> ```
>
> - `pg_dump` copia o banco inteiro, estrutura e dados, para um arquivo.
> - `-Fc` usa o formato próprio do PostgreSQL, que o `pg_restore` sabe ler.
> - `-f ~/banco-antes-do-estudo.dump` é o arquivo da cópia, na sua pasta pessoal.
>
> **2. Viaje até o capítulo:**
>
> ```bash
> git switch -c estudo-0270 cap-0270
> bin/rails db:reset
> ```
>
> O `db:reset` **apaga** o banco de desenvolvimento e o recria exatamente como neste capítulo.
>
> **3. Para voltar ao presente** (de novo com o servidor desligado e o pgAdmin desconectado):
>
> ```bash
> git switch main
> bin/rails db:drop db:create
> pg_restore --no-owner -d territorio_inteligente_development ~/banco-antes-do-estudo.dump
> bin/rails db:migrate
> git branch -D estudo-0270
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo, os equipamentos, o território e a categoria.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar um `generate` ou um `install` de novo, por exemplo, criaria migrations repetidas, e o `db:migrate` daria erro.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — Por que um mapa dentro da ficha

Até aqui, a ficha da academia tinha um link "Ver no mapa", que levava a pessoa **para fora** do Território Inteligente, até o site do OpenStreetMap. Funcionava, mas tinha dois problemas:

- quem saía da ficha para ver o mapa perdia o contexto (as observações, as fotos, os equipamentos);
- o próximo passo do projeto é mostrar, **no mesmo mapa**, os equipamentos culturais do entorno de cada academia, vindos da API do CulturaEduca. Num site de fora, não temos como fazer isso.

Este capítulo traz o mapa para dentro da ficha, e já o prepara para esse próximo passo: ele não recebe **um** ponto, e sim **uma lista de pontos**. Hoje, a lista tem só a academia. Quando a API chegar, os equipamentos do entorno entram na mesma lista, sem mudar o mapa.

Pense no mural de avisos de um posto de saúde com um mapa do bairro e alfinetes coloridos. O mural não muda quando chega um aviso novo: só entra mais um alfinete.

---

## Parte 2 — O que os dois mapas têm em comum: `mapas.js`

O projeto já tinha um mapa: o do formulário da academia, do capítulo 0240, no controller Stimulus `localizacao`. O mapa novo precisa de duas coisas que estavam escritas lá dentro: **o mapa de fundo** do OpenStreetMap e **o pino** feito em CSS.

Pela regra que seguimos desde os concerns, na segunda vez que um código aparece, ele ganha um lugar próprio. No lado do navegador, esse lugar é um **módulo JavaScript**, `app/javascript/mapas.js`:

```js
// 📖 JÁ ESTÁ NO PROJETO
import * as L from "leaflet"

// O que todo mapa do projeto usa: o mapa de fundo e o pino.

// O mapa de fundo do OpenStreetMap, com o crédito que a licença exige
export function camadaDeFundo() {
  return L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
    maxZoom: 19,
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
  })
}

// Pino feito em CSS: dispensa as imagens do Leaflet.
// O tipo vira uma classe (pino-academia, pino-cultura...), para cada tipo ter a sua cor no futuro.
export function pino(tipo = "academia") {
  return L.divIcon({
    className: `pino pino-${tipo}`,
    iconSize: [ 28, 28 ],
    iconAnchor: [ 14, 28 ],
    popupAnchor: [ 0, -28 ]
  })
}
```

- **`export function`** torna a função visível para quem fizer `import`. É o equivalente, no JavaScript, aos métodos públicos de um módulo Ruby.
- **O crédito do OpenStreetMap** (`attribution`) não é enfeite: a licença dos mapas exige que ele apareça. Com o mapa de fundo num lugar só, nenhum mapa do projeto esquece o crédito.
- **`tipo`**: o pino ganha uma classe com o tipo do ponto. Hoje, todos são `pino-academia`. Os equipamentos culturais vão poder ter outra cor só com CSS.
- **`popupAnchor`**: o balão do pino abre **acima** da ponta, e não por cima dele.

### 2.1 O importmap precisa saber do arquivo

No `config/importmap.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
pin "application"
pin "mapas"
```

O `pin "mapas"` faz o importmap procurar o arquivo `app/javascript/mapas.js`, do mesmo jeito que o `pin "application"` acha o `application.js`. Sem essa linha, o navegador não sabe onde está o `"mapas"` do `import`.

> O importmap é como o `Gemfile` do JavaScript no navegador: ele diz, para cada nome usado num `import`, de onde o arquivo vem. Os controllers Stimulus não precisam de uma linha cada um porque o `pin_all_from "app/javascript/controllers"` cuida da pasta inteira.

### 2.2 O formulário passa a usar o módulo

No `localizacao_controller.js`, o código do mapa de fundo e do pino saiu, e entrou o `import`:

```js
// 📖 JÁ ESTÁ NO PROJETO
import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"
import { camadaDeFundo, pino } from "mapas"

// ...

  connect() {
    // ...
    this.mapa = L.map(this.mapaTarget).setView(ponto || this.centroValue, ponto ? 17 : 13)
    camadaDeFundo().addTo(this.mapa)
    // ...
  }

  // ...

    this.pino = L.marker(latlng, { draggable: true, icon: pino(), keyboard: true, title: "Local da academia" })
```

O método `icone()` do fim do arquivo foi apagado: o `pino()` do módulo faz o papel dele. O formulário continua funcionando **igual**, e esse é o teste de uma boa extração.

---

## Parte 3 — O controller `mapa`

O `localizacao` serve para **marcar** um ponto: clique, arraste, GPS. O mapa da ficha serve para **mostrar** pontos. São trabalhos diferentes, então são controllers diferentes. `app/javascript/controllers/mapa_controller.js`:

```js
// 📖 JÁ ESTÁ NO PROJETO
import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"
import { camadaDeFundo, pino } from "mapas"

// Mapa só de leitura, com uma lista de pontos: [{ lat, lng, titulo, tipo }].
// Hoje, a academia. Depois, também os equipamentos do entorno.
export default class extends Controller {
  static values = { pontos: Array }

  connect() {
    // A roda do mouse e, no celular, o arrastar com um dedo começam desligados:
    // quem está rolando a página não fica preso no mapa
    this.mapa = L.map(this.element, { scrollWheelZoom: false, dragging: !L.Browser.mobile })
    camadaDeFundo().addTo(this.mapa)

    const marcadores = this.pontosValue.map((ponto) => this.marcador(ponto).addTo(this.mapa))
    this.enquadrar(marcadores)

    // Tocou ou clicou no mapa: a pessoa quer mexer nele
    this.mapa.once("click", () => {
      this.mapa.dragging.enable()
      this.mapa.scrollWheelZoom.enable()
    })
  }

  disconnect() {
    this.mapa?.remove()
  }

  // --- daqui para baixo, só uso interno ---

  marcador({ lat, lng, titulo, tipo }) {
    // O nome é digitado por qualquer pessoa: entra como texto, e nunca é interpretado como HTML
    const balao = document.createElement("span")
    balao.textContent = titulo

    return L.marker([ lat, lng ], { icon: pino(tipo), title: titulo, keyboard: true }).bindPopup(balao)
  }

  // Um ponto: aproxima nele. Vários: mostra todos de uma vez.
  enquadrar(marcadores) {
    if (marcadores.length === 1) {
      this.mapa.setView(marcadores[0].getLatLng(), 17)
    } else if (marcadores.length > 1) {
      this.mapa.fitBounds(L.featureGroup(marcadores).getBounds(), { padding: [ 32, 32 ] })
    }
  }
}
```

### 3.1 Os pontos chegam prontos

O **`static values = { pontos: Array }`** faz o Stimulus ler o atributo `data-mapa-pontos-value` do HTML e entregar o conteúdo já convertido em lista. O JavaScript não precisa buscar nada no servidor: os pontos vêm junto com a página.

### 3.2 Um ponto ou vários

O `enquadrar` decide o zoom. Com **um** ponto, o mapa aproxima nele. Com **vários**, o `fitBounds` calcula o retângulo que contém todos e ajusta o zoom para mostrá-los de uma vez, com uma folga (`padding`) nas bordas. É o código que vai funcionar sozinho quando os equipamentos do entorno chegarem.

### 3.3 Não prender a rolagem da página

Um mapa no meio de uma página tem um problema conhecido: no celular, quem passa o dedo sobre ele para **rolar a página** acaba **arrastando o mapa**, e fica preso. No computador, a roda do mouse muda o zoom em vez de rolar.

Por isso, o mapa nasce com a **roda do mouse desligada** e, no celular, com o **arrastar desligado** (`L.Browser.mobile` diz se é um celular). No primeiro toque ou clique no mapa, os dois são ligados: a pessoa mostrou que quer mexer nele. O **`once`** escuta o evento uma vez só.

### 3.4 Segurança: o nome nunca vira HTML

O balão do pino mostra o nome da academia, e esse nome é **digitado por qualquer pessoa** no cadastro. O `bindPopup` do Leaflet, quando recebe um texto, monta o balão como **HTML**. Uma academia cadastrada com o nome `<img src=x onerror="...">` executaria código na página de todo mundo que abrisse a ficha. É o ataque chamado **XSS** (*cross-site scripting*).

A defesa é montar o conteúdo com o **`textContent`**, que trata tudo como texto puro. Os símbolos `<` e `>` aparecem na tela como símbolos, e nunca viram uma etiqueta HTML.

> No Rails, as views fazem isso sozinhas: o `<%= %>` escapa o texto. No JavaScript, a proteção é nossa responsabilidade: `textContent` para texto, e nunca `innerHTML` com o que veio de uma pessoa.

### 3.5 O Turbo e o `disconnect`

Quando a pessoa volta a uma página pelo botão "Voltar", o Turbo mostra uma cópia da página guardada na memória, e o Stimulus conecta os controllers de novo. Sem o **`this.mapa?.remove()`** no `disconnect`, o mesmo elemento ganharia um segundo mapa por cima do primeiro. O `?.` evita um erro caso o mapa nem tenha chegado a nascer.

---

## Parte 4 — A ficha da academia

### 4.1 Os pontos: um helper

Em `app/helpers/academias_helper.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module AcademiasHelper
  # Os pontos do mapa da ficha. Hoje, só a academia; a API do CulturaEduca vai acrescentar o entorno.
  def pontos_do_mapa(academia)
    [
      { lat: academia.latitude.to_f, lng: academia.longitude.to_f, titulo: academia.titulo, tipo: "academia" }
    ]
  end
end
```

- **O formato dos pontos é o contrato** entre o Rails e o mapa: `lat`, `lng`, `titulo` e `tipo`. Qualquer ponto que vier depois, de qualquer fonte, segue o mesmo formato.
- **`to_f`**: a latitude é um `decimal` no banco. Convertido para JSON, um `BigDecimal` vira **texto** (`"-15.8166"`), e o Leaflet espera um número.

### 4.2 A view

No `academias/show.html.erb`, o link "Ver no mapa" deu lugar a:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<div class="mapa-ficha" data-controller="mapa"
     data-mapa-pontos-value="<%= pontos_do_mapa(@academia).to_json %>"
     role="region" aria-label="Mapa com a localização de <%= @academia.titulo %>"></div>

<p class="links-mapa">
  <%= link_to "Abrir no app de mapas", "geo:#{@academia.latitude},#{@academia.longitude}?q=#{@academia.latitude},#{@academia.longitude}" %>
  ·
  <%= link_to "Ver no OpenStreetMap",
        "https://www.openstreetmap.org/?mlat=#{@academia.latitude}&mlon=#{@academia.longitude}#map=18/#{@academia.latitude}/#{@academia.longitude}",
        target: "_blank", rel: "noopener" %>
</p>
```

- **`to_json`** transforma a lista Ruby em texto JSON. O `<%= %>` escapa as aspas para caberem dentro do atributo, e o Stimulus desfaz o escape ao ler.
- **`role="region"` com `aria-label`**: para o leitor de tela, o mapa vira uma área com nome, e não um bloco mudo.
- **`geo:`** é um endereço especial que o celular entende. No Android, ele abre o aplicativo de mapas instalado, já no ponto da academia, com a opção de traçar a rota. É o "como chegar", sem depender de nenhum serviço.
- **O link do OpenStreetMap continua**, como alternativa: o `geo:` não funciona no computador nem no iPhone.

### 4.3 O CSS

No `45-academias.css`:

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* O mapa da ficha da academia */
.mapa-ficha {
  height: 16rem;
  border: 2px solid var(--cor-roxo);
  border-radius: var(--raio);
  isolation: isolate;
}

.links-mapa {
  font-size: 0.875rem;
}
```

- **`height`**: o Leaflet ocupa o tamanho do elemento. Sem uma altura, o mapa teria altura zero e não apareceria.
- **`isolation: isolate`** é a mesma correção do formulário, do bug do mapa sobre a barra de abas. O Leaflet põe as suas camadas com `z-index` alto, e elas subiriam por cima da barra e do menu. O `isolate` cria um "andar" próprio para o mapa, e as camadas dele não saem dali.

---

## Parte 5 — Os testes

### 5.1 O controller

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  test "a ficha tem o mapa com o ponto da academia" do
    academia = academias(:publicada)

    get academia_path(academia)

    assert_select "[data-controller=mapa]" do |mapa|
      pontos = JSON.parse(mapa.first["data-mapa-pontos-value"])
      assert_equal academia.titulo, pontos.first["titulo"]
      assert_kind_of Float, pontos.first["lat"]
    end
  end
```

O teste lê o JSON do atributo e confere o título e se a latitude chegou como **número**. Se um dia alguém tirar o `to_f`, ele falha.

### 5.2 O sistema: o navegador de verdade

Em `test/system/academias_test.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
require "application_system_test_case"

class AcademiasTest < ApplicationSystemTestCase
  test "o mapa aparece na ficha, com o pino" do
    visit academia_path(academias(:publicada))

    assert_selector ".mapa-ficha.leaflet-container"
    assert_selector ".mapa-ficha .pino"
  end
end
```

Um **teste de sistema** abre um navegador de verdade (o Chrome, sem janela) e roda o JavaScript. A classe `leaflet-container` é posta pelo próprio Leaflet quando o mapa nasce. Se ela aparece, o JavaScript rodou, o `import "mapas"` funcionou e o pino foi desenhado.

### 5.3 Quando a ferramenta de teste quebra: o remendo do Chrome 158

Durante este capítulo, **todos** os testes de sistema passaram a falhar, inclusive os antigos, com:

```
Selenium::WebDriver::Error::InvalidArgumentError: invalid argument: * is not a valid URL
```

Três pistas mostraram que o problema não estava no nosso código:

1. os testes **antigos**, que não tinham mudado, falhavam do mesmo jeito;
2. o erro acontecia no **`after_teardown`**, depois do teste, e não durante ele;
3. as **asserções passavam**: o relatório mostrava as asserções contadas, e o erro vinha depois delas.

A causa: entre um teste e outro, o Capybara limpa os cookies do navegador com um comando interno do Chrome, passando `"*"` ("todas as origens"). O Chrome 158 passou a recusar esse `"*"`. Atualizar as gems não resolveu, porque a versão mais nova do Capybara ainda manda o `"*"`.

A solução foi um **remendo**, no `test/application_system_test_case.rb`, o arquivo que todos os testes de sistema carregam:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
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
```

- **`prepend`** põe o nosso módulo **na frente** da classe do Capybara. Quando o Capybara chama o `execute_cdp`, o nosso método responde primeiro. Só o comando problemático é trocado. Qualquer outro passa direto para o original, pelo `super`.
- **Os cookies continuam sendo limpos** entre os testes, agora por outro comando. Sem a limpeza, o login de um teste vazaria para o seguinte.
- **O lugar importa.** No arquivo de um teste, o remendo só valeria quando aquele arquivo fosse carregado: quem rodasse só outro teste veria o erro de novo. No `application_system_test_case.rb`, ele vale para todos.
- **O comentário diz quando remover.** Um remendo sem data de validade vira código esquecido.

Para conferir que o remendo está no lugar certo, rode um teste de sistema **que não tem nada a ver** com o mapa:

```bash
bin/rails test test/system/validacao_test.rb
```

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 6 — Testando no navegador

1. **A ficha de uma academia** mostra o mapa com o pino. Clique no pino: o balão traz o nome.
2. **Role a página com o mouse sobre o mapa**: a página rola, e o mapa não muda o zoom. Clique no mapa e role de novo: agora o zoom muda.
3. **No celular**, a página rola com o dedo sobre o mapa. Um toque no mapa libera o arrastar.
4. **"Abrir no app de mapas"**, num celular Android, abre o aplicativo de mapas no ponto da academia.
5. **O formulário de academia** continua igual: mapa, pino arrastável e GPS.
6. **Volte e avance** pelo histórico do navegador: o mapa não duplica.

> Para abrir o projeto no celular durante o desenvolvimento, suba o servidor com `bin/dev -b 0.0.0.0` e abra no celular `http://IP-DO-SEU-PC:3000`. O IP aparece com `hostname -I`.

### Tente quebrar

| Tente | O que deve acontecer |
| --- | --- |
| Cadastrar uma academia com o nome `<b>negrito</b>` e abrir o balão do pino | Aparecer o texto `<b>negrito</b>`, com os símbolos, e não a palavra em negrito |
| Abrir o menu com o mapa na tela | O menu fica por cima do mapa |
| Voltar e avançar várias vezes pelo histórico | Um mapa só, sempre |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Módulo JavaScript** | Um arquivo que exporta funções para outros arquivos importarem. O "concern" do navegador. |
| **`export` / `import`** | Torna uma função visível para outros arquivos / traz uma função de outro arquivo. |
| **`pin`** (importmap) | Diz ao navegador de onde vem cada nome usado num `import`. |
| **Stimulus Values** | Os dados que o controller lê dos atributos `data-*-value`, já convertidos. |
| **`fitBounds`** | Ajusta o mapa para mostrar todos os pontos de uma vez. |
| **XSS** | Um ataque em que um texto digitado por alguém vira código na página dos outros. |
| **`textContent`** | Põe texto num elemento sem interpretar HTML. A defesa contra o XSS no JavaScript. |
| **`geo:`** | Um endereço que o celular abre no aplicativo de mapas. |
| **Teste de sistema** | Um teste que abre um navegador de verdade e roda o JavaScript. |
| **`prepend`** | Põe um módulo na frente de uma classe, para os métodos dele responderem primeiro. |
| **Remendo** (*monkey patch*) | Uma mudança no comportamento de uma biblioteca de fora, feita pelo nosso código. Temporária, e com aviso de quando remover. |

---

## O que aprendemos

- Um mapa que recebe uma lista de pontos está pronto para crescer sem mudar.
- O que dois arquivos JavaScript têm em comum ganha um módulo próprio, como os concerns do Ruby.
- Texto digitado por pessoas entra no HTML como texto, e nunca como código.
- Um mapa no meio da página não pode sequestrar a rolagem.
- Quando os testes antigos também falham, e no mesmo ponto, a culpa pode ser da ferramenta, e não do código.
- Um remendo mora onde vale para todos, e diz quando deve sair.

**Próximo capítulo:** [0320 — O mapa na capa](0320-mapa-na-capa.md)

---

## Fontes

- [Leaflet — documentação](https://leafletjs.com/reference.html)
- [Leaflet — `fitBounds`](https://leafletjs.com/reference.html#map-fitbounds)
- [OpenStreetMap — Copyright e licença](https://www.openstreetmap.org/copyright)
- [Stimulus Handbook — Values](https://stimulus.hotwired.dev/reference/values)
- [importmap-rails](https://github.com/rails/importmap-rails)
- [MDN — `textContent`](https://developer.mozilla.org/pt-BR/docs/Web/API/Node/textContent)
- [OWASP — Cross Site Scripting (XSS)](https://owasp.org/www-community/attacks/xss/)
- [Rails Guides — System Testing](https://guides.rubyonrails.org/testing.html#system-testing)
- [teamcapybara/capybara — issue #2535](https://github.com/teamcapybara/capybara/issues/2535)
