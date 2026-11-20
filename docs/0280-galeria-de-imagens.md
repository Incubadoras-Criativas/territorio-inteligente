# 0280 — A galeria de imagens

> **Neste capítulo:** cada pessoa ganha uma **galeria particular** de imagens. Ela sobe as fotos de campo uma vez, com o termo de consentimento, e vê as miniaturas, abre cada imagem e remove o que não quer mais. Ninguém mais vê essa galeria. Cada galeria tem um **limite de espaço**, que o admin pode aumentar pelo terminal. É o primeiro passo de uma mudança maior: nas próximas etapas, as fotos das academias, das observações e dos equipamentos vão ser **escolhidas da galeria**, e passar por moderação antes de aparecer para o público.

**Tag deste capítulo:** `cap-0280`

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

O `db:migrate` cria a tabela `imagens` e acrescenta aos usuários a coluna do limite da galeria.

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
> git switch -c estudo-0280 cap-0280
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
> git branch -D estudo-0280
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

## Parte 1 — Por que uma galeria?

Até aqui, a foto era escolhida **dentro** do formulário da academia, da observação ou do equipamento. Em campo, isso dava problema:

- o campo de arquivo do navegador é pequeno e confuso no celular;
- quando o formulário voltava com um erro (a data no futuro, por exemplo), **as fotos escolhidas se perdiam**, e era preciso escolher tudo de novo;
- escolher mais fotos depois **substituía** as primeiras, em vez de somar.

A solução é separar os dois momentos. Primeiro a pessoa **guarda** as fotos num lugar só dela. Depois, em outra etapa, ela **escolhe** da galeria o que quer anexar a cada registro.

Pense numa pasta de fotos reveladas. Você leva a pasta para a reunião e escolhe, ali, quais fotos vão para o mural. A foto que você não escolheu continua na sua pasta, e ninguém mais a vê.

As regras combinadas para a galeria:

| Regra | Como fica no código |
| --- | --- |
| A galeria é **particular**: só o dono vê | Toda busca parte de `current_user.imagens` |
| Cada galeria tem um **limite de espaço**: 100 MB por padrão | A coluna `limite_galeria_mb` no usuário e uma validação na imagem |
| O admin pode **aumentar o limite** de alguém | Um comando no terminal (Parte 9) |
| O **termo de consentimento** é aceito ao enviar | A mesma regra de aceite das observações, agora na imagem |
| Fotos anexadas a academias, observações e equipamentos passam por **moderação** | Nas próximas etapas |

---

## Parte 2 — "imagem" no plural

O Rails monta o plural em inglês: sem ajuda, `imagem` vira `imagems`. Já resolvemos isso com academia, categoria e observação. A regra entra no `config/initializers/inflections.rb` **antes** de gerar qualquer coisa:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  inflect.irregular "imagem", "imagens"
```

Dá para conferir antes de gerar:

```bash
# 📖 JÁ ESTÁ NO PROJETO
bin/rails runner 'puts "imagem".pluralize, "imagens".singularize'
```

A resposta precisa ser `imagens` e `imagem`. Se a regra faltar, o gerador cria a tabela `imagems`, o model procura uma tabela com outro nome, e consertar depois dá trabalho.

---

## Parte 3 — O model `Imagem`

### 3.1 As migrations

```bash
# 📖 JÁ ESTÁ NO PROJETO
bin/rails generate model Imagem user:references termo_aceito_em:datetime
bin/rails generate migration AddLimiteGaleriaMbToUsers limite_galeria_mb:integer
```

Na segunda, a coluna ganhou um valor padrão e não aceita vazio:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
    add_column :users, :limite_galeria_mb, :integer, null: false, default: 100
```

O `default: 100` vale também para quem **já tinha conta**: ao criar a coluna, o PostgreSQL preenche as linhas que já existem com o valor padrão.

