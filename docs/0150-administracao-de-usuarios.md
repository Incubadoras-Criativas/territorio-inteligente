# 0150 — Administração de usuários

> **Neste capítulo:** o administrador ganha uma área só dele, com a lista de usuários e a tela para mudar o nível de acesso de cada um. Vamos ver como um **namespace** organiza essa área, como um "porteiro" protege todas as telas de uma vez, por que o administrador não pode rebaixar a si mesmo e o que faz o **RuboCop**.

**Tag deste capítulo:** `cap-0150`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails db:migrate
bin/rails test
```

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
> git switch -c estudo-0150 cap-0150
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
> git branch -D estudo-0150
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin e os usuários de exemplo.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar um `generate` de novo, por exemplo, criaria uma segunda migration igual à primeira, e o `db:migrate` daria erro.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — Uma área separada: o `namespace`

Em `config/routes.rb`:

```ruby
namespace :admin do
  resources :users, only: [ :index, :edit, :update ]
end
```

O `namespace :admin` agrupa tudo o que é de administração:

| O quê | Fica em |
| --- | --- |
| Endereços | Começam com `/admin`: `/admin/users`, `/admin/users/7/edit` |
| Controllers | Pasta `app/controllers/admin/` |
| Views | Pasta `app/views/admin/` |
| Testes | Pasta `test/controllers/admin/` |
| Nomes das rotas | Começam com `admin_`: `admin_users_path`, `edit_admin_user_path(user)` |

Quem abrir o projeto daqui a um ano sabe na hora onde está **tudo** o que é de administração.

Aqui a rota é `resources`, no **plural**, com `id` na URL: o administrador escolhe **qual** usuário editar. Compare com o `resource :perfil` do capítulo 0140.

---

## Parte 2 — O porteiro

### O que é herança?

Numa família, as regras da casa valem para todo mundo: *"tira o sapato na entrada"*. Quem nasce na casa já cresce com essas regras, sem precisar que alguém repita para cada um.

Em termos técnicos, **herança** é quando uma classe **recebe tudo** o que outra classe define: métodos, `before_action`s, configurações. No Ruby, ela se escreve com `<`:

```ruby
class UsersController < BaseController
```

*"O `UsersController` é um tipo de `BaseController`, e herda tudo dele."* O projeto já usa herança desde o começo, sem chamar por esse nome: todo controller herda de `ApplicationController`, e todo model herda de `ApplicationRecord`. A classe que herda pode **acrescentar** coisas próprias, mas não perde as que recebeu.

### O porteiro da administração

`app/controllers/admin/base_controller.rb`:

```ruby
module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :exigir_admin

    private

    def exigir_admin
      redirect_to root_path, alert: "Acesso restrito a administradores." unless current_user.admin?
    end
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `module Admin` | O controller mora "dentro" do namespace `Admin` |
| `before_action :authenticate_user!` | Primeiro: tem alguém logado? |
| `before_action :exigir_admin` | Depois: essa pessoa é administradora? |
| `unless current_user.admin?` | "A não ser que seja admin": quem não é volta para a página inicial |

Todos os controllers de administração **herdam** deste. A regra fica escrita **uma vez**: uma tela nova de administração já nasce protegida, sem ninguém precisar lembrar. É o DRY do capítulo 000.

---

## Parte 3 — O controller dos usuários

`app/controllers/admin/users_controller.rb`:

```ruby
module Admin
  class UsersController < BaseController
    before_action :set_user, only: [ :edit, :update ]

    def index
      @users = User.order(:nome)
    end

    def edit
    end

    def update
      if @user == current_user && user_params[:role] != "admin"
        redirect_to admin_users_path, alert: "Você não pode remover o seu próprio acesso de administrador."
      elsif @user.update(user_params)
        redirect_to admin_users_path, notice: "Nível de acesso de #{@user.nome} atualizado."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_user
      @user = User.find(params.expect(:id))
    end

    def user_params
      params.expect(user: [ :role ])
    end
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `< BaseController` | Herda o porteiro: só administradores chegam aqui |
| `before_action :set_user, only: [ :edit, :update ]` | Antes de editar ou salvar, busca o usuário pelo `id` da URL |
| `User.order(:nome)` | Todos os usuários, em ordem alfabética |
| `params.expect(user: [ :role ])` | Aqui, **e só aqui**, o `role` entra nos campos permitidos |

### A trava: o administrador não se rebaixa

```ruby
if @user == current_user && user_params[:role] != "admin"
```

*"Se o usuário editado sou eu mesmo **e** o nível novo não é administrador..."*, então recusa.

Sem essa trava, o **último** administrador poderia se rebaixar por engano, e **ninguém** mais conseguiria administrar o sistema. Como só administradores mudam níveis e nenhum pode rebaixar a si mesmo, sempre sobra pelo menos um.

> 💡 **Manha: pense no pior caso.** Quando uma ação tira poder de alguém, pergunte: *"e se a pessoa fizer isso consigo mesma? E se for a última?"*. Muitos sistemas de verdade já ficaram sem administrador por falta dessa pergunta.

---

## Parte 4 — As telas

### 4.1 A lista

`app/views/admin/users/index.html.erb`:

```erb
<% content_for :title, "Usuários" %>

