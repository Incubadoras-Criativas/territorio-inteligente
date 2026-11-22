# 0320 — O mapa na capa

> **Neste capítulo:** a capa do site passa a mostrar um **mapa grande com todas as academias publicadas**, e o balão de cada pino leva à ficha da academia. Um botão **"Perto de mim"** leva o mapa até onde a pessoa está. O controller `mapa` do capítulo 0270 **cresce sem quebrar** o mapa da ficha, com targets e valores opcionais. E a proteção que impede os mapas de passarem por cima do menu passa a valer para todos os mapas de uma vez.

**Tag deste capítulo:** `cap-0320`

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

Este capítulo não tem migrations: o `db:migrate` não vai fazer nada. O `bundle install` traz as versões novas do puma e do rack-protection (Parte 7).

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
> git switch -c estudo-0320 cap-0320
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
> git branch -D estudo-0320
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

## Parte 1 — A primeira coisa que se vê

A capa do site era só o título, uma frase e o link "Quero participar". Quem chegava não via o que o Território Inteligente faz. Agora, a capa mostra **o mapa com todas as academias publicadas**, e um botão **"Perto de mim"** leva o mapa até onde a pessoa está.

As regras:

| Regra | Como fica no código |
| --- | --- |
| Só aparecem academias **publicadas**: rascunhos nunca chegam à capa | `Academia.visiveis` no controller |
| O balão de cada pino **leva à ficha** da academia | O campo `url` no ponto |
| A localização só é pedida **quando a pessoa toca** no botão | A ação `pertoDeMim` do Stimulus |
| Sem nenhuma academia publicada, o mapa abre no **Marco Zero** | O valor `centro` |

Quase tudo isso já existia: o controller `mapa` do capítulo 0270 foi feito para receber uma lista de pontos. Este capítulo mostra como **fazer crescer** um controller sem quebrar quem já o usa.

---

## Parte 2 — O ponto, num lugar só

Em `app/helpers/academias_helper.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module AcademiasHelper
  # Uma academia no formato que o mapa entende
  def ponto_da_academia(academia)
    {
      lat: academia.latitude.to_f,
      lng: academia.longitude.to_f,
      titulo: academia.titulo,
      tipo: "academia",
      url: academia_path(academia)
    }
  end

  # Os pontos do mapa da ficha. Hoje, só a academia; a API do CulturaEduca vai acrescentar o entorno.
  def pontos_do_mapa(academia)
    [ ponto_da_academia(academia) ]
  end
end
```

- **O formato de um ponto** agora mora num método só, o `ponto_da_academia`, usado pela ficha e pela capa. Se o formato mudar, muda num lugar.
- **O campo novo `url`** diz para onde o balão do pino leva.
- O Rails disponibiliza **todos os helpers em todas as views**. A capa, que é do `PaginasController`, enxerga um helper do `AcademiasHelper` sem nenhuma configuração.

---

## Parte 3 — A capa

### 3.1 O controller

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  def inicio
    @academias = Academia.visiveis.select(:id, :nome, :referencia, :latitude, :longitude)
  end
```

- **`visiveis`**: só as publicadas. A capa é a página mais vista do site, e um rascunho nunca pode aparecer nela.
- **`select`**: traz do banco só as colunas que o mapa usa. Com centenas de academias, a capa continua leve. O `nome` e a `referencia` estão na lista porque o `titulo` depende deles.

### 3.2 A view

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<section class="mapa-da-capa" data-controller="mapa"
         data-mapa-pontos-value="<%= @academias.map { |academia| ponto_da_academia(academia) }.to_json %>">
  <div class="mapa-capa" data-mapa-target="area"
       role="region" aria-label="Mapa das academias ao ar livre"></div>

  <div class="acoes-mapa-capa">
    <button type="button" class="botao-secundario" data-action="mapa#pertoDeMim">
      <%= icone("map-pin") %> Perto de mim
    </button>
    <p class="dica" data-mapa-target="status" role="status"></p>
  </div>

  <p class="dica"><%= pluralize(@academias.size, "academia publicada", plural: "academias publicadas") %> no mapa.</p>
</section>
```

Repare na estrutura: o controller `mapa` fica na **`<section>`**, que abraça o mapa **e** o botão. O mapa em si fica numa `<div>` marcada como **target `area`**. Assim, o botão, que está fora do mapa, consegue chamar uma ação do mesmo controller.

> Pense num controle remoto e numa televisão no mesmo móvel. O controller é o móvel inteiro: dentro dele, a tela (o `area`) e o controle (o botão) conversam.