> ⚠️ **Atenção às fixtures geradas.** O `generate model` cria também o arquivo `test/fixtures/imagens.yml`, com exemplos que apontam para usuários chamados `one` e `two`. Esses usuários não existem nas nossas fixtures, que se chamam `ana`, `admin` e `bia`. Antes de cada teste, o Rails carrega **todas** as fixtures e confere as chaves estrangeiras, e então **todos os testes falham**, até os que não têm nada a ver com imagens.
>
> Como os nossos testes criam as imagens na hora, o arquivo foi apagado. Depois de qualquer `generate model`, confira a fixture gerada: ou ajuste os nomes, ou apague o arquivo.
>
> Se os testes já tiverem rodado com a fixture errada, as linhas dela podem ter ficado gravadas no banco de teste. Nesse caso, depois de apagar o arquivo, recrie o banco de teste:
>
> ```bash
> bin/rails db:test:prepare
> ```
>
> O banco de teste é descartável: o `db:test:prepare` o apaga e o refaz com a estrutura atual, sem tocar no banco de desenvolvimento.

### 3.2 O model

`app/models/imagem.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Uma imagem da galeria pessoal. Só o dono vê.
class Imagem < ApplicationRecord
  include ValidaImagens

  belongs_to :user

  has_one_attached :arquivo do |anexo|
    anexo.variant :miniatura, resize_to_limit: [ 160, 160 ], format: :webp
    anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
  end

  attribute :termo_fotos, :boolean

  scope :recentes, -> { order(created_at: :desc) }

  valida_imagens :arquivo
  validates :termo_fotos, acceptance: { allow_nil: false, message: "precisa ser aceito para enviar fotos" }, on: :create
  validate :arquivo_presente
  validate :cabe_na_galeria, on: :create

  before_create { self.termo_aceito_em = Time.current }

  private

  def arquivo_presente
    errors.add(:arquivo, :blank) unless arquivo.attached?
  end

  def cabe_na_galeria
    return unless arquivo.attached? && user

    return if user.espaco_usado + arquivo.blob.byte_size <= user.limite_galeria_bytes

    errors.add(:arquivo, "não cabe na sua galeria (limite de #{user.limite_galeria_mb} MB)")
  end
end
```

Quase tudo aqui já apareceu antes:

| Linha | Onde já vimos |
| --- | --- |
| `include ValidaImagens` e `valida_imagens :arquivo` | O concern do capítulo 0260: só JPG, PNG ou WebP, até 10 MB |
| `has_one_attached` com variantes | A capa dos equipamentos, no capítulo 0220 |
| `attribute :termo_fotos` e `acceptance` com `allow_nil: false` | O termo das observações, no capítulo 0260 |

E duas coisas novas:

- **`arquivo_presente`**: o Rails não tem um `presence` pronto para anexos. A checagem é feita à mão, perguntando ao anexo se ele existe (`attached?`).
- **`cabe_na_galeria`**: soma o espaço que a pessoa já usa com o tamanho da imagem nova, e recusa se passar do limite. Como a validação roda **antes** de gravar, a imagem nova ainda não está no banco e não é contada duas vezes.

### 3.3 O usuário e o espaço usado

Em `app/models/user.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  has_many :imagens, dependent: :destroy

  def limite_galeria_bytes = limite_galeria_mb.megabytes

  def espaco_usado
    imagens.joins(:arquivo_blob).sum("active_storage_blobs.byte_size")
  end
```

- **`dependent: :destroy`**: se a conta for apagada, as imagens vão junto, e cada uma apaga o seu arquivo do disco. É o direito de exclusão da LGPD funcionando sem nenhum código a mais.
- **`megabytes`**: o Rails sabe converter números. `100.megabytes` é `104857600`.
- **`joins(:arquivo_blob)`**: o `has_one_attached :arquivo` cria, por baixo, duas associações: `arquivo_attachment` e `arquivo_blob`. O tamanho do arquivo mora no *blob*, na coluna `byte_size`. O `sum` faz a conta **dentro do banco**, numa consulta só, sem carregar nenhuma imagem na memória.

> **O que é um blob?** Pense no protocolo de um documento num cartório. O documento fica no arquivo, e a ficha do protocolo guarda o nome, o tamanho e onde ele está guardado. No Active Storage, o arquivo fica no disco (em `storage/`), e o **blob** é a ficha: uma linha na tabela `active_storage_blobs`, com o nome, o tipo, o tamanho em bytes e a chave para encontrar o arquivo.