<h1>Usuários</h1>

<ul class="lista-usuarios" role="list">
  <% @users.each do |user| %>
    <li>
      <strong><%= user.nome %></strong> (<%= user.login %>)<br>
      <span><%= user.email %></span><br>
      <span><%= t("user.roles.#{user.role}") %></span>
      <%= link_to "Alterar nível", edit_admin_user_path(user) %>
    </li>
  <% end %>
</ul>
```

Por que uma **lista** e não uma **tabela**? O foco do projeto é o celular. Numa tela de 320 px, uma tabela com nome, identificador, e-mail e nível estoura para o lado. Cartões empilhados cabem em qualquer largura.

O `role="list"` aciona a regra do `00-reset.css` que tira as bolinhas da lista.

### 4.2 A edição do nível

`app/views/admin/users/edit.html.erb`:

```erb
<% content_for :title, "Nível de acesso" %>

<h1>Nível de acesso de <%= @user.nome %></h1>

<%= form_with model: @user, url: admin_user_path(@user), method: :patch do |f| %>
  <%= render "devise/shared/error_messages", resource: @user %>

  <fieldset>
    <legend>Nível de acesso</legend>
    <% User.roles.each_key do |role| %>
      <label>
        <%= f.radio_button :role, role %>
        <%= t("user.roles.#{role}") %>
      </label>
    <% end %>
  </fieldset>

  <%= f.submit "Salvar" %>
<% end %>

<p><%= link_to "Voltar", admin_users_path %></p>
```

O `User.roles` vem do `enum` do capítulo 0110 e devolve `{ "admin" => 0, "moderador" => 1, "comum" => 2 }`. O `each_key` passa por cada nome. Se um dia surgir um nível novo no `enum`, ele aparece **sozinho** neste formulário.

### 4.3 O link no menu

No layout, dentro do `if user_signed_in?`:

```erb
<% if current_user.admin? %>
  <%= link_to "Usuários", admin_users_path %>
<% end %>
```

> 🕵️ **Pensamento hacker:** esconder o link **não é segurança**. Qualquer pessoa pode digitar `/admin/users` na barra de endereço. Quem protege de verdade é o porteiro da Parte 2. O link escondido é só conforto: não mostrar a ninguém um botão que não vai funcionar.

---

## Parte 5 — Cartões zebrados

Para a lista ficar fácil de ler, cada usuário vira um **cartão**, alternando branco e lilás bem claro, com o creme da página aparecendo entre eles.

Primeiro, uma cor nova nos tokens, em `01-tokens.css`:

```css
--cor-roxo-claro: #f1e9f3;      /* fundo suave: o roxo da marca bem diluído */
```

Depois, um arquivo novo, `30-admin.css`. Seguimos a regra de **um arquivo por assunto**, para que duas pessoas mexendo em telas diferentes não editem o mesmo arquivo:

```css
.lista-usuarios {
  display: grid;
  gap: var(--espaco-1);
  max-width: 40rem;
  padding: 0;
}

.lista-usuarios li {
  padding: var(--espaco-2);
  border-radius: var(--raio);
  line-height: 1.6;
}

.lista-usuarios li:nth-child(odd) {
  background: var(--cor-branco);
}