O **`role="status"`** no parágrafo dos avisos faz o leitor de tela anunciar o texto quando ele muda ("Procurando a sua localização…"), sem a pessoa precisar ir até ele.

---

## Parte 4 — O controller `mapa` cresce

O controller do capítulo 0270 ganhou quatro coisas. A versão completa, `app/javascript/controllers/mapa_controller.js`:

```js
// 📖 JÁ ESTÁ NO PROJETO
import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"
import { camadaDeFundo, pino } from "mapas"

// Mapa só de leitura, com uma lista de pontos: [{ lat, lng, titulo, tipo, url }].
// O mapa fica no target "area" (ou no próprio elemento, se não houver target).
// Opcional: um botão "Perto de mim" e uma área de avisos (target "status").
export default class extends Controller {
  static targets = [ "area", "status" ]

  static values = {
    pontos: Array,
    // Marco Zero do DF, para quando não há nenhum ponto
    centro: { type: Array, default: [ -15.7942, -47.8825 ] }
  }

  connect() {
    const area = this.hasAreaTarget ? this.areaTarget : this.element

    // A roda do mouse e, no celular, o arrastar com um dedo começam desligados:
    // quem está rolando a página não fica preso no mapa
    this.mapa = L.map(area, { scrollWheelZoom: false, dragging: !L.Browser.mobile })
    camadaDeFundo().addTo(this.mapa)

    const marcadores = this.pontosValue.map((ponto) => this.marcador(ponto).addTo(this.mapa))
    this.enquadrar(marcadores)

    // Tocou ou clicou no mapa: a pessoa quer mexer nele
    this.mapa.once("click", () => this.liberar())
  }

  disconnect() {
    this.mapa?.remove()
  }

  // Botão "Perto de mim": a localização só é pedida quando a pessoa toca
  pertoDeMim() {
    if (!navigator.geolocation) {
      this.avisar("Este navegador não informa a localização.")
      return
    }

    this.avisar("Procurando a sua localização…")
    navigator.geolocation.getCurrentPosition(
      (posicao) => this.mostrarOndeEstou(posicao),
      () => this.avisar("Não foi possível usar a sua localização."),
      { enableHighAccuracy: true, timeout: 20000, maximumAge: 60000 }
    )
  }

  // --- daqui para baixo, só uso interno ---

  marcador({ lat, lng, titulo, tipo, url }) {
    // O nome é digitado por qualquer pessoa: entra como texto, e nunca é interpretado como HTML
    const balao = document.createElement(url ? "a" : "span")
    balao.textContent = titulo
    if (url) balao.href = url

    return L.marker([ lat, lng ], { icon: pino(tipo), title: titulo, keyboard: true }).bindPopup(balao)
  }

  // Nenhum ponto: o Marco Zero. Um ponto: aproxima nele. Vários: mostra todos de uma vez.
  enquadrar(marcadores) {
    if (marcadores.length === 0) {
      this.mapa.setView(this.centroValue, 11)
    } else if (marcadores.length === 1) {
      this.mapa.setView(marcadores[0].getLatLng(), 17)
    } else {
      this.mapa.fitBounds(L.featureGroup(marcadores).getBounds(), { padding: [ 32, 32 ] })
    }
  }

  mostrarOndeEstou(posicao) {
    const aqui = L.latLng(posicao.coords.latitude, posicao.coords.longitude)

    this.voceEstaAqui?.remove()
    this.voceEstaAqui = L.circleMarker(aqui, { radius: 9, weight: 3, className: "voce-esta-aqui" })
                         .addTo(this.mapa)
                         .bindPopup("Você está aqui")

    this.liberar()
    this.mapa.setView(aqui, 15)
    this.avisar("")
  }

  liberar() {
    this.mapa.dragging.enable()
    this.mapa.scrollWheelZoom.enable()
  }

  avisar(texto) {
    if (this.hasStatusTarget) this.statusTarget.textContent = texto
  }
}
```

### 4.1 Crescer sem quebrar

| O que mudou | Por quê |
| --- | --- |
| **Target `area`**, com o próprio elemento como reserva | Na capa, o mapa fica no target. Na ficha da academia, que não tem target, o mapa continua no próprio elemento. **A view da ficha não mudou uma linha** |
| **Target `status`**, opcional | O `avisar` só escreve se o target existir (`hasStatusTarget`). A ficha, que não tem área de avisos, não quebra |
| **Valor `centro`**, com o Marco Zero como padrão | Sem nenhum ponto, o mapa abre num lugar que faz sentido para o DF. Outro território poderia passar outro centro pelo HTML |
| **Balão com link** | Quando o ponto tem `url`, o balão é um `<a>`. O nome continua entrando como **texto** (`textContent`), protegido contra XSS. O endereço vem do servidor (`academia_path`), e não de quem digitou |