---

## Parte 4 — A rota e o controller

### 4.1 A rota

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  resources :imagens, only: %i[index show create destroy], path: "galeria"
```

O `path: "galeria"` muda só o endereço, que fica `/galeria`. Os helpers continuam com o nome do recurso: `imagens_path` e `imagem_path(imagem)`.

Não há `new` nem `edit`. O formulário de envio fica na própria lista, e uma imagem não se edita: ou ela fica, ou é removida.

### 4.2 O controller

`app/controllers/imagens_controller.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# A galeria pessoal: cada pessoa só vê e só mexe nas próprias imagens.
class ImagensController < ApplicationController
  before_action :authenticate_user!

  def index
    @imagens = current_user.imagens.recentes.with_attached_arquivo
    @espaco_usado = current_user.espaco_usado
  end

  def show
    @imagem = current_user.imagens.find(params[:id])
  end

  # Aceita várias imagens de uma vez: cada arquivo vira uma Imagem.
  def create
    envio = params.expect(imagem: [ :termo_fotos, arquivos: [] ])
    arquivos = Array(envio[:arquivos]).compact_blank

    if arquivos.empty?
      redirect_to imagens_path, alert: "Escolha pelo menos uma imagem.", status: :see_other
      return
    end

    imagens = arquivos.map do |arquivo|
      current_user.imagens.create(arquivo: arquivo, termo_fotos: envio[:termo_fotos])
    end
    recusadas = imagens.reject(&:persisted?)

    if recusadas.empty?
      redirect_to imagens_path, notice: "#{imagens.size} imagem(ns) enviada(s) para a sua galeria.", status: :see_other
    else
      erros = recusadas.flat_map { |imagem| imagem.errors.full_messages }.uniq.to_sentence
      redirect_to imagens_path, alert: "#{imagens.size - recusadas.size} de #{imagens.size} enviada(s). #{erros}", status: :see_other
    end
  end

  def destroy
    current_user.imagens.find(params[:id]).destroy
    redirect_to imagens_path, notice: "Imagem removida.", status: :see_other
  end
end
```

**A privacidade está numa expressão: `current_user.imagens.find`.** O `find` procura o id **só entre as imagens da pessoa logada**. Se alguém trocar o número na URL para tentar abrir ou apagar a imagem de outra pessoa, o `find` não encontra nada, e a resposta é um 404, como se a imagem não existisse. É o mesmo princípio do `permitidas_para` das academias: a regra de acesso fica **na consulta**, e não num `if` que alguém pode esquecer.

Sobre o `create`:

- **Uma `Imagem` por arquivo.** Se a pessoa envia 5 fotos e a quinta não cabe no limite, as 4 primeiras ficam salvas, e a mensagem diz isso: *"4 de 5 enviada(s). Arquivo não cabe na sua galeria…"*.
- **`create`, e não `create!`**: o `create` devolve o objeto mesmo quando a validação falha, sem levantar exceção. Assim, dá para separar as aceitas (`persisted?`) das recusadas.
- **`compact_blank`**: o campo de arquivo múltiplo envia um item vazio quando nada foi escolhido. O `compact_blank` tira os vazios da lista.
- **`to_sentence`**: junta uma lista em português corrido, como "a, b e c".

---

## Parte 5 — O termo num arquivo de texto

O texto do termo fica em `config/locales/termos.pt-BR.yml`:

```yaml
# 📖 JÁ ESTÁ NO PROJETO
pt-BR:
  termos:
    fotos: >-
      Declaro que tirei estas fotos ou tenho autorização para usá-las,
      que elas não mostram o rosto de pessoas que não autorizaram,
      e concordo que, ao anexá-las a uma academia ou observação,
      elas sejam publicadas sob a licença CC BY-SA 4.0.
