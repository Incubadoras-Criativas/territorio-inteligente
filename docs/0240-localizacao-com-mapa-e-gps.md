# 0240 — Localização com mapa e GPS

> **Neste capítulo:** o cadastro de academias ganha um **mapa**. Quem está na praça toca em **"Usar minha localização"**, e o GPS do celular marca o ponto. Quem cadastra de casa toca no mapa, e pode arrastar o pino até o lugar exato. Vamos conhecer o **Leaflet**, a biblioteca de mapas mais usada da web livre, o **OpenStreetMap**, o mapa feito por voluntários, e a **Geolocation API**, o jeito de uma página pedir a localização ao navegador. E vamos descobrir por que o GPS se recusa a funcionar em certos endereços.

**Tag deste capítulo:** `cap-0240`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails test
```

Este capítulo não tem migration nem gem nova. O Leaflet entra pelo **importmap**, e o arquivo dele já vem no `git pull`, na pasta `vendor/javascript/`.

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
> git switch -c estudo-0240 cap-0240
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
> git branch -D estudo-0240
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo, os equipamentos, o território e a categoria.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar o `bin/importmap pin` ou o `generate stimulus` de novo, por exemplo, baixaria o Leaflet de novo ou sobrescreveria o controller.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.


---

## Parte 1 — O problema

No capítulo 0230, o cadastro de uma academia pedia a latitude e a longitude **digitadas**. Para testar, copiávamos as coordenadas do OpenStreetMap. Na praça, com o celular na mão, ninguém faz isso direito: são números de seis casas decimais, com sinal de menos.

O que queremos:

| Quem | Como marca o ponto |
| --- | --- |
| Quem está **na academia** | Toca em "Usar minha localização", e o GPS do celular faz o resto |
| Quem cadastra **de casa** | Toca no lugar certo do mapa |
| **Os dois** | Arrastam o pino para corrigir |

E, como sempre, sem JavaScript tudo continua funcionando: os campos de latitude e longitude ficam no formulário, para digitar.

---

## Parte 2 — As peças

| Peça | O que é |
| --- | --- |
| **Leaflet** | A biblioteca que desenha o mapa, o pino e os controles de zoom. Livre, leve e feita para celular |
| **OpenStreetMap** | As imagens do mapa, chamadas de **tiles** (azulejos). É um mapa do mundo feito por voluntários, como a Wikipédia |
| **Controller Stimulus `localizacao`** | Liga o mapa aos campos do formulário, nos dois sentidos |
| **Geolocation API** | O pedido de localização que a página faz ao navegador |

### 2.1 O que é um tile?

Pense num piso de azulejos. Em vez de uma pedra enorme, o chão é feito de quadradinhos iguais, e só se colocam os que cabem no cômodo.

Em termos técnicos, o mapa do mundo é dividido em **quadrados de 256×256 pixels**, os *tiles*, um conjunto para cada nível de zoom. O Leaflet só baixa os que aparecem na tela. Ao arrastar o mapa, ele busca os quadrados novos que entraram na tela. Por isso o mapa abre rápido, mesmo sendo o mapa do planeta inteiro.

### 2.2 As licenças

- **Leaflet:** licença **BSD-2**, que pede o aviso de copyright junto com o código. Ele já vem no topo dos arquivos.
- **OpenStreetMap:** os dados são livres, desde que se dê o **crédito** "© OpenStreetMap" visível no mapa. O Leaflet põe esse crédito no canto, com o `attribution`. Os servidores de tiles do OpenStreetMap são mantidos por doações e têm uma **política de uso**: servem bem um projeto como o nosso, mas não aguentariam um aplicativo com milhões de acessos. Se um dia o projeto crescer muito, será preciso um servidor de tiles próprio ou pago.

---

## Parte 3 — O Leaflet pelo importmap

### 3.1 O JavaScript

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/importmap pin leaflet
```

Pense numa estante de livros emprestados. O importmap anota na estante "o livro *leaflet* está na prateleira tal", e qualquer controller que pedir `import ... from "leaflet"` encontra.

