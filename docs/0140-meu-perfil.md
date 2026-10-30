# 0140 — Meu perfil: nome, identificador e avatar

> **Neste capítulo:** cada pessoa ganha uma tela **Meu perfil** para editar o nome, o identificador e escolher um **avatar** de uma galeria. Vamos entender por que essa tela tem um controller próprio, separado do Devise, como uma rota no **singular** garante que ninguém edite o perfil de outra pessoa, e como testar telas que exigem login.

**Tag deste capítulo:** `cap-0140`

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
> git switch -c estudo-0140 cap-0140
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
> git branch -D estudo-0140
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

## Parte 1 — Por que um perfil separado do Devise?

O Devise já tem uma tela de edição da conta, em `/users/edit`. Mas ela tem uma regra: para salvar **qualquer** mudança, pede a **senha atual**.

Lembra do capítulo 0130? Quem entra com o Google recebeu uma senha **aleatória**, que ninguém conhece. Essa pessoa nunca conseguiria editar nem o próprio nome.

A solução é dividir:

| Tela | Endereço | O que edita | Pede senha? |
| --- | --- | --- | --- |
| **Meu perfil** (nova) | `/perfil/edit` | Nome, identificador e avatar | Não |
| Conta do Devise | `/users/edit` | E-mail e senha | Sim |

Faz sentido: trocar o **avatar** é uma coisa leve; trocar o **e-mail** ou a **senha** é uma coisa séria, e aí pedir a senha atual protege a conta.

---

## Parte 2 — O avatar

### 2.1 A coluna

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate migration AddAvatarToUsers avatar:string
bin/rails db:migrate
```

A coluna `avatar` guarda só o **nome do arquivo** escolhido, como `avatar-03.svg`. A imagem não vai para o banco.

### 2.2 A galeria é uma pasta

Os avatares ficam em `app/assets/images/avatares/`. Enquanto o time de design não entrega a galeria, existe um avatar provisório, `avatar-00.svg`: um círculo creme com uma silhueta roxa.

> 💡 **Por que avatares em vez de fotos?** Uma foto de rosto é um **dado pessoal** protegido pela LGPD. Com uma galeria de avatares, o sistema não guarda imagem de ninguém.

### 2.3 O model lê a pasta

Em `app/models/user.rb`:

```ruby
def self.avatares_disponiveis
  pasta = Rails.root.join("app/assets/images/avatares")
  return [] unless pasta.directory?

  pasta.children
       .select { |arquivo| arquivo.extname.in?(%w[.svg .png]) }
       .map { |arquivo| arquivo.basename.to_s }
       .sort