```

E a view usa `t("termos.fotos")`. Por que num arquivo de locale, e não escrito direto na view?

- **Um texto, vários lugares.** O mesmo termo vai aparecer na galeria e, depois, em outros formulários. Com o texto num lugar só, nunca existem duas versões diferentes do termo.
- **Fácil de mudar.** Quem for ajustar o texto mexe num arquivo de texto, sem procurar no meio do HTML.
- O **`>-`** do YAML junta as linhas num parágrafo só. O texto fica legível no arquivo, sem virar uma linha gigante.

> Em produção, o Rails lê os arquivos de locale **quando sobe**. Depois de mudar o texto do termo no servidor, é preciso reiniciar a aplicação. No desenvolvimento, a mudança aparece na hora.

---

## Parte 6 — A página da galeria

### 6.1 O espaço usado

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<p class="uso-galeria">
  <label for="uso-galeria">
    <%= number_to_human_size(@espaco_usado) %> de <%= current_user.limite_galeria_mb %> MB usados
  </label>
  <meter id="uso-galeria" min="0" max="<%= current_user.limite_galeria_bytes %>"
         value="<%= @espaco_usado %>" high="<%= (current_user.limite_galeria_bytes * 0.9).to_i %>"></meter>
</p>
```

- **`number_to_human_size`**: transforma `389120` em "380 KB".
- **`<meter>`**: o marcador de combustível do HTML, para valores dentro de uma faixa conhecida. O atributo `high` marca a "reserva": quando passa de 90%, o navegador pinta a barra de outra cor. Não precisa de JavaScript.

### 6.2 Um botão no lugar do campo de arquivo

O campo de arquivo do navegador (o "Escolher arquivos / Nenhum arquivo escolhido") é difícil de usar no celular. Na galeria, ele dá lugar a um único botão, **Adicionar fotos**: a pessoa escolhe as fotos, e elas sobem sozinhas.

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<%= form_with url: imagens_path, scope: :imagem, class: "envio-galeria",
              data: { controller: "envio-automatico" } do |f| %>
  <div class="campo">
    <%= f.check_box :termo_fotos, required: true %>
    <%= f.label :termo_fotos, t("termos.fotos") %>
  </div>

  <div class="campo">
    <%= f.file_field :arquivos, multiple: true, accept: "image/jpeg,image/png,image/webp",
                     class: "visualmente-oculto",
                     data: { action: "change->envio-automatico#enviar", tamanho_maximo: Imagem::TAMANHO_MAXIMO } %>
    <%= f.label :arquivos, class: "botao botao-enviar" do %>
      <span class="quando-parado">Adicionar fotos</span>
      <span class="quando-enviando">Enviando…</span>
    <% end %>
    <p class="dica">JPG, PNG ou WebP, até 10 MB cada. Pode escolher várias de uma vez.</p>
  </div>
<% end %>
```

São três ideias juntas:

**1. O botão é um `<label>`.** No HTML, clicar no `<label>` de um campo é o mesmo que clicar no campo. No caso de um campo de arquivo, isso **abre a janela de escolha**, sem nenhuma linha de JavaScript. O `<label>` só precisa da aparência de botão, dada pela classe `.botao`.

**2. O campo continua lá, só que invisível.** A classe `.visualmente-oculto` esconde o campo da vista, mas não do teclado nem do leitor de tela. Com `display: none`, quem navega com a tecla Tab não conseguiria mais escolher fotos, porque o campo sairia da navegação.

**3. Escolheu, enviou.** O único JavaScript da página é o controller Stimulus `envio-automatico`, ligado ao evento `change` do campo:

```js
// 📖 JÁ ESTÁ NO PROJETO
// app/javascript/controllers/envio_automatico_controller.js
import { Controller } from "@hotwired/stimulus"

