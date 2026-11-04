# 0190 — Administração dos equipamentos

> **Neste capítulo:** o administrador passa a cuidar da lista de equipamentos pelo próprio site: **cadastrar**, **editar** e **publicar**. Um equipamento novo nasce como **rascunho**, escondido do público, até o guia estar pronto e revisado. Vamos montar o **CRUD** mais clássico do Rails, ver como o model percebe que um campo **mudou** e criar uma trava que protege o endereço de um equipamento que já tem guia.

**Tag deste capítulo:** `cap-0190`

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

O `db:migrate` cria a coluna `visivel` (Parte 2). Depois dele, **todos** os equipamentos ficam escondidos, e a lista pública fica vazia: nenhum deles tem guia ainda. Para ver a lista, entre como admin.

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
> git switch -c estudo-0190 cap-0190
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
> git branch -D estudo-0190
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo e os equipamentos.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar um `generate` de novo, por exemplo, criaria uma segunda migration igual à primeira, e o `db:migrate` daria erro.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — O que o administrador precisa fazer

No capítulo 0170, a lista de equipamentos entrou pelo `db/seeds.rb`. Para mudar a lista, só mexendo no código ou no console do servidor, e o console de produção só uma pessoa acessa. Mas a lista **vai mudar**: a pesquisa de campo vai trazer nomes novos, correções e equipamentos que ninguém tinha listado.

O administrador precisa de três coisas:

| Ação | Por quê |
| --- | --- |
| **Cadastrar** | Um equipamento novo, encontrado numa praça |
| **Editar** | Corrigir um nome escrito errado |
| **Publicar** | Mostrar o equipamento ao público só quando o guia estiver pronto e revisado |

### E apagar?

De propósito, **não** há botão de apagar. **Esconder** resolve o mesmo problema sem perder nada. E, quando o projeto tiver dados ligados a um equipamento (as academias onde ele está, as avaliações de quem usou), apagar um equipamento deixaria esses dados apontando para o nada. Esconder é reversível; apagar, não.

---

## Parte 2 — O rascunho: a coluna `visivel`

### 2.1 A migration

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate migration AddVisivelToEquipamentos visivel:boolean
```

O nome `AddVisivelToEquipamentos` segue a convenção `Add<Coluna>To<Tabela>`, e o Rails entende sozinho que é para **acrescentar** a coluna `visivel` à tabela `equipamentos`. A migration gerada foi ajustada à mão:

```ruby
add_column :equipamentos, :visivel, :boolean, default: false, null: false
```

| Opção | Por quê |
| --- | --- |
| `:boolean` | Só dois valores: verdadeiro ou falso |
| `default: false` | Todo equipamento novo nasce **escondido** |
| `null: false` | Nunca fica "sem resposta". Um booleano com `null` teria **três** estados: sim, não e "não sei", e o terceiro só traz confusão |

Repare no efeito sobre os equipamentos que **já existiam**: a coluna nova chega com o valor padrão, `false`, e todos ficam escondidos. Era o que queríamos, porque nenhum deles tinha guia.

### 2.2 O escopo `visiveis`

No model:

```ruby
scope :visiveis, -> { where(visivel: true) }
```

Pense num atalho na tela do celular para um contato que você chama todo dia. O contato continua na agenda, mas o atalho poupa o caminho.

Em termos técnicos, um **scope** dá um **nome** a uma consulta que se repete. Em vez de espalhar `where(visivel: true)` pelo projeto, escrevemos `Equipamento.visiveis`, que se lê como português. E dá para continuar a consulta: `Equipamento.visiveis.order(:nome)`.

---

## Parte 3 — O público vê os publicados, o admin vê tudo

No `app/controllers/equipamentos_controller.rb`:

```ruby
class EquipamentosController < ApplicationController
  def index
    @equipamentos = equipamentos_permitidos.order(:nome)
  end

  def show
    @equipamento = equipamentos_permitidos.find_by!(slug: params[:slug])
  end

  private

  # O admin vê também os rascunhos; o público, só os visíveis
  def equipamentos_permitidos
    current_user&.admin? ? Equipamento.all : Equipamento.visiveis
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `current_user&.admin?` | O `&.` é o **operador de navegação segura**: se ninguém está logado, `current_user` é `nil`, e o `&.` devolve `nil` em vez de dar erro |
| `condição ? a : b` | O **operador ternário**: um `if` de uma linha. "Se for admin, todos; senão, só os visíveis" |
| `equipamentos_permitidos` | A regra fica escrita **uma vez** e vale para a lista e para a página |