Em termos técnicos, o comando baixa o Leaflet para `vendor/javascript/leaflet.js` e acrescenta ao `config/importmap.rb` a linha que liga o nome `leaflet` a esse arquivo. Não há `npm`, nem `node_modules`, nem etapa de compilação: o navegador carrega o arquivo direto. É o mesmo mecanismo que já carregava o Turbo e o Stimulus desde a criação do projeto.

### 3.2 O CSS

O Leaflet também precisa de um CSS, que o importmap não traz. Ele foi baixado da **mesma versão** do JavaScript:

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
curl -o app/assets/stylesheets/05-leaflet.css https://unpkg.com/leaflet@1.9.4/dist/leaflet.css
```

O número **05** faz ele carregar antes dos nossos arquivos (10, 15, 20...), que podem sobrescrever o que for preciso. É a mesma ordem alfabética do capítulo 0100.

> ⚠️ **A versão do CSS precisa ser a mesma do JavaScript.** Os dois foram feitos um para o outro. Quando o Leaflet for atualizado, os dois arquivos mudam juntos.

---

## Parte 4 — O formulário

No `app/views/academias/_form.html.erb`, os dois campos soltos de latitude e longitude viraram um grupo:

```erb
<fieldset class="campo" data-controller="localizacao">
  <legend>Localização</legend>

  <button type="button" class="botao-secundario" data-action="localizacao#localizar">
    <%= icone("map-pin") %> Usar minha localização
  </button>
  <p class="dica" data-localizacao-target="status" role="status">
    Ou toque no mapa para marcar o ponto. Depois, dá para arrastar o pino.
  </p>

  <div class="mapa-formulario" data-localizacao-target="mapa"></div>

  <div class="coordenadas">
    <div>
      <%= f.label :latitude %>
      <%= f.number_field :latitude, step: "any", required: true,
                         data: { localizacao_target: "latitude", action: "change->localizacao#digitou" } %>
    </div>
    <div>
      <%= f.label :longitude %>
      <%= f.number_field :longitude, step: "any", required: true,
                         data: { localizacao_target: "longitude", action: "change->localizacao#digitou" } %>
    </div>
  </div>
</fieldset>
```

| Trecho | O que faz |
| --- | --- |
| `data-controller="localizacao"` | Liga o controller ao grupo inteiro |
| `data-localizacao-target="..."` | Dá nome aos elementos que o controller usa: o mapa, os dois campos e a mensagem |
| `type="button"` | **Essencial.** Sem ele, um botão dentro de um formulário **envia** o formulário |
| `role="status"` | O leitor de tela anuncia as mensagens ("Localização encontrada...") sem interromper |
| `change->localizacao#digitou` | Quando alguém digita uma coordenada e sai do campo, o pino vai para lá |

### 4.1 O que é um *target*?

No capítulo 0210, o controller `validacao` não precisava de nomes: ele reagia a qualquer campo que mandasse um evento. Aqui, o controller precisa saber **qual** elemento é o mapa e **quais** são os campos de latitude e de longitude.

Pense nas etiquetas de um painel de disjuntores: "cozinha", "chuveiro", "quartos". Quem mexe no painel não precisa adivinhar qual é qual.

Em termos técnicos, o controller declara os nomes:

```js
static targets = [ "latitude", "longitude", "mapa", "status" ]
```

E o Stimulus cria, para cada um, uma propriedade: `this.mapaTarget`, `this.latitudeTarget`... que devolve o elemento com a etiqueta `data-localizacao-target="mapa"`, `"latitude"`... Nenhum `document.querySelector`, nenhum `id` inventado.

---

## Parte 5 — O controller

O arquivo completo está em `app/javascript/controllers/localizacao_controller.js`. Vamos por partes.

### 5.1 Montando o mapa

```js
import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

export default class extends Controller {
  static targets = [ "latitude", "longitude", "mapa", "status" ]

  // Centro de Ceilândia, para quando ainda não há ponto
  static values = { centro: { type: Array, default: [ -15.8166, -48.1060 ] } }

  connect() {
    const ponto = this.pontoDosCampos()

    this.mapa = L.map(this.mapaTarget).setView(ponto || this.centroValue, ponto ? 17 : 13)
    L.tileLayer("https://tile.openstreetmap.org/{z}/{x}/{y}.png", {
      maxZoom: 19,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
    }).addTo(this.mapa)

    if (ponto) this.colocarPino(ponto)

    // Tocar no mapa também posiciona o pino
    this.mapa.on("click", (evento) => this.moverPara(evento.latlng))
  }

  disconnect() {
    this.mapa?.remove()
  }
```