É o mesmo princípio de um método Ruby que ganha um argumento novo **com valor padrão**: quem já chamava o método do jeito antigo continua funcionando.

### 4.2 O "Perto de mim"

- **A localização só é pedida no toque.** Pedir a localização sem uma ação da pessoa é má prática, e muitos navegadores bloqueiam. É a mesma regra do formulário da academia, no capítulo 0240.
- **`maximumAge: 60000`**: aceita uma localização de até 1 minuto atrás, se o celular tiver uma guardada. A resposta vem mais rápido, e a capa não precisa da precisão do cadastro.
- **`setView(aqui, 15)`**: o zoom 15 mostra o bairro em volta, onde se veem as academias próximas.
- **O "Você está aqui" é um círculo**, e não um pino (`circleMarker`), para não ser confundido com uma academia.
- **`liberar()`**: ao localizar a pessoa, o mapa libera o arrastar. Ela quer explorar em volta.

> O GPS só funciona em páginas **seguras**: HTTPS ou `localhost`. Testando no celular pelo IP da rede (`http://192.168...`), o "Perto de mim" responde "Não foi possível usar a sua localização". Em produção, com HTTPS, ele funciona.

---

## Parte 5 — O CSS

### 5.1 O mapa da capa, no `45-academias.css`

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* O mapa grande da capa */
.mapa-da-capa {
  display: grid;
  gap: var(--espaco-1);
}

.mapa-capa {
  height: 60vh;
  min-height: 18rem;
  border: 2px solid var(--cor-roxo);
  border-radius: var(--raio);
}

.acoes-mapa-capa {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: var(--espaco-1);
}

/* "Você está aqui": um círculo amarelo com borda roxa, diferente dos pinos */
.voce-esta-aqui {
  fill: var(--cor-amarelo);
  fill-opacity: 1;
  stroke: var(--cor-roxo);
}
```

- **`60vh`**: o mapa ocupa 60% da altura da tela, no celular e no computador. O `min-height` garante um tamanho mínimo em telas muito baixas.
- **`.voce-esta-aqui`**: o `circleMarker` do Leaflet é desenhado em **SVG**. Por isso as propriedades são `fill` (preenchimento) e `stroke` (contorno), e não `background` e `border`.

### 5.2 Todos os mapas no seu "andar", no `05-leaflet.css`

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* Todo mapa do projeto fica no seu próprio "andar": as camadas do Leaflet
   (z-index de até 1000) não sobem por cima da barra de abas nem do menu */
.leaflet-container {
  isolation: isolate;
}
```

Até aqui, cada mapa tinha o seu `isolation: isolate`: o do formulário e o da ficha. Com três mapas, a proteção passou para a classe que o Leaflet põe em **todo** mapa que ele cria, a `leaflet-container`. Assim, nenhum mapa futuro esquece a proteção, e o `isolation` saiu das regras de cada mapa.

> Pense nas regras de segurança de um prédio. Em vez de pendurar um extintor em cada sala nova, a norma do prédio exige extintor em toda sala. Ninguém precisa lembrar.

---

## Parte 6 — Os testes

### 6.1 Rascunho nunca na capa

No `test/controllers/paginas_controller_test.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  test "a capa mostra no mapa só as academias publicadas" do
    get root_path

    assert_select "[data-controller=mapa]" do |mapa|
      titulos = JSON.parse(mapa.first["data-mapa-pontos-value"]).map { |ponto| ponto["titulo"] }
      assert_includes titulos, academias(:publicada).titulo
      assert_not_includes titulos, academias(:rascunho_da_ana).titulo
    end
  end
```

É o teste mais importante do capítulo: ele garante que **um rascunho nunca aparece na capa**.

### 6.2 O mapa nasce no lugar certo

No `test/system/academias_test.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  test "a capa mostra o mapa e o botão Perto de mim" do
    visit root_path

    assert_selector ".mapa-capa.leaflet-container"
    assert_button "Perto de mim"
  end
```

O seletor **`.mapa-capa.leaflet-container`** (as duas classes juntas, sem espaço) só encontra algo se o Leaflet criou o mapa **na `<div>` da área**. Se, por algum motivo, o mapa fosse criado na `<section>` inteira, ele cobriria o botão e a contagem, e este teste falharia. O teste de controller não pegaria isso, porque ele confere o HTML que o Rails monta, e não o que o JavaScript faz com ele no navegador.

> Os dois tipos de teste se completam: o de **controller** prova o que o servidor envia; o de **sistema** prova o que a pessoa vê.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 7 — Manutenção: as gems de segurança