Para o visitante, um rascunho **não existe**: não aparece na lista, e o endereço dele responde 404. Para o admin, ele aparece, mas **marcado**. Assim, a fisioterapeuta que revisa o guia consegue ver a página exatamente como vai ficar, antes de publicar.

Na página do equipamento (`show.html.erb`), logo abaixo do título:

```erb
<% unless @equipamento.visivel %>
  <p class="aviso-rascunho">Rascunho: este equipamento ainda não está visível para o público.</p>
<% end %>
```

E no cartão da lista (`index.html.erb`), depois do nome:

```erb
<% unless equipamento.visivel %>
  <span class="etiqueta-rascunho">Rascunho</span>
<% end %>
```

---

## Parte 4 — A área de administração

### 4.1 As rotas

Dentro do `namespace :admin` que já existia desde o capítulo 0150:

```ruby
namespace :admin do
  resources :users, only: [ :index, :edit, :update ]
  resources :equipamentos, only: [ :index, :new, :create, :edit, :update ], param: :slug
end
```

| Ação | Endereço | Para quê |
| --- | --- | --- |
| `index` | `GET /admin/equipamentos` | A lista, com o estado de cada um |
| `new` | `GET /admin/equipamentos/new` | O formulário vazio |
| `create` | `POST /admin/equipamentos` | Salva o equipamento novo |
| `edit` | `GET /admin/equipamentos/leg-press/edit` | O formulário preenchido |
| `update` | `PATCH /admin/equipamentos/leg-press` | Salva as mudanças |

### 4.2 O que é CRUD?

Quase todo cadastro do mundo faz as mesmas quatro coisas, como uma agenda de papel: escrever um contato novo, consultar, corrigir e riscar.

Em termos técnicos, **CRUD** é a sigla em inglês para essas quatro operações: **C**reate (criar), **R**ead (ler), **U**pdate (atualizar) e **D**elete (apagar). O Rails tem um jeito padrão para cada uma, com as sete ações da tabela acima mais `show` e `destroy`. Nós usamos cinco; o `destroy` ficou de fora pelo motivo da Parte 1.

### 4.3 O controller

`app/controllers/admin/equipamentos_controller.rb`:

```ruby
module Admin
  class EquipamentosController < BaseController
    before_action :carregar_equipamento, only: [ :edit, :update ]

    def index
      @equipamentos = Equipamento.order(:nome)
    end

    def new
      @equipamento = Equipamento.new
    end

    def create
      @equipamento = Equipamento.new(equipamento_params)

      if @equipamento.save
        redirect_to admin_equipamentos_path, notice: "Equipamento cadastrado."
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
    end

    def update
      if @equipamento.update(equipamento_params)
        redirect_to admin_equipamentos_path, notice: "Equipamento atualizado."
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def carregar_equipamento
      @equipamento = Equipamento.find_by!(slug: params[:slug])
    end

    def equipamento_params
      params.expect(equipamento: [ :nome, :slug, :visivel ])
    end
  end
end
```

Quase tudo aqui você já viu no `Admin::UsersController` do capítulo 0150:

- **`< BaseController`:** herda o porteiro. A tela já nasce restrita ao admin, sem nenhuma linha a mais.
- **`params.expect`:** só aceita `nome`, `slug` e `visivel`. Qualquer outro campo enviado é descartado.
- **`before_action :carregar_equipamento`:** busca o equipamento uma vez, para o `edit` e o `update`.

### 4.4 Salvou ou não salvou: `redirect_to` e `render`

Repare no par `if ... save` / `else`:

