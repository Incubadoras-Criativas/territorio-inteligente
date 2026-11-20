# 0300 — A moderação

> **Neste capítulo:** as fotos pendentes, as academias e as observações em rascunho ganham **uma página só**, onde moderadores e admin decidem: aprovar ou recusar a foto, publicar a academia ou a observação. Cada decisão tira o item da lista **sem recarregar a página**, com o **Turbo Stream**. A foto recusada não é apagada: só o autor a vê, com a etiqueta "Recusada". E quem modera passa a ver, no menu, **quantos itens esperam** por uma decisão.

**Tag deste capítulo:** `cap-0300`

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
> git switch -c estudo-0300 cap-0300
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
> git branch -D estudo-0300
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

## Parte 1 — O que espera decisão

Desde o capítulo 0230, as academias cadastradas por quem não modera nascem como **rascunho**. Desde o 0260, as observações também. E desde o 0290, as fotos anexadas entram **pendentes**. Três filas, e nenhum lugar para vê-las juntas: o moderador precisava passear pela lista de academias para descobrir o que esperava por ele.

Este capítulo cria esse lugar. É como a bandeja de "entrada" em cima da mesa de quem revisa os documentos: tudo o que chega para aprovação cai ali, do mais antigo para o mais novo, e cada item sai da bandeja quando recebe uma decisão.

As regras combinadas:

| Regra | Como fica no código |
| --- | --- |
| A página **Moderação** é só para moderadores e admin | `Moderacao::BaseController` |
| Uma foto pendente pode ser **aprovada** ou **recusada** | `Foto#aprovar!` e `Foto#recusar!`, com quem moderou e quando |
| A foto **recusada** continua existindo, visível **só para o autor**, com a etiqueta "Recusada"; ele pode removê-la | O `fotos_visiveis_para` e o `removivel_por?` |
| Academias e observações em rascunho aparecem na mesma página, com o botão **Publicar** | `Moderavel#publicar` |
| Ao decidir, o item **some da lista sem recarregar** a página | Turbo Stream |
| Quem modera vê **quantos itens** esperam: um número no menu e um pontinho na aba | `Moderacao::Pendencias` |

---

## Parte 2 — O model: aprovar, recusar, publicar

### 2.1 As fotos

No `app/models/foto.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  def aprovar!(por:) = moderar!(:aprovada, por)
  def recusar!(por:) = moderar!(:recusada, por)

  # Quem modera remove sempre; o autor, enquanto a foto não foi aprovada
  def removivel_por?(user)
    return false unless user

    user.pode_moderar? || (autor_id == user.id && !aprovada?)
  end

  private

  def moderar!(situacao, por)
    update!(situacao: situacao, moderador: por, moderado_em: Time.current)
  end
```

- **`aprovar!` e `recusar!` numa linha**: o `def nome = expressão` é o "método de uma linha" do Ruby moderno. Os dois fazem a mesma coisa com valores diferentes, e a operação de verdade mora num método só, o `moderar!`.
- **A moderação deixa rastro**: quem moderou (`moderador`) e quando (`moderado_em`). Se um dia alguém perguntar por que uma foto saiu do ar, a resposta está no banco.
- **`!aprovada?`**: o autor pode remover a foto pendente **ou recusada**. Depois de aprovada, ela passou pela curadoria, e só quem modera a retira.

### 2.2 Uma etiqueta para cada situação

Agora há duas etiquetas possíveis, e elas aparecem em três lugares: no seletor das fotos, na ficha da academia e nas observações. Então elas ganharam um partial, `app/views/fotos/_etiqueta.html.erb`:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<% if foto.pendente? %>
  <span class="etiqueta-rascunho">Aguardando moderação</span>
<% elsif foto.recusada? %>
  <span class="etiqueta-recusada">Recusada</span>
<% end %>
```

Nos três lugares, uma linha:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<%= render "fotos/etiqueta", foto: foto %>
```

A foto aprovada não ganha etiqueta: ela é o estado normal.

### 2.3 Academias e observações: o concern `Moderavel`