// Envia o formulário assim que a pessoa escolhe os arquivos
export default class extends Controller {
  enviar() {
    this.element.requestSubmit()
  }
}
```

O **`requestSubmit()`** envia o formulário **como se a pessoa tivesse clicado num botão de envio**: ele dispara o evento `submit`. Por isso, o controller `validacao` do capítulo 0210 confere o termo e o tamanho dos arquivos, e o Turbo cuida do envio. O `submit()`, mais antigo, pularia as duas coisas.

Como o envio é automático, **o termo vem primeiro**. Enquanto ele não estiver marcado, o botão fica apagado (ver o CSS na Parte 7). O `required` na caixa garante a mensagem de erro para quem usa o teclado, e o servidor continua validando o aceite, como última garantia.

### 6.3 "Enviando…"

Fotos de celular demoram alguns segundos para subir. Sem nenhum aviso, a pessoa acha que travou e toca de novo. Durante o envio, o Turbo marca o formulário com `aria-busy="true"`, e o CSS usa essa marca para trocar o texto do botão de "Adicionar fotos" para "Enviando…". Não precisa de JavaScript.

### 6.4 As miniaturas

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<% if @imagens.any? %>
  <ul class="galeria" role="list">
    <% @imagens.each do |imagem| %>
      <li>
        <%= link_to imagem_path(imagem), class: "abrir-imagem" do %>
          <%= image_tag imagem.arquivo.variant(:miniatura),
                        alt: "Imagem enviada em #{l imagem.created_at, format: :short}" %>
        <% end %>
        <%= button_to imagem_path(imagem), method: :delete, class: "remover-imagem",
                      aria: { label: "Remover imagem" },
                      form: { data: { turbo_confirm: "Remover esta imagem da sua galeria?" } } do %>
          <%= icone("trash") %>
        <% end %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>Sua galeria está vazia.</p>
<% end %>
```

- **A miniatura é um link** para a página da imagem. Todo link precisa de um nome para o leitor de tela. Como aqui o link só tem a imagem, o nome vem do `alt`: "Imagem enviada em 16 nov 17:03".
- **O `button_to` com bloco**: o conteúdo do bloco vira o conteúdo do botão, que aqui é só o ícone da lixeira. Pela mesma razão do link, o botão leva um **`aria-label`**. Sem ele, o leitor de tela anunciaria apenas "botão".
- **`turbo_confirm`**: a pergunta de confirmação antes de remover.

### 6.5 A página da imagem

A página da imagem (`show`) mostra a variante **`:media`**, de até 800px, e um link para o arquivo original:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<% content_for :title, "Imagem da galeria" %>

<p><%= link_to "← Minha galeria", imagens_path %></p>

<figure class="imagem-grande">
  <%= image_tag @imagem.arquivo.variant(:media), alt: "Imagem enviada em #{l @imagem.created_at, format: :short}" %>
  <figcaption>
    Enviada em <%= l @imagem.created_at, format: :short %> ·
    <%= number_to_human_size(@imagem.arquivo.byte_size) %>
  </figcaption>
</figure>

<p><%= link_to "Abrir original", rails_blob_path(@imagem.arquivo), target: "_blank" %></p>

<%= button_to "Remover da galeria", imagem_path(@imagem), method: :delete,
              form: { data: { turbo_confirm: "Remover esta imagem da sua galeria?" } } %>
```

Por que não mostrar o original direto? Uma foto de celular tem uns 4000 pixels de largura e de 3 a 5 MB. A tela do celular tem uns 400. Em campo, usando dados móveis, baixar o original só para ver a foto gasta dados à toa. Os 800px ficam nítidos na tela, e quem quiser o arquivo completo toca em "Abrir original".

> **Sobre o link do original.** O `rails_blob_path` gera um endereço assinado, impossível de adivinhar. Mas quem **recebe** esse endereço consegue abrir a imagem, mesmo sem login. Para uma galeria pessoal, isso é aceitável: a pessoa só compartilharia o link de propósito.

---

## Parte 7 — O CSS

### 7.1 Um `<label>` com cara de botão

Em `10-base.css`, a classe `.botao` entrou na **mesma regra** dos botões do projeto, para herdar exatamente a mesma aparência:

```css
/* 📖 JÁ ESTÁ NO PROJETO */
button,
input[type="submit"],
.botao {
  /* ...a aparência dos botões do projeto... */
}