.lista-usuarios li:nth-child(even) {
  background: var(--cor-roxo-claro);
}
```

| Trecho | O que faz |
| --- | --- |
| `display: grid` + `gap` | Coloca espaço **só entre** os cartões, nunca antes do primeiro nem depois do último. É esse espaço que deixa o creme aparecer |
| `:nth-child(odd)` | Os itens **ímpares** (1º, 3º, 5º...): fundo branco |
| `:nth-child(even)` | Os itens **pares** (2º, 4º, 6º...): fundo lilás |

A zebra se ajusta sozinha quando a lista cresce, sem nenhuma classe a mais no HTML.

Conferimos o contraste da cor nova: o texto roxo sobre o lilás dá **10,8** e o link laranja-escuro dá **5,0**. Os dois passam no mínimo de 4,5 para texto.

---

## Parte 6 — Os testes

Os testes precisam de um administrador. Em `test/fixtures/users.yml`:

```yaml
admin:
  email: admin@exemplo.com
  nome: Admin
  login: admin
  role: admin
  encrypted_password: <%= Devise::Encryptor.digest(User, "senha-segura-123") %>
  confirmed_at: <%= Time.current %>
```

Repare no `role: admin`: nas fixtures, dá para usar o **nome** do enum, e o Rails converte para o número.

`test/controllers/admin/users_controller_test.rb`:

```ruby
require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "usuário comum não entra na administração" do
    sign_in users(:ana)
    get admin_users_url
    assert_redirected_to root_url
  end

  test "administrador vê a lista de usuários" do
    sign_in users(:admin)
    get admin_users_url
    assert_response :success
  end

  test "administrador promove um usuário a moderador" do
    sign_in users(:admin)
    patch admin_user_url(users(:ana)), params: { user: { role: "moderador" } }
    assert users(:ana).reload.moderador?
  end

  test "administrador não remove o próprio acesso" do
    sign_in users(:admin)
    patch admin_user_url(users(:admin)), params: { user: { role: "comum" } }
    assert users(:admin).reload.admin?
  end

  test "usuário comum não se promove pela administração" do
    sign_in users(:ana)
    patch admin_user_url(users(:ana)), params: { user: { role: "admin" } }
    assert users(:ana).reload.comum?
  end
end
```

O arquivo fica em `test/controllers/admin/`, repetindo a pasta do controller. É a mesma organização do namespace.

```bash
bin/rails test
```

---

## Parte 7 — O RuboCop: o revisor de estilo

Antes de cada commit, além dos testes, rodamos:

```bash
bin/rubocop
```

O **RuboCop** lê o código Ruby e aponta o que foge das regras de **estilo** combinadas: espaço dentro dos colchetes (`[ :role ]`), aspas duplas, linhas em branco sobrando no começo de uma classe. Funciona como um corretor ortográfico do código.

| Comando | O que faz |
| --- | --- |
| `bin/rubocop` | Lista os problemas, com arquivo e linha |
| `bin/rubocop -a` | Corrige sozinho o que for seguro corrigir |

As regras são as **"omakase"** do Rails, o estilo oficial da comunidade. *Omakase* é uma palavra japonesa usada em restaurantes: *"deixo o chef escolher"*.

| | Testes | RuboCop |
| --- | --- | --- |
| Pergunta que responde | *O código funciona?* | *O código está escrito no padrão?* |
| Exemplo de problema | O admin conseguiu se rebaixar | Faltou um espaço dentro dos colchetes |

Por que isso importa numa equipe? Com todo mundo escrevendo do mesmo jeito, a revisão de um PR olha para a **lógica**, e não para espaços e aspas.

---

## Parte 8 — Testando no navegador

1. Entre como admin (`admin@territorio.local`). O link **Usuários** aparece no menu.
2. Promova uma conta a moderador e confira no pgAdmin: `role` = 1.
3. Tente rebaixar o próprio admin: aparece a mensagem de recusa.
4. Saia, entre com uma conta comum e digite `localhost:3000/admin/users`: você é barrado.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Namespace** | Um agrupamento de rotas, controllers e views sob um nome, como `admin`. |
| **Herança** | Uma classe que recebe tudo o que outra classe define (`UsersController < BaseController`). |
| **Linter** | Um programa que confere o estilo do código. O RuboCop é o linter do Ruby. |
| **`nth-child`** | Uma regra de CSS que escolhe itens pela posição: ímpares, pares, o terceiro... |

---

## O que aprendemos

- Um **namespace** deixa claro onde fica tudo de uma área do sistema.
- Um controller "porteiro" protege todas as telas de uma vez, inclusive as que ainda vão existir.
- Esconder um link não é segurança: a proteção mora no servidor.
- Toda ação que tira poder precisa da pergunta *"e se for com ele mesmo?"*.
- Testes conferem se funciona; o RuboCop confere se está no padrão.

**Próximo capítulo:** [0160 — Lista de usuários: dados de exemplo, busca e rolagem infinita](0160-busca-e-rolagem-infinita.md)