Publicar uma academia ou uma observação é a mesma operação: mudar o `visivel` para `true`. As duas já compartilham o concern `Moderavel`, do capítulo 0260, e a regra nova foi para lá:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  included do
    # ...
    scope :rascunhos, -> { where(visivel: false) }
  end

  # Publica, passando pelas validações. Devolve false se o registro estiver inválido.
  def publicar = update(visivel: true)
```

O **`update`**, e não o `update!`: se um registro antigo estiver inválido (uma academia cadastrada antes de a categoria virar obrigatória, por exemplo), o `update` devolve `false`, e a página mostra o motivo em vez de um erro 500.

---

## Parte 3 — Os controllers da moderação

### 3.1 Um namespace para a moderação

Os controllers da moderação moram juntos, em `app/controllers/moderacao/`, como os da administração moram em `app/controllers/admin/`. A porta de entrada é o `BaseController`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Base dos controllers de moderação: só moderadores e admin entram
module Moderacao
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :exigir_moderacao

    private

    def exigir_moderacao
      redirect_to root_path, alert: "Esta página é só para quem modera." unless current_user.pode_moderar?
    end

    # Com Turbo, o item some da lista sem recarregar; sem ele, volta para a página
    def responder(registro, aviso)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(registro) }
        format.html { redirect_to moderacao_path, notice: aviso }
      end
    end
  end
end
```

É o mesmo papel do `Admin::BaseController`, com uma porta mais larga: além do admin, entram os moderadores. Todo controller que herda daqui ganha a tranca e o método `responder`. É como o `ApplicationController`, só que para uma ala do prédio.

### 3.2 A página

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module Moderacao
  class PainelController < BaseController
    def index
      @fotos = Foto.pendente.order(:created_at)
                   .includes(:autor, :fotografavel, imagem: { arquivo_attachment: :blob })
      @academias = Academia.rascunhos.order(:created_at).includes(:autor)
      @observacoes = Observacao.rascunhos.order(:created_at).includes(:autor, :academia)
    end
  end
end
```

- **`order(:created_at)`**: os mais antigos primeiro. Quem espera há mais tempo é atendido antes, como numa fila.
- **`includes(:fotografavel)`**: o Rails carrega os donos polimórficos **por tipo**, com uma consulta para as academias, outra para as observações e outra para os equipamentos.

### 3.3 As decisões

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module Moderacao
  class FotosController < BaseController
    before_action :carregar_foto

    def aprovar
      @foto.aprovar!(por: current_user)
      responder @foto, "Foto aprovada."
    end

    def recusar
      @foto.recusar!(por: current_user)
      responder @foto, "Foto recusada."
    end

    private

    # Só as pendentes: se outra pessoa já moderou, a resposta é 404
    def carregar_foto
      @foto = Foto.pendente.find(params[:id])
    end
  end
end
```

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module Moderacao
  class AcademiasController < BaseController
    def publicar
      academia = Academia.rascunhos.find(params[:id])

      if academia.publicar
        responder academia, "Academia publicada."
      else
        redirect_to moderacao_path, status: :see_other,
                    alert: "Não foi possível publicar: #{academia.errors.full_messages.to_sentence}"
      end
    end
  end
end
```

O `Moderacao::ObservacoesController` é igual, com `Observacao` no lugar de `Academia`.

- **`Foto.pendente.find` e `Academia.rascunhos.find`**: só se decide sobre o que ainda espera decisão. Se dois moderadores abrirem a página ao mesmo tempo e os dois tocarem no mesmo item, o segundo recebe 404, e a decisão de quem chegou primeiro não muda.
- **`status: :see_other`** (303): depois de um `PATCH`, o redirecionamento precisa ser 303 para o navegador seguir com um `GET`. Com o 302 padrão, alguns navegadores repetiriam o `PATCH`.

### 3.4 As rotas

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  get "moderacao", to: "moderacao/painel#index", as: :moderacao

  namespace :moderacao do
    resources :fotos, only: [] do
      member do
        patch :aprovar
        patch :recusar
      end
    end

    resources :academias, only: [] do
      patch :publicar, on: :member
    end

    resources :observacoes, only: [] do
      patch :publicar, on: :member
    end
  end
```