Durante este capítulo, o CI acusou alertas novos de segurança em duas gems: o **puma** (o servidor da aplicação) e o **rack-protection** (que chega ao projeto como dependência do OmniAuth, o login com Google). A base de vulnerabilidades que o `bundler-audit` consulta é atualizada todo dia, e uma gem segura ontem pode ter um alerta hoje.

A correção segue sempre o mesmo roteiro:

```bash
# 📖 JÁ ESTÁ NO PROJETO
bundle update puma rack-protection --conservative
bin/bundler-audit
git diff Gemfile.lock
```

- **`--conservative`** atualiza só as gems pedidas, sem levar as dependências delas junto.
- **`bin/bundler-audit`** precisa responder *"No vulnerabilities found"*.
- **`git diff Gemfile.lock`** confirma que só as gems pedidas mudaram.

Para ler um alerta do `bundler-audit`, bastam três linhas de cada bloco: **`Name`** (qual gem), **`Version`** (a versão que temos) e **`Solution`** (as versões que corrigem).

No servidor, depois do deploy, o `bundle install` instala as versões novas, e o `restart` sobe o Puma atualizado. Para conferir, o `systemctl status` mostra a versão do Puma na linha do processo.

---

## Parte 8 — Testando no navegador

1. **A capa** mostra o mapa com as academias publicadas, todas enquadradas.
2. **Clique num pino**: o balão traz o nome como link, e o link abre a ficha.
3. **"Perto de mim"**: o navegador pede a localização, o mapa vai até você e mostra o círculo amarelo.
4. **Role a página** com o mapa na tela: ele não passa por cima da barra de abas.
5. **A ficha de uma academia** continua com o mapa dela, igual.

### Tente quebrar

| Tente | O que deve acontecer |
| --- | --- |
| Despublicar todas as academias (como moderador) e abrir a capa | O mapa abre no Marco Zero, com "0 academias publicadas" |
| Cadastrar uma academia nova, como comum, e abrir a capa | Ela não aparece até um moderador publicar |
| Negar a permissão de localização no "Perto de mim" | Aparece "Não foi possível usar a sua localização", e o mapa continua onde estava |

> **Para depois:** com muitas academias perto umas das outras, os pinos se sobrepõem (já acontece em Ceilândia). A solução é **agrupar** os pinos próximos num círculo com o número de academias, que se abre ao aproximar o mapa. O Leaflet tem um complemento para isso, o *MarkerCluster*.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Target opcional** | Um target que o controller usa só se ele existir (`hasXxxTarget`). |
| **Valor com padrão** | Um `value` do Stimulus que tem um valor quando o HTML não informa nenhum. |
| **`circleMarker`** | Um círculo de tamanho fixo no mapa, desenhado em SVG. |
| **`vh`** | Uma medida em porcentagem da altura da tela: `60vh` é 60% dela. |
| **`fill` e `stroke`** | O preenchimento e o contorno de um desenho em SVG. |
| **`role="status"`** | Faz o leitor de tela anunciar o texto quando ele muda. |
| **Agrupamento de pinos** (*clustering*) | Juntar pinos próximos num só, com a contagem, para o mapa não ficar poluído. |

---

## O que aprendemos

- A primeira página do site mostra o que ele faz.
- O que vai para a página mais vista passa por um filtro: só o que foi publicado.
- Um controller cresce com targets e valores opcionais, sem quebrar quem já o usava.
- O formato de um dado usado em vários lugares mora num método só.
- Uma proteção que vale para todos os casos vai para a regra comum, e não para cada caso.
- O teste de controller prova o que o servidor envia; o de sistema, o que a pessoa vê.
- Um alerta de segurança numa gem se resolve com um roteiro curto: atualizar só ela, conferir e enviar.

**Próximo capítulo:** em breve.

---

## Fontes

- [Stimulus Handbook — Targets: optional targets](https://stimulus.hotwired.dev/reference/targets#optional-targets)
- [Stimulus Handbook — Values: default values](https://stimulus.hotwired.dev/reference/values#default-values)
- [Leaflet — `circleMarker`](https://leafletjs.com/reference.html#circlemarker)
- [MDN — Geolocation API](https://developer.mozilla.org/pt-BR/docs/Web/API/Geolocation_API)
- [MDN — `role="status"`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/status_role)
- [MDN — `isolation`](https://developer.mozilla.org/pt-BR/docs/Web/CSS/isolation)
- [Leaflet.markercluster](https://github.com/Leaflet/Leaflet.markercluster)
- [bundler-audit](https://github.com/rubysec/bundler-audit)