/* Um label ou link com cara de botão */
.botao {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  user-select: none;
  text-decoration: none;
}
```

A segunda regra dá ao `<label>` o que um `<button>` já traz de fábrica:

| Linha | Por quê |
| --- | --- |
| `display: inline-flex` | O `<label>` é *inline*, como uma palavra, e não aceita bem altura e espaçamento interno. O `inline-flex` faz ele se comportar como uma caixa |
| `cursor: pointer` | O `<button>` já mostra a mãozinha; o `<label>`, não |
| `user-select: none` | Evita que um toque demorado no celular selecione o texto do botão |
| `text-decoration: none` | Para quando a `.botao` for usada num link |

### 7.2 A galeria: `50-galeria.css`

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* 50-galeria.css — Galeria pessoal de imagens */

.galeria {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
  gap: var(--espaco-1);
  padding: 0;
}

.galeria li {
  position: relative;
}

.galeria img {
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: var(--raio);
}

.abrir-imagem {
  display: block;
}

/* A lixeira: um círculo branco no canto superior direito */
.remover-imagem {
  position: absolute;
  top: 4px;
  right: 4px;
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: rgb(255 255 255 / 0.9);
  color: var(--cor-erro);
  box-shadow: 0 1px 3px rgb(0 0 0 / 0.3);
}

.remover-imagem:hover {
  background: var(--cor-branco);
}

.remover-imagem .icone {
  width: 1.25rem;
  height: 1.25rem;
}

.uso-galeria meter {
  display: block;
  width: 100%;
}

/* O campo do envio: botão em cima, dica embaixo, com respiro */
.campo:has(.botao-enviar) {
  display: grid;
  gap: var(--espaco-1);
  justify-items: start;
}

/* O botão fica apagado enquanto o termo não estiver marcado */
.envio-galeria:has(input[type="checkbox"]:not(:checked)) .botao-enviar {
  opacity: 0.5;
  pointer-events: none;
}

/* Contorno de foco no botão quando o campo oculto recebe o Tab */
.visualmente-oculto:focus-visible + .botao {
  outline: 3px solid var(--cor-amarelo);
  outline-offset: 2px;
}

/* Durante o envio: troca o texto e impede um segundo clique */
.botao-enviar .quando-enviando,
.envio-galeria[aria-busy="true"] .botao-enviar .quando-parado {
  display: none;
}

.envio-galeria[aria-busy="true"] .botao-enviar .quando-enviando {
  display: inline;
}

.envio-galeria[aria-busy="true"] .botao-enviar {
  pointer-events: none;
}

.imagem-grande {
  display: grid;
  gap: var(--espaco-1);
  margin: 0;
}

.imagem-grande img {
  width: 100%;
  height: auto;
  border-radius: var(--raio);
}

.imagem-grande figcaption {
  font-size: 0.875rem;
}
```

Os pontos novos:

- **`repeat(auto-fill, minmax(100px, 1fr))`**: cabem quantas colunas der, cada uma com pelo menos 100px. No celular ficam três; no computador, mais. Não precisa de `@media`.
- **`aspect-ratio: 1` com `object-fit: cover`**: todas as miniaturas ficam quadradas e alinhadas, com fotos em pé ou deitadas. A foto é recortada para preencher o quadrado, sem ficar distorcida.
- **`position: relative` no `<li>` e `position: absolute` na lixeira**: o `<li>` vira a moldura de referência, e a lixeira fica presa no canto dessa moldura. O círculo branco semitransparente faz a lixeira vermelha aparecer sobre qualquer foto, clara ou escura.
- **`:has()`**: o seletor "pai". `.envio-galeria:has(input[type="checkbox"]:not(:checked))` quer dizer "o formulário que **tem** uma caixa de seleção não marcada". Com ele, o CSS reage ao estado do formulário sem JavaScript. É como um `where` que olha para os filhos.
- **`pointer-events: none`**: o elemento deixa de receber cliques e toques. É o que impede abrir a janela de escolha antes do termo, e tocar duas vezes durante o envio.
- **`+`**: "o elemento logo depois". Por isso, no HTML, o campo de arquivo vem **antes** do `<label>`: quando o campo recebe o foco, o `<label>` logo depois dele ganha o contorno.
- **`.campo:has(.botao-enviar)`**: a regra do espaço vale só para o campo que contém o botão. Se valesse para todo `.campo`, a caixa do termo e o texto dela iriam para linhas separadas.

---

## Parte 8 — Os testes

### 8.1 O model: `test/models/imagem_test.rb`