- **`only: []` com `member`**: cria só as rotas que existem de fato, como `PATCH /moderacao/fotos/12/aprovar`. Nenhuma rota de `index`, `show` ou `destroy` fica sobrando.
- **`on: :member`** é a forma curta do bloco `member do ... end`, para quando há uma rota só.
- **Tudo dentro do mesmo `namespace`**: é o que dá o `moderacao_` no meio dos helpers (`publicar_moderacao_academia_path`) e manda os pedidos para os controllers da pasta `moderacao/`. Uma rota fora do bloco iria para o controller público de mesmo nome.

Para conferir as rotas que o Rails enxerga:

```bash
bin/rails routes -g moderacao
```

O `-g` filtra a lista, como um `grep`.

---

## Parte 4 — Turbo Stream: o item some da lista

Moderar trinta fotos de uma turma, recarregando a página a cada toque, é cansativo. Com o **Turbo Stream**, a resposta a um "Aprovar" não é uma página nova, e sim uma **instrução** curta para a página que já está aberta:

```html
<turbo-stream action="remove" target="foto_12"></turbo-stream>
```

"Remova o elemento com `id` `foto_12`." O Turbo, que já está no navegador, executa a instrução, e o item some.

No controller, essa instrução sai do `turbo_stream.remove(registro)`, que calcula o `id` com o `dom_id`. Na view, cada item da lista usa o mesmo `dom_id`:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<li id="<%= dom_id(foto) %>" class="item-moderacao">
```

Os dois lados usam o mesmo helper, então sempre combinam.

O **`respond_to`** escolhe a resposta pelo tipo de pedido. Quando o Turbo envia o formulário do `button_to`, ele avisa que aceita Turbo Stream, e recebe a instrução. Se o pedido vier sem o Turbo, ele recebe o redirecionamento de sempre, para a página da moderação. As duas formas chegam ao mesmo resultado.

> Quem conheceu o Rails 3 vai reconhecer a ideia do `format.js`, que devolvia um JavaScript para a página executar. O Turbo Stream faz o mesmo, sem escrever JavaScript.

---

## Parte 5 — A página

### 5.1 De onde veio cada foto

A foto pode estar numa academia, numa observação ou num equipamento. Para mostrar o nome e o link do lugar, a página usa dois helpers, em `app/helpers/moderacao_helper.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module ModeracaoHelper
  # O nome do registro onde a foto foi anexada
  def descricao_do_registro(registro)
    case registro
    when Academia then registro.titulo
    when Observacao then "Observação de #{l registro.data_da_visita} em #{registro.academia.titulo}"
    when Equipamento then registro.nome
    end
  end

  # O endereço do registro. A observação não tem página própria: vai para a ficha da academia
  def caminho_do_registro(registro)
    case registro
    when Observacao then academia_path(registro.academia, anchor: dom_id(registro))
    else polymorphic_path(registro)
    end
  end
end
```

- **`polymorphic_path`** descobre a rota pelo tipo do objeto: uma academia vira `academia_path`, um equipamento vira `equipamento_path`. É o que o `link_to @academia` faz por baixo.
- **`anchor: dom_id(registro)`** leva direto à observação dentro da ficha: `/academias/3#observacao_7`. Para isso funcionar, cada observação na ficha ganhou o seu `id`:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<article class="observacao" id="<%= dom_id(observacao) %>">
```

Os mesmos helpers servem às seções das academias e das observações em rascunho.

### 5.2 As três seções

A página `app/views/moderacao/painel/index.html.erb` tem três seções, uma para cada fila: **fotos aguardando**, **academias em rascunho** e **observações em rascunho**. Cada item mostra:

- o lugar, com link;
- quem enviou e quando;
- os botões da decisão: **Aprovar** e **Recusar** nas fotos; **Publicar** e **Revisar** nas academias e observações.

O **Revisar** abre o formulário de edição. Às vezes, quem modera quer corrigir algo antes de publicar: o nome da academia, um erro no relato.

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<li id="<%= dom_id(academia) %>" class="item-moderacao">
  <div>
    <p><%= link_to descricao_do_registro(academia), caminho_do_registro(academia) %></p>
    <p class="dica">por <%= academia.autor&.login || "autor desconhecido" %> · <%= l academia.created_at, format: :short %></p>
    <div class="acoes-moderacao">
      <%= button_to "Publicar", publicar_moderacao_academia_path(academia), method: :patch %>
      <%= link_to "Revisar", edit_academia_path(academia), class: "botao-secundario" %>
    </div>
  </div>
</li>
```