| Trecho | O que faz |
| --- | --- |
| `import * as L from "leaflet"` | O Leaflet não tem um "export padrão". O `* as L` junta tudo num objeto `L`, o nome que toda a documentação do Leaflet usa |
| `static values` | Um valor configurável do controller, com padrão. Daria para trocar o centro pelo HTML, com `data-localizacao-centro-value`, sem mexer no JavaScript |
| `L.map(...).setView(ponto, zoom)` | Cria o mapa dentro do elemento e define o centro e o zoom |
| `ponto ? 17 : 13` | Se a academia já tem coordenadas (na edição), abre bem perto (zoom 17). Se não, abre vendo a região inteira (zoom 13) |
| `{z}/{x}/{y}` | O endereço de cada tile: o zoom e a posição. O Leaflet preenche sozinho |
| `this.mapa.on("click", ...)` | Tocar no mapa move o pino para o ponto tocado |

**O `disconnect` é importante.** Quando o Turbo troca de página, o Stimulus desliga o controller. O `remove()` desmonta o mapa e libera a memória. Sem ele, cada visita ao formulário deixaria um mapa "fantasma" para trás.

### 5.2 Os dois sentidos: pino → campos e campos → pino

```js
moverPara(latlng) {
  this.colocarPino(latlng)
  this.preencherCampos(latlng)
}

preencherCampos(latlng) {
  this.latitudeTarget.value = latlng.lat.toFixed(6)
  this.longitudeTarget.value = latlng.lng.toFixed(6)
}

// Quando alguém digita nos campos, o pino acompanha
digitou() {
  const ponto = this.pontoDosCampos()
  if (!ponto) return

  this.colocarPino(ponto)
  this.mapa.setView(ponto)
}
```

O mapa e os campos mostram **a mesma informação** de dois jeitos. Mexeu num, o outro acompanha. O **`toFixed(6)`** arredonda para seis casas decimais, a mesma precisão da coluna no banco (capítulo 0230).

> 💡 Nos campos, a coordenada pode aparecer com vírgula (`-15,849140`). É o navegador mostrando o número no formato brasileiro. O valor enviado ao servidor continua com ponto.

### 5.3 O pino

```js
colocarPino(latlng) {
  if (this.pino) {
    this.pino.setLatLng(latlng)
    return
  }

  this.pino = L.marker(latlng, { draggable: true, icon: this.icone(), keyboard: true, title: "Local da academia" })
    .addTo(this.mapa)
  this.pino.on("dragend", () => this.preencherCampos(this.pino.getLatLng()))
}

// Pino feito em CSS: dispensa as imagens do Leaflet
icone() {
  return L.divIcon({ className: "pino", iconSize: [ 28, 28 ], iconAnchor: [ 14, 28 ] })
}
```

- **Um pino só.** Se ele já existe, só muda de lugar.
- **`draggable: true`** deixa arrastar, e o evento **`dragend`** avisa quando a pessoa solta o pino.
- **`iconAnchor: [14, 28]`** diz qual ponto do desenho fica **exatamente** sobre a coordenada: o meio da base, a "ponta" do pino.

**Por que um pino de CSS?** O pino padrão do Leaflet é uma imagem, que o CSS do Leaflet procura numa pasta `images/` ao lado dele. Com o importmap, essa pasta não existe, e o mapa apareceria com um ícone quebrado. O **`divIcon`** troca a imagem por um `<div>` com a classe `pino`, que desenhamos com CSS (Parte 7).

### 5.4 O GPS

```js
localizar() {
  if (!navigator.geolocation) {
    this.avisar("Este navegador não informa a localização. Toque no mapa para marcar o ponto.")
    return
  }

  this.avisar("Procurando a sua localização…")
  navigator.geolocation.getCurrentPosition(
    (posicao) => this.encontrou(posicao),
    (erro) => this.falhou(erro),
    { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 }
  )
}
```

Pense num motorista de aplicativo perguntando "posso usar a sua localização?" antes de ir buscar você. Só depois do "sim" ele sabe onde você está.