end
```

| Trecho | O que faz |
| --- | --- |
| `def self.avatares_disponiveis` | O `self.` faz deste um método **da classe**: chamamos `User.avatares_disponiveis`, sem precisar de um usuário |
| `Rails.root.join(...)` | Monta o caminho completo da pasta, a partir da raiz do projeto |
| `return [] unless pasta.directory?` | Se a pasta não existir, devolve uma lista vazia em vez de quebrar |
| `pasta.children` | Todos os arquivos da pasta |
| `.select { ... .extname.in?(%w[.svg .png]) }` | Só os que terminam em `.svg` ou `.png` |
| `.map { ... .basename.to_s }` | Só o nome do arquivo, sem o caminho |
| `.sort` | Em ordem alfabética |

Quando o time de design entregar avatares novos, basta **colocar os arquivos na pasta**. Nenhuma linha de código muda.

E a validação:

```ruby
validates :avatar, inclusion: { in: ->(_) { User.avatares_disponiveis } }, allow_nil: true
```

- `inclusion: { in: ... }` só aceita valores que estão na lista. Ninguém consegue gravar um nome de arquivo inventado.
- A lista vem de uma **lambda** (`->`), para ser lida na hora da validação, e não uma vez só, quando o Rails liga.
- `allow_nil: true` permite não ter avatar.

---

## Parte 3 — Uma rota no singular

Em `config/routes.rb`:

```ruby
resource :perfil, only: [ :edit, :update ], controller: "perfis"
```

Repare: `resource`, no **singular**, e não `resources`.

| | `resources :users` | `resource :perfil` |
| --- | --- | --- |
| Quantos existem | Muitos: um para cada pessoa | Um só: o **seu** |
| Endereço da edição | `/users/7/edit` | `/perfil/edit` |
| Tem `id` na URL? | Sim | **Não** |

Sem `id` na URL, não existe como pedir o perfil de outra pessoa: o endereço é o mesmo para todo mundo, e cada um vê **o seu**.

> 💡 **Manha: o Rails pensa em inglês.** Para achar o controller, o Rails coloca o nome da rota no plural. Em inglês, "perfil" viraria "perfils". O `controller: "perfis"` diz o nome certo.

---

## Parte 4 — O controller

### O que é um controller?

No restaurante do capítulo 000, o controller é o **garçom**: recebe o pedido, leva à cozinha (o model), busca o prato e entrega na mesa (a view). Ele não cozinha e não decora o prato: **coordena**.

Em termos técnicos, um **controller** é uma **classe Ruby** em `app/controllers/` que herda de `ApplicationController`. Cada **método público** dele é uma **action**: uma das coisas que esse garçom sabe fazer. O roteador (capítulo 0100) decide qual controller e qual action atendem cada pedido.

O ciclo de uma action:

1. **Recebe o pedido**, com os dados que vieram do navegador em `params`.
2. **Conversa com o model**: busca, cria ou altera registros.
3. **Responde** de um destes jeitos:
   - **mostra uma view**: por convenção, a de mesmo nome. A action `edit` do `PerfisController` mostra `app/views/perfis/edit.html.erb` sem que ninguém precise dizer;
   - **redireciona** para outro endereço, com `redirect_to`, normalmente depois de salvar algo.

As variáveis que começam com `@`, como `@user`, são as **variáveis de instância**: é por elas que o controller entrega os dados para a view.

### O controller do perfil

`app/controllers/perfis_controller.rb`:

```ruby
class PerfisController < ApplicationController
  before_action :authenticate_user!

  def edit
    @user = current_user
  end

  def update
    @user = current_user

    if @user.update(perfil_params)
      redirect_to edit_perfil_path, notice: "Perfil atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def perfil_params
    params.expect(user: [ :nome, :login, :avatar ])
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `before_action :authenticate_user!` | Antes de tudo, o Devise confere se há alguém logado. Se não, manda para o login |
| `@user = current_user` | O usuário editado é **sempre** quem está logado. Não existe outra forma de escolher |
| `@user.update(perfil_params)` | Tenta salvar. Responde `true` se deu certo, `false` se alguma validação falhou |
| `redirect_to ... notice:` | Deu certo: volta para o perfil com a mensagem "Perfil atualizado." |
| `render :edit, status: :unprocessable_entity` | Deu errado: mostra o formulário de novo, com os erros. O código 422 avisa o Turbo que houve erro |
| `params.expect(user: [ :nome, :login, :avatar ])` | Os **strong parameters** do capítulo 0110, na forma nova do Rails 8. O `role` não está na lista |

> 💡 **`params.expect` e `params.require(...).permit(...)`** fazem a mesma coisa. O `expect` é a forma nova, do Rails 8, e mais segura com dados malformados. Muitos tutoriais na internet ainda mostram a forma antiga: agora você reconhece as duas.

---

## Parte 5 — A tela

### O que é uma view e o ERB?

Ainda no restaurante, a view é o **prato montado**: a comida que a cozinha preparou, arrumada do jeito certo para chegar à mesa.

Em termos técnicos, uma **view** é um **arquivo de modelo** (*template*) em `app/views/`, que vira o HTML enviado ao navegador. As views do Rails usam o **ERB** (*Embedded Ruby*, Ruby embutido): HTML comum com pedaços de Ruby entre marcadores especiais. A extensão `.html.erb` diz isso: *HTML com ERB*.