O **`autor&.login`**: no `Moderavel`, o autor é opcional. O `&.` evita um erro se algum registro antigo não tiver autor.

> ⚠️ **Publique a academia antes das observações dela.** Uma observação publicada de uma academia em rascunho continua invisível para o público, porque a ficha da academia ainda não abre para visitantes. A página ajuda: a seção das academias vem antes.

### 5.3 O CSS: `60-moderacao.css`

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* 60-moderacao.css — A página de moderação */

.fila-moderacao {
  display: grid;
  gap: var(--espaco-2);
  padding: 0;
}

.item-moderacao {
  display: flex;
  align-items: flex-start;
  gap: var(--espaco-2);
  padding: var(--espaco-2);
  border-radius: var(--raio);
  background: var(--cor-branco);
}

.item-moderacao img {
  width: 6rem;
  height: 6rem;
  object-fit: cover;
  border-radius: var(--raio);
}

.acoes-moderacao {
  display: flex;
  flex-wrap: wrap;
  gap: var(--espaco-1);
  margin-top: var(--espaco-1);
}

.etiqueta-recusada {
  display: inline-block;
  padding: 0 var(--espaco-1);
  border-radius: var(--raio);
  background: var(--cor-erro);
  color: var(--cor-branco);
  font-size: 0.8125rem;
  font-weight: 700;
}
```

E, no `15-formularios.css`, o `.botao-secundario` ganhou `text-decoration: none`. Usado num link, como o "Revisar", ele ficava sublinhado, diferente do "Recusar", que é um `<button>`.

---

## Parte 6 — O contador

### 6.1 A conta, num lugar só

`app/models/moderacao/pendencias.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Quanto há para moderar: as fotos pendentes e as academias e observações em rascunho
module Moderacao
  class Pendencias
    def self.total
      Foto.pendente.count + Academia.rascunhos.count + Observacao.rascunhos.count
    end
  end
end
```

- É uma **classe Ruby comum**, sem tabela: um **PORO** (*Plain Old Ruby Object*). Nem toda regra do domínio precisa ser um model do Active Record.
- O nome `Moderacao` é o mesmo dos controllers. O Rails junta as pastas `app/controllers/moderacao/` e `app/models/moderacao/` no mesmo *namespace*.
- A conta soma as **mesmas três filas** da página. Se um dia surgir uma quarta fila, ela entra aqui, e o contador acompanha.

### 6.2 O helper

No `ApplicationController`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  helper_method :pendencias_de_moderacao

  private

  # Só quem modera vê o contador. Calculado uma vez por pedido, mesmo usado em dois lugares do layout.
  def pendencias_de_moderacao
    return 0 unless current_user&.pode_moderar?

    @pendencias_de_moderacao ||= Moderacao::Pendencias.total
  end
```

- **`helper_method`** torna o método do controller visível nas views, como o `current_user` do Devise.
- **`||=`**: o layout usa o número duas vezes. Sem a memorização, seriam seis consultas por página. Com ela, são três, e só para quem modera. Para os demais, nenhuma.

### 6.3 No layout

No menu, uma seção nova, só para quem modera:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<% if user_signed_in? && current_user.pode_moderar? %>
  <h2 class="menu-secao">Moderação</h2>
  <ul role="list">
    <li>
      <%= link_to moderacao_path do %>
        Itens aguardando
        <% if pendencias_de_moderacao.positive? %>
          <span class="contador"><%= pendencias_de_moderacao %></span>
        <% end %>
      <% end %>
    </li>
  </ul>