Em termos técnicos, o **`navigator.geolocation.getCurrentPosition`** pede a localização ao navegador. O navegador **pergunta à pessoa** se ela permite e, se ela aceitar, chama a primeira função com a posição. Se ela recusar, ou algo der errado, chama a segunda.

| Opção | O que pede |
| --- | --- |
| `enableHighAccuracy: true` | Usar o **GPS** de verdade, e não só a estimativa pela rede. Mais preciso, mas gasta mais bateria e demora um pouco mais |
| `timeout: 20000` | Desistir depois de 20 segundos |
| `maximumAge: 0` | Não aceitar uma posição guardada de antes: queremos onde a pessoa está **agora** |

**O pedido é assíncrono.** O GPS pode levar segundos para responder. Enquanto isso, a página continua funcionando, e a mensagem "Procurando a sua localização…" mostra que algo está acontecendo. Quando a resposta chega, o navegador chama a função `encontrou`.

### 5.5 A precisão

```js
encontrou(posicao) {
  const { latitude, longitude, accuracy } = posicao.coords
  this.moverPara(L.latLng(latitude, longitude))
  this.mapa.setView([ latitude, longitude ], 18)

  this.precisao?.remove()
  this.precisao = L.circle([ latitude, longitude ], { radius: accuracy, weight: 1 }).addTo(this.mapa)

  this.avisar(`Localização encontrada, com precisão de uns ${Math.round(accuracy)} m. Se precisar, arraste o pino até o lugar exato.`)
}
```

O GPS informa, junto com o ponto, a sua **margem de erro**, o `accuracy`, em metros. O círculo azul em volta do pino mostra essa margem. Perto de prédios ou debaixo de árvores, ela pode passar de 30 metros. A mensagem convida a pessoa a olhar o mapa e arrastar o pino, se for o caso: o GPS dá o ponto de partida, e o olho humano confirma.

O `const { latitude, longitude, accuracy } = posicao.coords` é a **desestruturação** do JavaScript: tira três propriedades de um objeto de uma vez, cada uma na sua variável.

### 5.6 Quando não dá certo

```js
falhou(erro) {
  const mensagens = {
    1: "Você não permitiu o uso da localização. Toque no mapa para marcar o ponto.",
    2: "Não foi possível descobrir a localização agora. Tente de novo ou toque no mapa.",
    3: "A localização demorou demais. Tente de novo, de preferência ao ar livre."
  }
  this.avisar(mensagens[erro.code] || "Não foi possível usar a localização.")
}
```

O navegador informa o motivo do erro por um número. Cada mensagem explica o que aconteceu **e** oferece uma saída: tocar no mapa. Nenhuma mensagem de erro deveria deixar a pessoa sem saber o que fazer.

---

## Parte 6 — O GPS só funciona em conexão segura

### 6.1 O que é um contexto seguro?

Pense num cofre que só abre com o segurança presente. Você pode até ter a combinação, mas, sem o segurança, a porta não abre.

Em termos técnicos, os navegadores só liberam recursos sensíveis, como a **localização**, a câmera e o microfone, em páginas carregadas de um **contexto seguro**: por **HTTPS**, ou pelo endereço **`localhost`**, que é o próprio computador. Uma página por HTTP comum poderia ter sido alterada no caminho, e entregar a localização de alguém a um site adulterado seria grave.

| Endereço | O GPS funciona? |
| --- | --- |
| `http://localhost:3000`, no computador | Sim: é o próprio computador |
| `http://192.168.0.7:3000`, no celular, pela rede de casa | **Não**: é HTTP comum. O navegador recusa sem nem perguntar |
| `https://` com um domínio, na VPS | Sim |

### 6.2 Testando no celular

Para abrir o site no celular, pela rede de casa, o servidor precisa aceitar conexões de outros aparelhos:

```bash
bin/dev -b 0.0.0.0
```

O **`-b 0.0.0.0`** (de *bind*) faz o servidor escutar em todas as interfaces de rede, e não só no próprio computador. No celular, na mesma rede Wi-Fi, abra `http://<ip-do-computador>:3000`. Para descobrir o IP: `hostname -I`.