| Resultado | O que o controller faz | Por quê |
| --- | --- | --- |
| **Salvou** | `redirect_to` para a lista | Manda o navegador fazer um pedido **novo**. Se a pessoa apertar F5, não cadastra de novo |
| **Não salvou** | `render :new` | Mostra o **mesmo** formulário, com o que a pessoa digitou e os erros. Nada se perde |

E o `status: :unprocessable_content` é o código **422**: *"entendi o pedido, mas os dados têm problema"*. Ele é obrigatório com o Turbo. Sem ele, a resposta sai com o código 200 (*"tudo certo"*), e o Turbo, que espera um redirecionamento depois de um formulário, não mostra o formulário com os erros.

> 💡 Em tutoriais mais antigos, você vai ver `:unprocessable_entity`. É o mesmo código 422, com o nome antigo. O Rack, a peça que fica entre o servidor e o Rails, adotou o nome novo na versão 3.1.

---

## Parte 5 — A trava do slug

### 5.1 O problema

Desde o capítulo 0170, o slug é o **nome do arquivo** do guia: o texto do leg press mora em `conteudo/equipamentos/leg-press.html`. Se o admin mudar o slug para `leg-press-duplo`, o Rails passa a procurar `leg-press-duplo.html`, que não existe. A página perde o guia, sem nenhum aviso.

Pensamos em fazer o Rails **renomear o arquivo** sozinho. Não daria certo: o arquivo do guia está no Git, e o servidor de produção recebe o código pelo `git pull`. Se o servidor renomeasse um arquivo por conta própria, o repositório e o servidor ficariam diferentes, e o próximo `git pull` brigaria com essa diferença. **O repositório é a fonte da verdade**, e o servidor não muda o código.

### 5.2 A solução

O slug pode mudar **enquanto o equipamento não tem guia**. Isso cobre o caso comum: corrigir um erro de digitação logo depois de cadastrar. Quando o guia existe, o slug trava. Para mudar, renomeia-se o arquivo por Pull Request e o slug pelo console, juntos.

### 5.3 O código

```ruby
validate :slug_travado_com_guia, on: :update

def tem_guia? = arquivo.exist?

private

def arquivo(s = slug) = Rails.configuration.x.pasta_equipamentos.join("#{s}.html")

def slug_travado_com_guia
  return unless will_save_change_to_slug? && arquivo(slug_in_database).exist?

  errors.add(:slug, "não pode mudar: este equipamento já tem guia. Renomeie o arquivo por Pull Request.")
end
```

| Trecho | O que faz |
| --- | --- |
| `validate :slug_travado_com_guia` | Uma validação **nossa**, escrita como método. Repare: `validate`, no singular, para validações próprias; `validates`, no plural, para as prontas do Rails |
| `on: :update` | Só vale na edição. No cadastro, ainda não existe slug antigo para proteger |
| `arquivo(s = slug)` | O método ganhou um parâmetro opcional: sem argumento, usa o slug atual; com argumento, monta o caminho de outro slug |
| `errors.add(:slug, "...")` | Pendura a mensagem no campo `slug`. Com um erro, o `save` e o `update` devolvem `false` |

### 5.4 Como o model sabe que o slug mudou?

Pense num documento com o controle de alterações ligado. Você vê o texto novo e, ao lado, o que estava escrito antes.

Em termos técnicos, é o **dirty tracking** do Active Record. Quando você muda um atributo, o objeto lembra o valor que veio do banco, até salvar. Cada atributo ganha uma família de métodos:

```ruby
equipamento = Equipamento.find_by(slug: "leg-press")
equipamento.slug = "leg-press-duplo"

equipamento.slug                       # => "leg-press-duplo"  (o novo)
equipamento.slug_in_database           # => "leg-press"        (o que está no banco)
equipamento.will_save_change_to_slug?  # => true               (vai mudar ao salvar)
```

Com isso, a trava confere o arquivo do slug **antigo**, que é onde o guia está de verdade.

> 💡 Teste no `bin/rails console`, sem medo: enquanto você não chamar `save`, nada muda no banco.

### 5.5 A pegadinha do `to_param`

```ruby
def to_param = slug_in_database || slug
```