| Marcador | Executa o Ruby? | Mostra o resultado no HTML? | Exemplo |
| --- | --- | --- | --- |
| `<%= ... %>` | Sim | **Sim** | `<%= @user.nome %>` escreve o nome na página |
| `<% ... %>` | Sim | Não | `<% if @user.avatar %>`, para decisões e repetições |
| `<%- ... %>` | Sim | Não, e apaga os espaços antes da tag | Só deixa o HTML gerado mais limpo |

Um jeito de lembrar: o `=` quer dizer *"mostre"*. Sem o `=`, o Ruby roda, mas não aparece nada na página.

> 💡 O ERB **escapa** o texto automaticamente: se alguém se cadastrar com o nome `<script>alert('oi')</script>`, a página mostra esse texto como texto, e o navegador não executa nada. Essa proteção, contra um ataque chamado **XSS**, vem de graça em todo `<%= %>`.

### A tela do perfil

`app/views/perfis/edit.html.erb`:

```erb
<% content_for :title, "Meu perfil" %>

<h1>Meu perfil</h1>

<%= form_with model: @user, url: perfil_path, method: :patch do |f| %>
  <%= render "devise/shared/error_messages", resource: @user %>

  <div class="field">
    <%= f.label :nome %>
    <%= f.text_field :nome, autocomplete: "name" %>
  </div>

  <div class="field">
    <%= f.label :login %>
    <%= f.text_field :login, autocomplete: "username" %>
  </div>

  <fieldset class="galeria-avatares">
    <legend>Escolha seu avatar</legend>
    <% User.avatares_disponiveis.each_with_index do |arquivo, i| %>
      <label>
        <%= f.radio_button :avatar, arquivo %>
        <%= image_tag "avatares/#{arquivo}", alt: "Avatar #{i + 1}", width: 64, height: 64 %>
      </label>
    <% end %>
  </fieldset>

  <%= f.submit "Salvar" %>
<% end %>

<p><%= link_to "Trocar e-mail ou senha", edit_user_registration_path %></p>
```

| Trecho | O que faz |
| --- | --- |
| `form_with model: @user, url: perfil_path, method: :patch` | Um formulário para o `@user`, enviado para `/perfil` com o verbo `PATCH` ("altere") |
| `render "devise/shared/error_messages"` | Reaproveita a caixa de erros do Devise |
| `<fieldset>` e `<legend>` | Agrupam os avatares com um título. Leitores de tela anunciam o grupo |
| `f.radio_button :avatar, arquivo` | Um botão de opção para cada avatar: só dá para escolher um |
| `alt: "Avatar #{i + 1}"` | Aqui o `alt` **tem** texto: é ele que diz ao leitor de tela qual opção é qual |

O nome e o identificador **continuam** também na tela do Devise. Quem tem senha pode editá-los lá ou aqui.

---

## Parte 6 — O perfil no menu

No layout, o e-mail deu lugar ao avatar e ao nome, com link para o perfil:

```erb
<%= link_to edit_perfil_path, class: "menu-perfil" do %>
  <% if current_user.avatar %>
    <%= image_tag "avatares/#{current_user.avatar}", alt: "", width: 32, height: 32 %>
  <% end %>
  <span><%= current_user.nome %></span>
<% end %>
```

Aqui o `alt` fica **vazio**: o nome logo ao lado já diz tudo, e o leitor de tela não precisa anunciar "imagem" antes.

---

## Parte 7 — Testando telas que exigem login

### 7.1 Ensinando os testes a fazer login

Os testes de controller precisam **entrar** como alguém. O Devise tem um ajudante para isso, o `sign_in`. Para os testes conhecerem esse ajudante, no **fim** do `test/test_helper.rb`:

```ruby
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
```

> ⚠️ **Manha: fora do `module`.** Esse bloco vai **depois** do `end` do `module ActiveSupport`. Se ficar dentro, o Ruby cria uma classe nova, `ActiveSupport::ActionDispatch::IntegrationTest`, que nenhum teste usa, e o erro é `undefined method 'sign_in'`.

### 7.2 Os testes do perfil

`test/controllers/perfis_controller_test.rb`:

```ruby
require "test_helper"

class PerfisControllerTest < ActionDispatch::IntegrationTest
  test "quem não está logado é mandado para o login" do
    get edit_perfil_url
    assert_redirected_to new_user_session_url
  end

  test "o usuário atualiza o próprio nome e login" do
    sign_in users(:ana)
    patch perfil_url, params: { user: { nome: "Ana Paula", login: "ana-paula" } }
    assert_redirected_to edit_perfil_url
    assert_equal "ana-paula", users(:ana).reload.login
  end

  test "ninguém muda o próprio nível de acesso pelo perfil" do
    sign_in users(:ana)
    patch perfil_url, params: { user: { nome: "Ana", role: "admin" } }
    assert users(:ana).reload.comum?
  end

  test "não dá para editar outro usuário enviando um id" do
    sign_in users(:ana)
    patch perfil_url, params: { id: users(:admin).id, user: { nome: "Hackeado" } }
    assert_equal "Admin", users(:admin).reload.nome
  end
end
```

| Teste | O que garante |
| --- | --- |
| "quem não está logado..." | O `authenticate_user!` funciona |
| "o usuário atualiza..." | O caminho feliz: salvar funciona |
| "ninguém muda o próprio nível..." | Um `role` enviado à mão é **ignorado** |
| "não dá para editar outro usuário..." | Um `id` enviado à mão é **ignorado**: vale sempre o `current_user` |

Os dois últimos testes fazem o papel de quem tenta **burlar** o sistema. É o pensamento hacker do lado de quem defende.

- `get` e `patch` fazem o pedido, como o navegador faria.
- `.reload` busca o usuário **de novo no banco**, para ver o que foi gravado de verdade.

```bash
bin/rails test
```

---

## Parte 8 — Testando no navegador

1. Clique no seu nome no menu: abre **Meu perfil**.
2. Troque o nome, escolha o avatar e salve: aparece "Perfil atualizado." e o avatar surge no menu.
3. Saia e entre com o Google. Edite o perfil: funciona **sem** pedir senha.
4. No pgAdmin: `SELECT nome, login, avatar FROM users;`

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Apagar o **nome** e salvar | Recusar e mostrar a caixa de erros, mantendo o que você digitou |
| Um **identificador que já existe**, como `admin` | Recusar: identificador já em uso |
| Um identificador com **letras maiúsculas**, como `Maria` | Gravar `maria`: é o `normalizes` do capítulo 0120 agindo. Se `maria` já for de outra pessoa, recusar: identificador já em uso |
| Um identificador com **espaço nas pontas**, como ` maria ` | Gravar `maria`, sem os espaços (com a mesma ressalva da linha acima) |
| Um identificador com **espaço no meio** ou **`_`**, como `ana paula` ou `ana_paula` | Recusar: formato inválido |
| Abrir `/perfil/edit` **sem estar logado** | Mandar para a tela de login |

Repare em dois comportamentos diferentes: o que o sistema pode **corrigir sozinho** (maiúsculas, espaços nas pontas), ele corrige; o que ele não tem como adivinhar (um espaço no meio: vira hífen? some?), ele **recusa e explica**, para a pessoa decidir.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Rota no singular** (`resource`) | Uma rota para algo que existe uma vez só por pessoa, sem `id` na URL. |
| **Método de classe** | Um método chamado na classe (`User.avatares_disponiveis`), sem precisar de um registro. |
| **`before_action`** | Algo que o controller faz antes de cada action, como conferir o login. |
| **Código 422** | A resposta "não deu para processar": o formulário tinha erros. |
| **`fieldset` e `legend`** | Tags que agrupam campos de formulário e dão um título ao grupo. |

---

## O que aprendemos

- Ações leves (nome, avatar) e ações sérias (e-mail, senha) podem ter telas e regras diferentes.
- Uma rota **sem `id`** garante, pelo desenho, que cada pessoa só edita o que é seu.
- A galeria de avatares é uma pasta: conteúdo novo, nenhum código novo.
- Avatares em vez de fotos: menos dados pessoais guardados.
- Os testes mais valiosos são os que **tentam burlar** o sistema.

**Próximo capítulo:** [0150 — Administração de usuários](0150-administracao-de-usuarios.md)