Nessa situação, duas coisas **não** funcionam, e nenhuma delas é defeito do projeto:
- **O GPS**, pelo motivo da Parte 6.1. O mapa e o pino funcionam normalmente.
- **O login com o Google.** O Google não aceita que o login volte para um endereço de rede local, como `192.168.x.x`. Ele mostra *"device_id and device_name are required for private IP"*. Entre com e-mail e senha.

> 💡 **Quer testar o GPS de verdade no celular?** Dá para o celular acessar o computador como `localhost`, pelo cabo USB: no celular, ligue a **Depuração USB** nas Opções do desenvolvedor; no Chromium do computador, abra `chrome://inspect/#devices`, clique em **Port forwarding** e encaminhe a porta `3000` para `localhost:3000`. No celular, abra `http://localhost:3000`. De quebra, o `chrome://inspect` mostra o DevTools da página do celular no computador.

### 6.3 Simulando um GPS no computador

No computador, a localização vem da rede, e a precisão costuma ser ruim. Para testar com um ponto exato: no DevTools, **⋮ → More tools → Sensors → Location**, e escolha uma cidade ou digite uma coordenada. O "Usar minha localização" passa a receber esse ponto.

---

## Parte 7 — O CSS

No `15-formularios.css`:

```css
.mapa-formulario {
  height: 18rem;
  margin-block: var(--espaco-1);
  border: 2px solid var(--cor-roxo);
  border-radius: var(--raio);
}

.coordenadas {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--espaco-1);
}

/* O pino: uma gota laranja com borda roxa */
.pino {
  border: 3px solid var(--cor-roxo);
  border-radius: 50% 50% 50% 0;
  background: var(--cor-laranja);
  transform: rotate(-45deg);
}
```

- **O mapa precisa de altura.** Um `<div>` vazio tem altura zero, e o Leaflet desenharia um mapa invisível.
- **O pino:** um quadrado com três cantos redondos e um reto, girado 45°, vira a gota de um pino de mapa. Nenhuma imagem.
- **`.coordenadas`:** latitude e longitude lado a lado, em duas colunas iguais.

E a classe `.botao-secundario`, para o "Usar minha localização": contorno roxo e fundo branco, para não competir com o **Salvar**.

---

## Parte 8 — O teste

O mapa em si roda no navegador, e o teste de controller não executa JavaScript. Mas dá para garantir que **a estrutura** que o controller precisa está no formulário. No `academias_controller_test.rb`:

```ruby
test "o formulário de cadastro tem o mapa de localização" do
  sign_in users(:ana)
  get new_academia_url
  assert_select "[data-controller=localizacao] [data-localizacao-target=mapa]"
end
```

Se alguém mexer no formulário e apagar o `data-controller` ou o alvo do mapa sem querer, o mapa some sem erro nenhum na tela. Este teste avisa.

```bash
bin/rails test
```

---

## Parte 9 — Testando no navegador

Em **Cadastrar academia**:

1. O mapa aparece, centrado em Ceilândia.
2. **Toque no mapa:** o pino aparece, e os campos se preenchem.
3. **Arraste o pino:** os campos mudam.
4. **Digite uma coordenada** num campo e saia dele: o pino vai para lá.
5. **"Usar minha localização":** o navegador pede permissão. Simule um ponto pelo DevTools (Parte 6.3).
6. **Recuse a permissão:** aparece a mensagem pedindo para tocar no mapa.
7. **Edite uma academia que já existe:** o mapa abre no ponto dela, com zoom.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Desligar o JavaScript e cadastrar | Os campos de latitude e longitude continuam funcionando, para digitar |
| Navegar entre páginas e voltar ao formulário várias vezes | O mapa aparece uma vez só, sem duplicar (é o `disconnect`) |
| Clicar em "Usar minha localização" e, antes da resposta, tocar no mapa | O último a chegar define o ponto. Nada quebra |
| Digitar uma latitude de `120` | O pino não vai para lá de um jeito útil, e o model recusa ao salvar (capítulo 0230) |
| Abrir pelo celular em `http://192.168.x.x:3000` e pedir a localização | Aparecer a mensagem de erro, e o mapa continuar funcionando pelo toque |

---

## Enquanto isso: um avatar que sumiu