No capítulo 0170, o `to_param` devolvia só o `slug`. Agora que o slug pode ser editado, isso causaria um erro escondido:

1. O admin muda o slug de `remada` para `remada sentada` (com espaço, inválido) e salva.
2. A validação falha, e o `render :edit` mostra o formulário de novo, com o erro.
3. O formulário monta o endereço de envio com o `to_param`. Se ele usasse o slug **digitado**, o endereço seria `/admin/equipamentos/remada sentada`, que não existe. O próximo envio daria 404.

Com o `slug_in_database`, o formulário continua apontando para o endereço que existe de verdade. O `|| slug` cobre o equipamento ainda não salvo, que não tem nada no banco.

É uma pegadinha clássica: **sempre que a URL usa um atributo editável**, o formulário com erro precisa do valor antigo.

### 5.6 A trava fica no model, e não só na tela

No formulário, o campo do slug aparece **desabilitado** quando já existe guia. Mas isso é cortesia: um campo desabilitado na tela não impede ninguém de mandar o dado por outro caminho, como o console ou um pedido montado à mão. A regra de verdade é a validação do model, que vale para **qualquer** caminho. É a mesma ideia do capítulo 0180: esconder o link é cortesia, e a segurança fica no servidor.

---

## Parte 6 — O formulário e os erros embaixo de cada campo

### 6.1 Um formulário para duas telas

`app/views/admin/equipamentos/_form.html.erb`:

```erb
<%= form_with model: [ :admin, equipamento ] do |f| %>
  <div class="campo">
    <%= f.label :nome %>
    <%= f.text_field :nome %>
    <% equipamento.errors.full_messages_for(:nome).each do |msg| %>
      <p class="erro-campo"><%= msg %></p>
    <% end %>
  </div>

  <div class="campo">
    <%= f.label :slug, "Endereço (slug)" %>
    <%= f.text_field :slug, disabled: equipamento.persisted? && equipamento.tem_guia? %>
    <% if equipamento.persisted? && equipamento.tem_guia? %>
      <p class="dica">Este equipamento já tem guia. Para mudar o endereço, renomeie o arquivo por Pull Request.</p>
    <% else %>
      <p class="dica">Deixe em branco para gerar a partir do nome.</p>
    <% end %>
    <% equipamento.errors.full_messages_for(:slug).each do |msg| %>
      <p class="erro-campo"><%= msg %></p>
    <% end %>
  </div>

  <div class="campo">
    <%= f.check_box :visivel %>
    <%= f.label :visivel, "Visível para o público" %>
  </div>

  <%= f.submit "Salvar" %>
<% end %>
```

O sublinhado no começo do nome (`_form`) indica um **partial**: um pedaço de view que outras views incluem. O `new.html.erb` e o `edit.html.erb` usam o mesmo formulário:

```erb
<h1>Cadastrar equipamento</h1>
<%= render "form", equipamento: @equipamento %>
<%= link_to "Voltar", admin_equipamentos_path %>
```

| Trecho | O que faz |
| --- | --- |
| `form_with model: [ :admin, equipamento ]` | O Rails monta o endereço sozinho: equipamento **novo** vai para `POST /admin/equipamentos`; equipamento **salvo** vai para `PATCH /admin/equipamentos/leg-press`. O `:admin` coloca o endereço dentro do namespace |
| `equipamento.persisted?` | "Já está salvo no banco?" Equipamento novo não tem guia para proteger |
| `full_messages_for(:nome)` | Só os erros **deste** campo, com o nome do campo na frente: *"Nome não pode ficar em branco"* |
| `f.check_box :visivel` | A caixa de marcar. O Rails ainda cria um campo escondido com `0`, para o "desmarcado" também chegar ao servidor. Sem ele, desmarcar a caixa não mudaria nada |

### 6.2 Por que o erro embaixo do campo?

O jeito padrão dos geradores do Rails é uma lista de erros **no topo** do formulário. Num formulário longo, ou no celular, a pessoa precisa ler a lista, guardar na cabeça e procurar cada campo. Com a mensagem **colada no campo**, ela olha para onde precisa corrigir e já vê o que está errado.

### 6.3 Mensagens que não se contradizem