<% end %>
```

Na barra de abas, o ícone do Menu ganha um pontinho:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<button type="button" class="aba" popovertarget="menu-completo">
  <span class="icone-com-aviso">
    <%= icone("menu") %>
    <% if pendencias_de_moderacao.positive? %>
      <span class="ponto-aviso"></span>
    <% end %>
  </span>
  <span>Menu</span>
  <% if pendencias_de_moderacao.positive? %>
    <span class="visualmente-oculto">, há itens aguardando moderação</span>
  <% end %>
</button>
```

O pontinho é só visual. Para quem usa leitor de tela, a frase oculta faz o botão ser lido como "Menu, há itens aguardando moderação".

### 6.4 O CSS: no `20-navegacao.css`

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* O número de itens aguardando, no menu */
.contador {
  display: inline-grid;
  place-items: center;
  min-width: 1.5rem;
  height: 1.5rem;
  margin-left: var(--espaco-1);
  padding: 0 6px;
  border-radius: 999px;
  background: var(--cor-laranja);
  color: var(--cor-branco);
  font-size: 0.8125rem;
  font-weight: 700;
}

/* O pontinho sobre o ícone do Menu */
.icone-com-aviso {
  position: relative;
  display: inline-grid;
}

.ponto-aviso {
  position: absolute;
  top: -2px;
  right: -4px;
  width: 0.625rem;
  height: 0.625rem;
  border-radius: 50%;
  background: var(--cor-laranja);
  box-shadow: 0 0 0 2px var(--cor-roxo);
}
```

- **`border-radius: 999px` com `min-width`**: com um algarismo, o contador é um círculo. Com dois ("12"), ele vira uma pílula, sem cortar o número.
- **O `box-shadow` roxo** em volta do pontinho funciona como uma borda da cor da barra, que o separa do ícone.

> O contador é calculado a cada página carregada. Enquanto você aprova itens na própria página da moderação, ele não muda. Ao navegar para outra página, ele já mostra o número novo.

---

## Parte 7 — Os testes

### 7.1 Os models

| Teste | O que garante |
| --- | --- |
| O autor remove enquanto não aprovada; quem modera remove sempre | O `removivel_por?` com a recusada |
| A moderação registra quem moderou e quando | O rastro da decisão |
| O total soma fotos pendentes e registros em rascunho | O `Moderacao::Pendencias`, que sobe com uma foto nova e desce com uma publicação |

### 7.2 Os controllers

| Teste | O que garante |
| --- | --- |
| Comum não entra na moderação | A porta do `BaseController` |
| Moderadora vê a foto pendente | A página |
| Moderadora aprova, e a foto some da lista | O caminho do Turbo Stream |
| Moderadora recusa | O caminho do HTML, com redirecionamento |
| **Comum não aprova** | A porta fechada também nas **ações**, e não só na página |
| Foto já moderada dá 404 | Dois moderadores ao mesmo tempo |
| Moderadora vê e publica a academia em rascunho | A publicação |
| **Comum não publica** | A porta fechada na ação que mexe no que o público vê |
| Academia já publicada dá 404 | O `rascunhos.find` |
| O contador aparece só para quem modera | O `pendencias_de_moderacao` |

Dois detalhes dos testes:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
    patch aprovar_moderacao_foto_path(@foto), as: :turbo_stream
```

O **`as: :turbo_stream`** simula o pedido que o Turbo faz no navegador. Sem ele, o teste prova o caminho do HTML.

```ruby
# 📖 JÁ ESTÁ NO PROJETO
    assert_select "##{ActionView::RecordIdentifier.dom_id(@foto)}"
```

O **`assert_select`** procura um elemento no HTML da resposta, com a mesma sintaxe do CSS. O `#` é o seletor de `id`. Fora das views, o `dom_id` mora no módulo `ActionView::RecordIdentifier`.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 8 — Testando no navegador

Como **Ana** (comum):

1. Anexe uma foto da galeria a uma academia publicada.
2. Cadastre uma academia nova, que nasce como rascunho, e registre uma observação nela.