Durante esta etapa, aconteceu uma situação que vale registrar. A galeria de avatares foi atualizada, e um arquivo antigo de teste, o `avatar-00.svg`, saiu dela. Só que um usuário de desenvolvimento **ainda tinha esse avatar escolhido**, e a página dele parou de abrir: o Rails procurava uma imagem que não existia mais.

A tentação é colocar o arquivo de volta, ou escondê-lo com o `.gitignore`. Mas o problema não é o arquivo: é o **banco apontar para algo que pode sumir**. Toda vez que um avatar sair da galeria, a história se repetiria.

A correção, num PR próprio, ensinou a aplicação a sobreviver a isso. No `User`:

```ruby
# O avatar escolhido, só se o arquivo ainda estiver na galeria.
# Um avatar removido da galeria não pode quebrar a página de quem o tinha escolhido.
def avatar_exibivel
  avatar if avatar.present? && avatar.in?(self.class.avatares_disponiveis)
end
```

As views que **mostram** o avatar passaram a usar o `avatar_exibivel`. Se o arquivo sumiu, aparece o ícone padrão, e a pessoa escolhe outro na próxima visita ao perfil.

> 💡 **A lição vale para qualquer dado que aponta para fora do banco:** um arquivo, uma imagem, um endereço de outro site. O banco guarda só o nome, e o nome pode deixar de existir. O código que usa esse nome precisa ter um plano para quando isso acontecer.

E o mesmo episódio trouxe uma lição de **direitos de imagem**: um escudo de time de futebol não pode entrar na galeria, por ser marca registrada do clube. É o mesmo motivo que tirou o escudo da CBF dos avatares da equipe artística.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Leaflet** | Uma biblioteca livre de JavaScript para mapas interativos. |
| **OpenStreetMap** | Um mapa do mundo livre, feito por voluntários, como a Wikipédia. |
| **Tile** | Como um azulejo: um quadrado do mapa, baixado só quando aparece na tela. |
| **Importmap** | Como a anotação numa estante: liga o nome de uma biblioteca JavaScript ao arquivo dela, sem `npm`. |
| **Target** | Como a etiqueta de um disjuntor: o nome de um elemento que o controller Stimulus usa. |
| **Geolocation API** | O pedido de localização que a página faz ao navegador, com a permissão da pessoa. |
| **Assíncrono** | Algo que responde depois: a página continua funcionando enquanto espera. |
| **Contexto seguro** | Como o cofre que só abre com o segurança: HTTPS ou `localhost`, onde o navegador libera recursos sensíveis. |
| **Precisão** (*accuracy*) | A margem de erro do GPS, em metros. |
| **Desestruturação** | Tirar várias propriedades de um objeto de uma vez, cada uma na sua variável. |

---

## O que aprendemos

- Um mapa não precisa de servidor próprio: o Leaflet e o OpenStreetMap fazem o trabalho, com crédito a quem fez.
- O importmap carrega bibliotecas JavaScript sem `npm` e sem compilação.
- Os *targets* do Stimulus dão nome aos elementos que o controller usa.
- O mapa e os campos mostram a mesma informação: mexeu num, o outro acompanha.
- O GPS dá o ponto de partida, e o olho humano confirma.
- A localização só funciona em contexto seguro: HTTPS ou `localhost`.
- Toda mensagem de erro oferece uma saída.
- Dado que aponta para fora do banco precisa de um plano para quando o que ele aponta sumir.

**Próximo capítulo:** [0250 — Academias sem território](0250-academias-sem-territorio.md)

---

## Fontes

- [Leaflet — documentação](https://leafletjs.com/reference.html)
- [OpenStreetMap — direitos autorais e licença](https://www.openstreetmap.org/copyright)
- [OpenStreetMap — política de uso dos tiles](https://operations.osmfoundation.org/policies/tiles/)
- [Stimulus — Targets](https://stimulus.hotwired.dev/reference/targets)
- [Stimulus — Values](https://stimulus.hotwired.dev/reference/values)
- [MDN — Geolocation API](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation_API)
- [MDN — Contextos seguros](https://developer.mozilla.org/en-US/docs/Web/Security/Secure_Contexts)
- [importmap-rails](https://github.com/rails/importmap-rails)