Na primeira versão, cadastrar sem nome mostrava **três** erros: *"Nome não pode ficar em branco"*, *"Slug não pode ficar em branco"* e *"Slug não é válido"*. Os dois últimos eram consequência do primeiro: sem nome, não há de onde gerar o slug. E *"não pode ficar em branco"* contradizia a dica logo acima, *"Deixe em branco..."*.

A validação do slug ficou assim:

```ruby
validates :slug, presence: { if: -> { nome.present? } },
                 uniqueness: true,
                 format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/, allow_blank: true }
```

- `presence: { if: -> { nome.present? } }`: só reclama do slug vazio se houver nome. Sem nome, o erro do nome já impede o cadastro.
- `allow_blank: true`: o formato só é conferido quando há algo para conferir.

Agora, sem nome, aparece **um** erro, no lugar certo. Mostrar só o erro que a pessoa consegue resolver é parte de um bom formulário.

### 6.4 "Endereço", e não "Slug"

"Slug" é palavra de programador. No `config/locales/pt-BR.yml`:

```yaml
pt-BR:
  activerecord:
    attributes:
      equipamento:
        nome: "Nome"
        slug: "Endereço"
        visivel: "Visível"
```

O Rails usa esses nomes nas mensagens de erro: *"Endereço não pode mudar: este equipamento já tem guia..."*.

---

## Parte 7 — A lista do admin e o CSS

### 7.1 A lista

`app/views/admin/equipamentos/index.html.erb` mostra, para cada equipamento, o nome, o slug, se está **visível** ou **escondido**, se **tem guia** ou **falta guia**, e os links para editar e para ver a página. Com "Falta guia" à vista, fica fácil distribuir as tarefas de escrita para a turma.

O link para a tela fica no menu completo, só para o admin, logo abaixo de "Usuários":

```erb
<li><%= link_to "Gerenciar equipamentos", admin_equipamentos_path %></li>
```

### 7.2 O carimbo de rascunho

No `40-equipamentos.css`:

```css
.cartao-equipamento {
  position: relative;
}

.etiqueta-rascunho {
  position: absolute;
  right: var(--espaco-1);
  bottom: var(--espaco-1);
  /* cores, tamanho e cantos */
}
```

Pense num adesivo colado no canto de uma caixa. A caixa é a referência: o adesivo fica no canto **dela**, e não no canto da sala.

Em termos técnicos, `position: absolute` tira o elemento do **fluxo** da página: ele não ocupa espaço nem empurra os vizinhos, e se posiciona pelas coordenadas `right` e `bottom`. Essas coordenadas são contadas a partir do ancestral mais próximo que tenha `position: relative`, aqui o cartão. Sem o `relative` no cartão, todos os carimbos iriam parar no mesmo canto da página.

Numa primeira versão, o carimbo ficava **ao lado** do nome, no fluxo normal. Em 320 px, o nome e o carimbo juntos não cabiam, e o cartão estourava a largura da tela. Fora do fluxo, o carimbo não disputa espaço com o nome.

### 7.3 Os estilos do formulário

No `30-admin.css`, as classes `.campo` (espaço entre os campos), `.dica` (texto de ajuda, menor e mais claro), `.erro-campo` (o erro, em vermelho e negrito) e `.aviso-rascunho` (a faixa amarela da página do equipamento).

---

## Parte 8 — O Brakeman de novo

Ao mudar o `show` para usar o `equipamentos_permitidos`, o alerta de XSS do capítulo 0170 **voltou**, agora com confiança *Weak* e a mensagem *"Unescaped parameter value"*.

O Brakeman identifica cada alerta por uma **impressão digital** calculada a partir do código. A linha mudou, a impressão mudou, e a entrada antiga do `brakeman.ignore` deixou de reconhecer o alerta. É de propósito: mexeu no código, alguém precisa olhar de novo.