Como **Bia** (moderadora):

3. O ícone do **Menu** tem um pontinho laranja. Abra o menu: **Moderação → Itens aguardando**, com o número.
4. Na página, a foto, a academia e a observação aparecem nas suas seções.
5. **Aprove a foto**: ela some da lista, sem recarregar.
6. **Publique a academia**, depois a **observação**.
7. Navegue para outra página: o pontinho sumiu.

De novo como **Ana**:

8. Anexe outra foto, e peça para a Bia recusar.
9. Na ficha da academia, a foto recusada aparece para a Ana com a etiqueta vermelha. Numa aba anônima, ela não aparece.
10. No formulário da academia, a recusada tem a opção **Remover**.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Como comum, abrir `/moderacao` | Voltar para o início, com um aviso |
| Como comum, enviar um `PATCH` para `/moderacao/fotos/ID/aprovar` | Não aprovar |
| Aprovar a mesma foto em duas abas | A segunda aba recebe 404 |
| Publicar uma academia já publicada | Dar 404 |
| Como visitante, ver uma foto recusada na ficha | Não aparecer |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Moderação** | A curadoria: decidir o que aparece para o público. |
| **Namespace** | Uma pasta e um prefixo para um grupo de controllers e rotas, como `admin/` e `moderacao/`. |
| **Turbo Stream** | Uma instrução curta enviada à página aberta: remover, acrescentar ou trocar um pedaço dela, sem recarregar. |
| **`dom_id`** | O `id` HTML de um registro, como `foto_12`. O mesmo helper serve à view e ao controller. |
| **`respond_to`** | Escolhe a resposta pelo tipo de pedido: Turbo Stream ou HTML. |
| **303 See Other** | O redirecionamento certo depois de um `PATCH` ou `POST`: o navegador segue com um `GET`. |
| **`polymorphic_path`** | Descobre a rota pelo tipo do objeto. |
| **PORO** | *Plain Old Ruby Object*: uma classe Ruby comum, sem banco por trás. |
| **`helper_method`** | Deixa um método do controller visível nas views. |
| **Memorização (`\|\|=`)** | Guarda um valor já calculado para não calcular de novo no mesmo pedido. |
| **`assert_select`** | Procura um elemento no HTML da resposta, num teste. |

---

## O que aprendemos

- Tudo o que espera decisão fica num lugar só, em ordem de chegada.
- A decisão deixa rastro: quem decidiu e quando.
- Recusar não é apagar: o trabalho do aluno continua com ele, e ele entende o que aconteceu.
- Uma base de controller é uma porta para uma ala inteira do sistema, e os testes provam que ela está fechada nas ações, não só na página.
- Só se decide sobre o que ainda espera decisão: assim, dois moderadores não se atropelam.
- O Turbo Stream troca o "recarregar a página" por uma instrução curta, sem JavaScript.
- Uma conta usada em vários lugares mora num lugar só, e é feita uma vez por pedido.

**Próximo capítulo:** em breve.

---

## Fontes

- [Rails Guides — Routing: Controller Namespaces and Routing](https://guides.rubyonrails.org/routing.html#controller-namespaces-and-routing)
- [Rails Guides — Routing: Adding More RESTful Actions](https://guides.rubyonrails.org/routing.html#adding-more-restful-actions)
- [Turbo Handbook — Streams](https://turbo.hotwired.dev/handbook/streams)
- [Rails API — `turbo_stream` (turbo-rails)](https://github.com/hotwired/turbo-rails)
- [Rails API — `ActionView::RecordIdentifier#dom_id`](https://api.rubyonrails.org/classes/ActionView/RecordIdentifier.html)
- [Rails API — `polymorphic_path`](https://api.rubyonrails.org/classes/ActionDispatch/Routing/PolymorphicRoutes.html)
- [MDN — 303 See Other](https://developer.mozilla.org/pt-BR/docs/Web/HTTP/Status/303)
- [Rails API — `assert_select`](https://api.rubyonrails.org/classes/ActionDispatch/Assertions/SelectorAssertions.html)