```ruby
# 📖 JÁ ESTÁ NO PROJETO
require "test_helper"

class ImagemTest < ActiveSupport::TestCase
  setup do
    @user = users(:ana)
  end

  def arquivo
    { io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg" }
  end

  test "envia uma imagem para a galeria e grava a data do termo" do
    imagem = @user.imagens.create!(arquivo: arquivo, termo_fotos: true)

    assert_not_nil imagem.termo_aceito_em
    assert @user.espaco_usado.positive?
  end

  test "exige o aceite do termo" do
    imagem = @user.imagens.new(arquivo: arquivo)

    assert_not imagem.valid?
    assert imagem.errors.of_kind?(:termo_fotos, :accepted)
  end

  test "exige um arquivo" do
    imagem = @user.imagens.new(termo_fotos: true)

    assert_not imagem.valid?
    assert imagem.errors.of_kind?(:arquivo, :blank)
  end

  test "recusa a imagem quando a galeria está cheia" do
    @user.update!(limite_galeria_mb: 0)
    imagem = @user.imagens.new(arquivo: arquivo, termo_fotos: true)

    assert_not imagem.valid?
    assert_includes imagem.errors[:arquivo].join, "não cabe na sua galeria"
  end
end
```

- **`file_fixture("foto.jpg")`**: a imagem de teste que está em `test/fixtures/files/` desde o capítulo 0220.
- **`errors.of_kind?`**: confere o **tipo** do erro, e não o texto. Se a mensagem mudar um dia, o teste continua valendo.
- **O limite zerado**: para testar "galeria cheia", não precisamos de 100 MB de imagens. Basta baixar o limite para zero.

### 8.2 O controller: `test/controllers/imagens_controller_test.rb`

| Teste | O que garante |
| --- | --- |
| Visitante não acessa a galeria | O `authenticate_user!` |
| Envia duas imagens de uma vez para a própria galeria | O envio múltiplo: uma `Imagem` por arquivo |
| Não envia sem aceitar o termo | O consentimento |
| Não vê a imagem de outra pessoa | **A galeria é privada**: 404 |
| Não remove a imagem de outra pessoa | **A galeria é privada**: 404, e nada é apagado |

Os dois últimos são os mais importantes do capítulo. Eles **provam** a regra principal: a galeria é particular.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 9 — Para quem administra o servidor

### 9.1 Aumentar o limite de alguém

O limite padrão é de 100 MB por pessoa. Para dar mais espaço a alguém, sem mexer no código, rode no servidor, como o usuário da aplicação:

```bash
RAILS_ENV=production mise exec -- bin/rails runner 'User.find_by!(login: "fulano").update!(limite_galeria_mb: 200)'
```

- **`runner`**: roda uma linha de Ruby com a aplicação carregada, como um `rails console` de uma linha só.
- **`find_by!`**, com exclamação: se o login não existir, o comando para com um erro claro, em vez de seguir sem fazer nada.
- Troque `fulano` pelo login da pessoa e `200` pelo novo limite em MB.

### 9.2 O tamanho máximo de um envio

O formulário envia todas as fotos escolhidas **num pedido só**. No servidor, o Nginx tem um limite para o tamanho de cada pedido, no `client_max_body_size` da configuração do site. Com fotos de celular de 7 MB, 8 fotos de uma vez já passam de 50 MB. Por isso, o limite foi ajustado para 100 MB:

```nginx
client_max_body_size 100m;
```

Se uma pessoa escolher fotos demais de uma vez e o envio passar desse limite, o Nginx recusa o pedido com o erro **413**, antes até de ele chegar ao Rails.

---

## Parte 10 — Testando no navegador

Entre como comum e abra **Menu → Minha galeria**:

1. **Com o termo desmarcado**, o botão "Adicionar fotos" fica apagado e não abre a janela de escolha.
2. **Marque o termo e escolha 3 fotos.** Aparece "Enviando…", e depois as três miniaturas, a mensagem verde e a barra de uso.
3. **Toque numa miniatura.** Abre a página da imagem, com a data e o tamanho. Toque em "Abrir original".
4. **Remova uma imagem pela lixeira** e outra pela página da imagem. As duas pedem confirmação.
5. **Pelo teclado:** vá com Tab até o botão. O contorno amarelo aparece, e Enter ou espaço abrem a janela de escolha.
6. **No celular emulado do DevTools**, ou no seu celular, o botão oferece a câmera ou as fotos do aparelho.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Abrir `/galeria` sem estar logado | Mandar para a tela de entrada |
| Abrir `/galeria/<id>` de uma imagem de outra pessoa | Dar 404 |
| Remover o `required` do termo pelo DevTools e enviar | Recusar no servidor: o termo continua obrigatório |
| Enviar um PDF renomeado para `.jpg` | Recusar: o `ValidaImagens` confere o tipo real do arquivo |
| Enviar uma foto com mais de 10 MB | Recusar |
| Pelo terminal, baixar o seu limite para `0` e tentar enviar | Recusar com "não cabe na sua galeria" |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Galeria** | Como uma pasta de fotos reveladas: um lugar particular onde as fotos ficam guardadas até serem escolhidas para um registro. |
| **Blob** | Como a ficha de protocolo de um documento: a linha do Active Storage que guarda o nome, o tipo, o tamanho e o endereço do arquivo no disco. |
| **`byte_size`** | O tamanho do arquivo em bytes, guardado no blob. |
| **`number_to_human_size`** | O helper que transforma bytes em "380 KB" ou "2,4 MB". |
| **`<meter>`** | O marcador de combustível do HTML: mostra um valor dentro de uma faixa conhecida. |
| **`requestSubmit()`** | Envia o formulário como se alguém tivesse clicado num botão de envio, passando pelas validações. |
| **`aria-busy`** | A marca que o Turbo põe no formulário enquanto ele está sendo enviado. |
| **`:has()`** | O seletor "pai" do CSS: escolhe um elemento pelo que ele tem dentro. |
| **`pointer-events: none`** | Faz o elemento deixar de receber cliques e toques. |
| **`aria-label`** | O nome de um elemento para o leitor de tela, quando ele não tem texto visível. |
| **Erro 413** | A resposta do servidor quando o pedido é grande demais. |

---

## O que aprendemos

- Separar "guardar" de "escolher" torna o envio de fotos mais simples, e as fotos não se perdem quando um formulário dá erro.
- A regra de acesso mora na consulta: `current_user.imagens.find` é a privacidade da galeria inteira.
- Um teste que prova o 404 para a imagem alheia vale mais do que qualquer promessa de privacidade.
- Um limite que o servidor confere protege o disco de todos.
- Um texto que aparece em vários lugares mora num arquivo só.
- O HTML já faz muito sozinho: o `<label>` abre a janela de escolha, e o `<meter>` mostra o uso. O JavaScript fica só com o que o HTML não faz.
- Esconder da vista não é o mesmo que esconder do teclado: `visualmente-oculto`, e não `display: none`.
- Depois de um `generate model`, confira a fixture gerada.

**Próximo capítulo:** [0290 — Fotos escolhidas da galeria](0290-fotos-da-galeria.md)

---

## Fontes

- [Rails Guides — Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)
- [Rails API — `ActiveSupport::Inflector::Inflections`](https://api.rubyonrails.org/classes/ActiveSupport/Inflector/Inflections.html)
- [Rails Guides — Internationalization (I18n)](https://guides.rubyonrails.org/i18n.html)
- [Rails API — `number_to_human_size`](https://api.rubyonrails.org/classes/ActionView/Helpers/NumberHelper.html#method-i-number_to_human_size)
- [MDN — `<meter>`](https://developer.mozilla.org/pt-BR/docs/Web/HTML/Element/meter)
- [MDN — `HTMLFormElement.requestSubmit()`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLFormElement/requestSubmit)
- [MDN — `:has()`](https://developer.mozilla.org/pt-BR/docs/Web/CSS/:has)
- [MDN — `aria-busy`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-busy)
- [Turbo Handbook — Drive: form submissions](https://turbo.hotwired.dev/handbook/drive#form-submissions)
- [Nginx — `client_max_body_size`](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size)