A análise do capítulo 0170 continua valendo: o texto vem só dos arquivos de `conteudo/equipamentos/`. O `params[:slug]` só **escolhe** o registro no banco, e nunca vira texto na página. Então:

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/brakeman -I
```

1. Opção **1**, inspecionar todos os alertas, e **`n`** no alerta, com a nota:
   *"Conteúdo vem só de arquivos HTML em conteudo/equipamentos, revisados via PR. O params[:slug] só escolhe o registro no banco; o slug é validado no model."*
2. Salvar.
3. Rodar `bin/brakeman -I` de novo, escolher a opção **3** (*Prune obsolete ignored warnings*) para remover a entrada antiga, que não corresponde a mais nada, e salvar.

O resultado: 0 alertas, 1 ignorado, com a nota atualizada.

> 💡 Não precisa decorar a nota: ela fica guardada no próprio `config/brakeman.ignore`. Na próxima vez, copie de lá e atualize o que tiver mudado.

---

## Parte 9 — Os testes

### 9.1 Um rascunho nos fixtures

No `test/fixtures/equipamentos.yml`, `barra_fixa` e `remada` ganharam `visivel: true`, e entrou um terceiro:

```yaml
rascunho:
  nome: Rotação diagonal
  slug: rotacao-diagonal
  visivel: false
```

### 9.2 O model

```ruby
test "o slug não muda quando já existe guia" do
  equipamento = equipamentos(:barra_fixa)
  assert_not equipamento.update(slug: "outro-nome")
  assert_includes equipamento.errors[:slug].first, "já tem guia"
end

test "o slug muda quando ainda não existe guia" do
  equipamento = equipamentos(:remada)
  assert equipamento.update(slug: "remada-sentada")
end

test "visiveis deixa os rascunhos de fora" do
  assert_not_includes Equipamento.visiveis, equipamentos(:rascunho)
end
```

Os dois primeiros testes são um **par**: um confere que a trava funciona quando deve, e o outro, que ela **não** atrapalha quando não deve. Uma trava que bloqueia tudo também passaria no primeiro teste.

### 9.3 A parte pública

```ruby
test "visitante não vê rascunho na lista nem na página" do
  get equipamentos_url
  assert_no_match "Rotação diagonal", response.body

  get equipamento_url(equipamentos(:rascunho))
  assert_response :not_found
end

test "admin vê a página do rascunho com aviso" do
  sign_in users(:admin)
  get equipamento_url(equipamentos(:rascunho))
  assert_response :success
  assert_select ".aviso-rascunho"
end

test "admin vê o rascunho na lista, com a etiqueta" do
  sign_in users(:admin)
  get equipamentos_url
  assert_select ".etiqueta-rascunho", count: 1
end
```

O `count: 1` confere duas coisas de uma vez: o rascunho **tem** etiqueta, e os publicados **não** têm.

### 9.4 A área do admin

`test/controllers/admin/equipamentos_controller_test.rb`:

```ruby
require "test_helper"

class Admin::EquipamentosControllerTest < ActionDispatch::IntegrationTest
  test "usuário comum não entra" do
    sign_in users(:ana)
    get admin_equipamentos_url
    assert_redirected_to root_path
  end

  test "admin cadastra equipamento, que nasce escondido" do
    sign_in users(:admin)

    assert_difference "Equipamento.count", 1 do
      post admin_equipamentos_url, params: { equipamento: { nome: "Surf" } }
    end

    equipamento = Equipamento.find_by!(slug: "surf")
    assert_not equipamento.visivel
    assert_redirected_to admin_equipamentos_path
  end

  test "admin publica um equipamento" do
    sign_in users(:admin)
    patch admin_equipamento_url(equipamentos(:rascunho)), params: { equipamento: { visivel: "1" } }
    assert equipamentos(:rascunho).reload.visivel
  end

  test "cadastro sem nome mostra o erro embaixo do campo" do
    sign_in users(:admin)
    post admin_equipamentos_url, params: { equipamento: { nome: "" } }
    assert_response :unprocessable_content
    assert_select ".erro-campo"
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `assert_difference "Equipamento.count", 1 do ... end` | Conta os equipamentos antes e depois do bloco, e confere que aumentou **um** |
| `.reload` | Busca o registro de novo no banco. Sem ele, o teste olharia o objeto antigo, carregado antes do `patch` |
| `assert_response :unprocessable_content` | Confere o código 422 da Parte 4.4 |

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 10 — Testando no navegador

1. Abra `/equipamentos` numa **aba anônima**: a lista está vazia, porque todos são rascunho.
2. Entre como admin, abra **Menu → Gerenciar equipamentos**: todos aparecem como "Escondido" e "Falta guia".
3. Abra `/equipamentos` como admin: todos os cartões têm o carimbo **Rascunho**.
4. Publique um equipamento. Na aba anônima, recarregue: ele aparece.
5. Abra um rascunho como admin: a faixa amarela avisa que é rascunho. Copie o endereço para a aba anônima: 404.
6. Cadastre um equipamento só com o nome: o slug é gerado sozinho.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Cadastrar **sem nome** | Mostrar **um** erro, embaixo do campo Nome |
| Cadastrar um nome que **já existe** | Recusar: o endereço gerado é igual ao de outro equipamento |
| Escrever o endereço com **espaço ou acento**, como `remada sentada` | Recusar, com o erro embaixo do campo, e continuar no formulário certo ao corrigir (é a Parte 5.5 funcionando) |
| Copiar o `_MODELO.html` para o slug de um equipamento e abrir a edição dele | O campo do endereço aparece travado, com a explicação. Apague o arquivo depois |
| Como usuário **comum**, digitar `/admin/equipamentos` | Ser barrado pelo porteiro |
| No console, mudar o slug de um equipamento **com guia** e chamar `save` | Devolver `false`, com o erro em `errors[:slug]`: a trava vale fora da tela também |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **CRUD** | Criar, ler, atualizar e apagar: as quatro operações de quase todo cadastro. |
| **Rascunho** | Um registro que existe, mas ainda não aparece para o público. |
| **Scope** | Como um atalho para um contato: um nome para uma consulta que se repete. |
| **Operador de navegação segura** (`&.`) | Chama o método só se o objeto não for `nil`. |
| **Operador ternário** (`? :`) | Um `if` de uma linha: `condição ? se_sim : se_não`. |
| **Dirty tracking** | Como o controle de alterações de um documento: o objeto lembra o valor antigo até salvar. |
| **Partial** | Um pedaço de view, com nome começando por `_`, que outras views incluem. |
| **Código 422** | A resposta *"entendi, mas os dados têm problema"*, usada quando o formulário volta com erros. |
| **`position: absolute`** | Como um adesivo no canto de uma caixa: o elemento sai do fluxo e se posiciona pelo ancestral com `position: relative`. |

---

## O que aprendemos

- Esconder é reversível; apagar, não. Na dúvida, esconda.
- Um `default` bem escolhido na migration decide o comportamento de todo registro novo.
- Uma regra que vale em dois lugares merece um método com nome.
- `redirect_to` quando salvou; `render` com 422 quando não salvou.
- O model sabe o que mudou antes de salvar, e uma validação própria pode usar isso.
- Quando a URL usa um atributo editável, o formulário com erro precisa do valor antigo.
- A trava de verdade fica no model; o campo desabilitado é cortesia.
- Erro bom aparece colado no campo, e só quando a pessoa consegue resolver.
- Mexeu no código de um alerta ignorado? O Brakeman pede para olhar de novo, e a nota se atualiza.

**Próximo capítulo:** [0200 — Erros nos formulários](0200-erros-nos-formularios.md)

---

## Fontes

- [Rails Guides — Active Record Migrations](https://guides.rubyonrails.org/active_record_migrations.html)
- [Rails Guides — Active Record Query Interface: scopes](https://guides.rubyonrails.org/active_record_querying.html#scopes)
- [Rails Guides — Active Record Validations: custom methods](https://guides.rubyonrails.org/active_record_validations.html#custom-methods)
- [Rails API — `ActiveRecord::AttributeMethods::Dirty`](https://api.rubyonrails.org/classes/ActiveRecord/AttributeMethods/Dirty.html)
- [Rails Guides — Action View Form Helpers](https://guides.rubyonrails.org/form_helpers.html)
- [MDN — `position`](https://developer.mozilla.org/en-US/docs/Web/CSS/position)
