# 0100 — Autenticação com Devise: cadastro, login e confirmação por e-mail

> **Neste capítulo:** o Território Inteligente ganha contas de usuário. Quem chega pode se **cadastrar**, recebe um **e-mail de confirmação**, **entra** e **sai** do sistema, e pode **recuperar a senha**. Vamos ver como a gem **Devise** faz isso, o que ela cria no projeto e algumas armadilhas que encontramos pelo caminho.

**Tag deste capítulo:** `cap-0100`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bundle install
bin/rails db:migrate
```

- `git pull` traz os commits novos do GitHub.
- `bundle install` instala as gems novas que entraram no `Gemfile`.
- `bin/rails db:migrate` roda as **migrations** novas: é assim que a tabela `users` aparece no seu banco.

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
> git switch -c estudo-0100 cap-0100
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
> git branch -D estudo-0100
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

## Parte 1 — Por que usar uma gem para autenticação?

Autenticação parece simples: um formulário com e-mail e senha. Mas um sistema sério precisa de muito mais:

- guardar a senha de um jeito que **nem nós** consigamos ler;
- confirmar que o e-mail existe e é de quem se cadastrou;
- recuperar a senha esquecida sem expor a conta;
- lembrar quem já entrou, sem pedir a senha a cada página;
- resistir a quem tenta adivinhar senhas.

Cada item desses tem armadilhas de segurança. O **Devise** é uma gem usada há mais de 15 anos por milhares de projetos Rails, que já resolveu e testou tudo isso. Usar o Devise é seguir a ideia do capítulo 000: não reinventar o encanamento da casa.

### Os módulos do Devise

O Devise é dividido em **módulos**, e cada projeto liga os que precisa. Os nossos estão na linha `devise` do arquivo `app/models/user.rb`:

| Módulo | O que faz |
| --- | --- |
| `database_authenticatable` | Guarda a senha criptografada no banco e confere no login |
| `registerable` | Permite que a pessoa se cadastre, edite e apague a própria conta |
| `recoverable` | "Esqueci minha senha": manda um link para criar outra |
| `rememberable` | A caixinha "Lembrar-me" |
| `validatable` | Confere se o e-mail tem formato válido e se a senha tem o tamanho mínimo |
| `confirmable` | Só deixa entrar depois de clicar no link de confirmação enviado por e-mail |

---

## Parte 2 — As gems

### O que são gems?

Uma **gem** é um pacote de código Ruby pronto, escrito por outra pessoa, que você acrescenta ao seu projeto para não ter de escrever tudo do zero. Em outras linguagens, a mesma ideia tem outros nomes: **biblioteca** ou **pacote**.

Pense numa caixa de ferramentas. Para pendurar um quadro, você não fabrica um martelo: pega um pronto. As gems são as ferramentas prontas do mundo Ruby:

| Gem | Problema que resolve |
| --- | --- |
| `devise` | Cadastro, login, senha e confirmação por e-mail |
| `pagy` | Dividir uma lista grande em páginas |
| `faker` | Gerar nomes e dados falsos para testes |
| `rails` | O próprio Rails também é uma gem! |

Algumas coisas que vale saber sobre as gems:

- **Quase todas são código aberto.** Qualquer pessoa pode ler, estudar e melhorar o código delas. O Devise, por exemplo, está no GitHub, e você pode ler cada linha.
- **Elas moram no RubyGems** (https://rubygems.org), um grande catálogo público com mais de 180 mil gems. É de lá que elas são baixadas.
- **Uma gem pode depender de outras.** O Devise usa outras gems por dentro, como a `bcrypt`, que criptografa as senhas. Quando você instala o Devise, essas vêm junto.
- **Cada gem tem versões.** Uma gem é atualizada com o tempo, e às vezes a versão nova muda a forma de usar. Por isso é importante que toda a equipe use **a mesma versão**, e é aí que entra o `bundle`.

> 🕵️ **Pensamento hacker:** acrescentar uma gem é **confiar** no código de outra pessoa, que vai rodar dentro do seu sistema. Antes de adicionar uma gem, vale perguntar: *ela é conhecida e usada por muita gente? É atualizada com frequência? Eu realmente preciso dela?* O comando `bin/bundler-audit`, que o projeto já tem, confere se alguma das nossas gems tem uma falha de segurança conhecida.

### O que é o `bundle`?

O `bundle` é o comando do **Bundler**, o gerenciador de gems do projeto. Lembra do `apt`, que instala programas no sistema (capítulo 020)? O Bundler faz o mesmo papel, mas para as **bibliotecas Ruby de um projeto**.

Ele trabalha com dois arquivos:

| Arquivo | O que guarda | Quem escreve |
| --- | --- | --- |
| `Gemfile` | A **lista de compras**: quais gems o projeto usa | Nós, ou o `bundle add` |
| `Gemfile.lock` | A **nota fiscal**: a versão exata de cada gem instalada, e das gems que elas usam | O Bundler, sozinho. Nunca editamos à mão |

O `Gemfile.lock` é o que garante que **todo mundo da equipe** usa exatamente as mesmas versões. Foi ele que o `bin/setup` leu no capítulo 030 para instalar o Rails na versão certa.

Os comandos que mais vamos usar:

| Comando | O que faz |
| --- | --- |
| `bundle add nome-da-gem` | Acrescenta a gem no `Gemfile`, instala e atualiza o `Gemfile.lock` |
| `bundle install` | Instala tudo o que está no `Gemfile.lock`. É o que você roda depois de um `git pull` que trouxe gems novas |
| `bundle remove nome-da-gem` | Tira a gem do `Gemfile` |

### As gems deste capítulo

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bundle add devise rails-i18n devise-i18n
bundle add letter_opener_web --group development
```

| Gem | Para quê |
| --- | --- |
| `devise` | A autenticação |
| `rails-i18n` | Traduz para o português o que é **do Rails**: mensagens de validação, datas, números, moeda |
| `devise-i18n` | Traduz as telas e os e-mails do Devise |
| `letter_opener_web` | Em desenvolvimento, **não envia e-mail de verdade**: guarda numa caixa de entrada que abrimos no navegador |

O `--group development` coloca a gem só no ambiente de desenvolvimento. No servidor de produção, ela nem é instalada.

---

## Parte 3 — Instalando o Devise

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate devise:install
```

Esse comando cria o arquivo de configuração `config/initializers/devise.rb` e mostra uma lista de tarefas. Fizemos as seguintes:

### 3.1 E-mails em desenvolvimento

Em `config/environments/development.rb`:

```ruby
config.action_mailer.default_url_options = { host: "localhost", port: 3000 }
config.action_mailer.delivery_method = :letter_opener_web
config.action_mailer.perform_deliveries = true
```

- `default_url_options`: os links dentro dos e-mails (como o de confirmação) precisam do endereço completo. Em desenvolvimento, é `localhost:3000`.
- `delivery_method = :letter_opener_web`: os e-mails vão para a caixa de entrada de teste.
- `perform_deliveries = true`: liga o envio.

### 3.2 Português e horário de Brasília

Em `config/application.rb`:

```ruby
config.i18n.default_locale = :"pt-BR"
config.time_zone = "Brasilia"
```

### 3.3 Configurações do Devise

Em `config/initializers/devise.rb`, conferimos e ajustamos estas linhas:

```ruby
config.mailer_sender = "nao_responda@candeeiro.org.br"
config.parent_mailer = "ApplicationMailer"
config.responder.error_status = :unprocessable_entity
config.responder.redirect_status = :see_other
```

- `mailer_sender`: o remetente dos e-mails do sistema.
- `parent_mailer`: veja a **Manha 2**, mais abaixo.
- `responder`: os códigos de resposta que o **Turbo** (a parte do Rails que deixa as páginas rápidas) espera. Com eles, um formulário com erro mostra as mensagens na tela, em vez de não fazer nada.

> 💡 **Manha 1: arquivos em `config/initializers` só valem depois de reiniciar.**
> O Rails lê esses arquivos **uma única vez**, quando o servidor liga. Mudou algo lá? Desligue o servidor (Ctrl+C) e ligue de novo (`bin/dev`). Mudanças em models, controllers e views valem na hora; em initializers, não.

---

## Parte 4 — A página inicial

O Devise precisa saber para onde mandar a pessoa depois do login. Por isso, criamos uma página inicial:

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate controller Paginas inicio
```

### O que é o `config/routes.rb`?

Lembra do restaurante do capítulo 000? Antes de o garçom (o controller) atender, alguém precisa saber **qual garçom** cuida de cada pedido. No Rails, quem faz isso é o arquivo `config/routes.rb`: ele é o **cardápio** do sistema.

#### O caminho de uma requisição

Agora, o mesmo caminho em termos técnicos. Quando você digita um endereço no navegador, ele envia uma **requisição HTTP** ao servidor: um pedido com um **verbo** (como `GET`) e um **caminho** (como `/users/sign_in`). Essa requisição passa por várias camadas até virar uma página:

1. **Proxy reverso** (só em produção). No servidor de verdade, quem recebe a requisição primeiro é um programa como o **Nginx**, o **Apache** ou o **kamal-proxy** (o que vem com o Rails 8). Ele cuida do HTTPS, entrega arquivos estáticos e repassa o resto para a aplicação. Em desenvolvimento, essa camada não existe.
2. **Servidor de aplicação: o Puma.** É o programa que o `bin/dev` liga e que fica escutando na porta 3000. O Puma recebe a requisição e a entrega ao Rails.
3. **Middlewares.** Antes de chegar às rotas, a requisição passa por uma fila de pequenos filtros do Rails, os *middlewares*: um lê os cookies, outro confere a proteção contra formulários falsos (CSRF), outro registra o pedido no log.
4. **O roteador.** O roteador do Rails compara o verbo e o caminho com as regras do `config/routes.rb` e descobre **qual controller e qual action** devem atender.
5. **Controller e action.** A action conversa com o model, se precisar, e escolhe a view.
6. **A resposta.** A view vira HTML, e a resposta faz o caminho de volta, pelas mesmas camadas, até o navegador.

O `routes.rb` não "recebe" a requisição sozinho: ele é a **configuração** do roteador, a tabela que o roteador consulta no passo 4.

> 💡 Quer ver esse caminho acontecendo? Com o `bin/dev` ligado, abra uma página e olhe o terminal. Cada requisição aparece no log com o verbo e o caminho (`Started GET "/"`), o controller e a action que atenderam (`Processing by PaginasController#inicio`) e o resultado (`Completed 200 OK`).

#### As regras do cardápio

Cada linha desse arquivo é uma **rota**, uma regra que liga um **endereço** a quem vai atendê-lo:

```ruby
get "up" => "rails/health#show"
```

| Parte | Significado |
| --- | --- |
| `get` | O **verbo** do pedido. `GET` é "me mostre" (a Parte 7 explica os outros verbos) |
| `"up"` | O **endereço**: `http://localhost:3000/up` |
| `"rails/health#show"` | **Quem atende**: o controller `Rails::HealthController`, na action `show` |

O `#` separa o **controller** da **action**. Uma action é um método do controller: cada coisa que o garçom sabe fazer.

Quando um pedido chega, o Rails lê o `routes.rb` **de cima para baixo** e usa a **primeira** rota que combinar com o endereço e o verbo. Se nenhuma combinar, aparece o erro *Routing Error: No route matches*.

> 💡 **Manha: veja todas as rotas do sistema.** No terminal, na pasta do projeto:
> ```bash
> bin/rails routes
> ```
> Ou, com o servidor ligado, abra **http://localhost:3000/rails/info/routes**: uma tabela com todas as rotas, só em desenvolvimento.

### A raiz do site

No `config/routes.rb`, dissemos que a página inicial é a **raiz** do site, o endereço `/`:

```ruby
root "paginas#inicio"
```

Leia `paginas#inicio` como: *"controller `Paginas`, action `inicio`"*. O pedido chega em `/`, e o `PaginasController` atende com o método `inicio`, que mostra a view `app/views/paginas/inicio.html.erb`.

Repare como o Rails segue convenções: a rota diz `paginas#inicio`, e o Rails sabe sozinho que o controller está em `app/controllers/paginas_controller.rb` e a view em `app/views/paginas/inicio.html.erb`. Ninguém precisa configurar isso: é a **convenção sobre configuração** do capítulo 000.

> 💡 **Manha 3: o gerador cria mais coisas do que você pediu.**
> Esse comando criou também uma rota `get "paginas/inicio"` e um **teste** em `test/controllers/paginas_controller_test.rb`. Como preferimos usar só a `root`, apagamos a rota extra, e o teste quebrou, porque procurava por ela. Corrigimos o teste no capítulo 0120.
> **Regra de ouro:** depois de qualquer `bin/rails generate`, rode `git status` e veja **tudo** o que apareceu.

---

## Parte 5 — O model `User`

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate devise User
```

Esse comando criou:

- o model `app/models/user.rb`;
- uma **migration** em `db/migrate/`, que cria a tabela `users`;
- a linha `devise_for :users` em `config/routes.rb`, que cria todas as rotas de autenticação.

### O que é um model?

No restaurante do capítulo 000, o model é a **cozinha com a despensa**: guarda os ingredientes, sabe onde cada coisa está e confere se o que vai para o prato está bom. O garçom (o controller) nunca entra na despensa: ele **pede** à cozinha.

Em termos técnicos, um **model** é uma **classe Ruby** que representa uma **tabela do banco de dados**. No Rails, os models herdam de `ApplicationRecord`, que por sua vez usa o **Active Record**, a parte do Rails que conversa com o banco.

```ruby
class User < ApplicationRecord
end
```

Só com essas duas linhas, o Rails já sabe muita coisa, pela **convenção sobre configuração**:

| Convenção | Exemplo |
| --- | --- |
| A classe `User` (singular) corresponde à tabela `users` (plural) | `User` ↔ `users` |
| Cada **linha** da tabela vira um **objeto** da classe | O usuário de `id` 7 é um objeto `User` |
| Cada **coluna** da tabela vira um **atributo** do objeto | A coluna `email` vira `user.email` |

O Active Record traduz Ruby em SQL. Você escreve Ruby, e o Rails monta a consulta:

| Em Ruby | O SQL que o Rails executa |
| --- | --- |
| `User.count` | `SELECT COUNT(*) FROM users` |
| `User.find(7)` | `SELECT * FROM users WHERE id = 7 LIMIT 1` |
| `User.where(role: :admin)` | `SELECT * FROM users WHERE role = 0` |
| `user.update(nome: "Ana")` | `UPDATE users SET nome = 'Ana' WHERE id = 7` |

Esse tipo de tradução entre objetos e tabelas se chama **ORM** (*Object-Relational Mapping*, mapeamento objeto-relacional). O SQL do 1º trimestre continua lá por baixo: o Active Record só escreve por você. Repare no log do `bin/dev`: cada consulta aparece em SQL.

Além de buscar e guardar dados, o model é o lugar das **regras** sobre eles:

- **Validações:** o que um registro precisa ter para ser salvo, como e-mail obrigatório e senha com tamanho mínimo.
- **Associações:** como as tabelas se ligam. Por exemplo, uma academia *tem muitos* equipamentos. Vamos ver isso mais adiante.
- **Callbacks:** o que fazer em certos momentos, como gerar o identificador antes de salvar (capítulo 0120).

Por isso a regra do MVC: **regra de dados mora no model**. Se amanhã surgir a regra *"todo usuário precisa ter nome"*, ela entra no `User`, e vale para o cadastro, para o login com o Google, para o console e para os testes, de uma vez só.

### 5.1 Ligando a confirmação por e-mail

Antes de rodar a migration, abrimos o arquivo dela e **tiramos o comentário** do bloco `## Confirmable`:

```ruby
## Confirmable
t.string   :confirmation_token
t.datetime :confirmed_at
t.datetime :confirmation_sent_at
t.string   :unconfirmed_email
```

E também do índice, no fim do arquivo:

```ruby
add_index :users, :confirmation_token, unique: true
```

| Coluna | O que guarda |
| --- | --- |
| `confirmation_token` | Um código secreto e único que vai no link do e-mail |
| `confirmed_at` | Quando a pessoa clicou no link. Enquanto estiver vazio, ela não entra |
| `confirmation_sent_at` | Quando o e-mail foi enviado |
| `unconfirmed_email` | O e-mail novo, quando alguém troca e ainda não confirmou |

No model, acrescentamos `:confirmable` na linha do `devise`. Depois:

```bash
bin/rails db:migrate
```

### 5.2 Onde está a senha?

Abra a tabela `users` no pgAdmin (capítulo 035). Não existe uma coluna `password`! Existe a `encrypted_password`, com algo assim:

```
$2a$12$E.RNekrkP89ixh9WprtJG.W5CpFm9GoYTwcrbOxA7flz4wNR3bWH6
```

Isso é um **hash** feito com o algoritmo **bcrypt**. Um hash é uma "impressão digital" da senha: dá para conferir se a senha digitada no login gera a mesma impressão, mas **não dá para voltar** do hash para a senha. Se alguém roubar o banco, não leva as senhas.

O `$12$` no começo é o **custo**: quanto trabalho o computador faz para gerar o hash. É de propósito: para nós, demora uma fração de segundo; para quem tenta adivinhar milhões de senhas, demora anos.

Repare também no log do servidor, no momento do cadastro:

```
Parameters: {"user" => {"email" => "[FILTERED]", "password" => "[FILTERED]", ...}}
```

O Rails **esconde** a senha até dos próprios logs.

### 5.3 As rotas que o Devise criou

```bash
bin/rails routes | grep users
```

| Endereço | Para quê |
| --- | --- |
| `/users/sign_up` | Cadastro |
| `/users/sign_in` | Entrar |
| `/users/sign_out` | Sair (com o verbo `DELETE`) |
| `/users/password/new` | Esqueci minha senha |
| `/users/confirmation` | O link do e-mail de confirmação |
| `/users/edit` | Editar a própria conta |

Tudo isso saiu de **uma linha**: `devise_for :users`.

---

## Parte 6 — Telas em português

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate devise:i18n:views
```

Esse comando copia as telas do Devise para `app/views/devise/`, já preparadas para tradução. Agora elas fazem parte do **nosso** projeto: o time de design pode mexer nelas como em qualquer outra view.

---

## Parte 7 — O layout

O layout é a "moldura" de todas as páginas: `app/views/layouts/application.html.erb`.

```erb
<html lang="pt-BR">
```

O `lang="pt-BR"` avisa ao navegador e aos leitores de tela que a página está em português.

```erb
<body>
  <nav>
    <% if user_signed_in? %>
      <span><%= current_user.email %></span>
      <%= button_to "Sair", destroy_user_session_path, method: :delete %>
    <% else %>
      <%= link_to "Entrar", new_user_session_path %>
      <%= link_to "Cadastrar", new_user_registration_path %>
    <% end %>
  </nav>

  <main>
    <p class="notice"><%= notice %></p>
    <p class="alert"><%= alert %></p>

    <%= yield %>
  </main>
</body>
```

| Trecho | O que faz |
| --- | --- |
| `user_signed_in?` | Pergunta do Devise: tem alguém logado? |
| `current_user` | O usuário logado |
| `button_to "Sair", ..., method: :delete` | Sair é um **botão**, não um link. Veja abaixo |
| `notice` e `alert` | As mensagens de aviso, como "Uma mensagem com um link de confirmação foi enviada" |
| `yield` | O lugar onde entra o conteúdo de cada página |

### Por que "Sair" é um botão?

Na web, cada pedido tem um **verbo**:

| Verbo | Significado | Exemplo |
| --- | --- | --- |
| `GET` | "Me mostre" | Abrir uma página |
| `POST` | "Crie" | Enviar o cadastro |
| `PATCH` | "Altere" | Salvar a edição da conta |
| `DELETE` | "Apague" | **Sair** (apaga a sessão) |

Links só fazem `GET`. Um `GET` nunca deve **mudar** nada: navegadores e robôs de busca abrem links por conta própria. Se "Sair" fosse um link, um programa poderia deslogar você só de passar pela página. Por isso, ações que mudam algo usam botão.

---

## Parte 8 — A caixa de entrada de testes

Em desenvolvimento, o sistema **não envia e-mails de verdade**. Quem cuida deles é o `letter_opener_web`: ele pega cada e-mail que o Rails tentaria enviar e guarda numa caixa de entrada de testes, que abrimos no navegador. Assim podemos cadastrar `teste@mail.com`, `ana@exemplo.com` ou qualquer endereço inventado, sem encher a caixa de ninguém e sem depender de internet.

> ⚠️ **Quando o site for para o ar, isso muda.** No servidor de produção, a aplicação precisa enviar e-mails **reais**, senão ninguém recebe o link de confirmação e não consegue entrar. Para isso, vamos configurar um **servidor de envio de e-mails** (SMTP) no arquivo `config/environments/production.rb`, com endereço, usuário e senha guardados nas credentials. Esse será um capítulo próprio, junto com a publicação do site.

Para ligar a caixa de entrada, em `config/routes.rb`:

```ruby
if Rails.env.development?
  mount LetterOpenerWeb::Engine, at: "/letter_opener"
end
```

Agora, todo e-mail que o sistema envia aparece em **http://localhost:3000/letter_opener**. O `if` garante que essa caixa de entrada **não existe** no servidor de produção: lá, ela mostraria os e-mails de todo mundo.

> 💡 **Manha 4: o ponto de interrogação faz parte do nome.**
> Em Ruby, métodos que **respondem sim ou não** terminam em `?`: `development?`, `user_signed_in?`, `empty?`. O `?` não é enfeite, é parte do nome. Sem ele, o Ruby procura outro método, que não existe, e o servidor mostra um erro como:
> ```
> NoMethodError (undefined method 'development' ...)
> ```

---

## Parte 9 — O e-mail com a cara do projeto

O arquivo `app/views/layouts/mailer.html.erb` é a moldura de **todos** os e-mails, como o `application.html.erb` é das páginas. Colocamos nele um cabeçalho com o nome do projeto, as cores da marca e um rodapé.

> 💡 **Manha 2: o Devise não usava o nosso layout de e-mail.**
> Depois de criar o layout, o e-mail de confirmação continuou chegando sem ele. O motivo: o layout é declarado na classe `ApplicationMailer`, mas o mailer do Devise **não herdava** dela. Ele herdava direto do `ActionMailer::Base`.
> É como um controller que herdasse de `ActionController::Base` em vez do `ApplicationController`: perderia tudo o que a aplicação define para todos.
> A correção foi uma linha no `config/initializers/devise.rb`:
> ```ruby
> config.parent_mailer = "ApplicationMailer"
> ```
> E, como é um initializer, foi preciso reiniciar o servidor (Manha 1).

> 💡 **Manha 5: e-mail é um mundo à parte.**
> Repare que o layout do e-mail tem os estilos **dentro das tags** (`style="..."`), as cores escritas direto e a fonte Arial. Os programas de e-mail, como Gmail e Outlook, ignoram arquivos CSS externos e boa parte do CSS moderno. As variáveis do `01-tokens.css` não funcionam lá. Em e-mail, o HTML parou nos anos 2000.

---

## Parte 10 — O primeiro visual

### O que é CSS?

Uma página web é feita de três camadas, cada uma com uma linguagem:

| Camada | Linguagem | Comparação com uma casa |
| --- | --- | --- |
| **Estrutura** | HTML | As paredes, as portas, os cômodos |
| **Aparência** | **CSS** | A pintura, os móveis, a iluminação |
| **Comportamento** | JavaScript | A campainha, o interruptor, a porta automática |

O **CSS** (*Cascading Style Sheets*, folhas de estilo em cascata) diz **como** cada parte do HTML aparece: cores, fontes, tamanhos, espaços, posição na tela e como a página se adapta ao celular. Uma regra de CSS tem um **seletor** (a quem a regra vale) e as **declarações** (o que muda):

```css
h1 {
  color: purple;
  font-size: 2rem;
}
```

*"Todo título `h1` fica roxo e com tamanho 2rem."* O "cascata" do nome quer dizer que várias regras podem valer para o mesmo elemento, e o navegador tem uma ordem para decidir qual vence. É por isso que a **ordem dos arquivos** importa, como vamos ver abaixo.

#### CSS puro ou framework?

Muitos projetos modernos não escrevem as folhas de estilo à mão. Usam um **framework de CSS**, um conjunto de estilos prontos que se aplica direto no HTML:

- **Tailwind CSS**: em vez de criar regras, você monta a aparência com classes pequenas no próprio HTML, como `<h1 class="text-purple-800 text-2xl">`. É um framework **utilitário**.
- **Bootstrap**: traz componentes prontos (botões, menus, cartões) com aparência padrão.

Esses frameworks **não substituem o CSS**: eles geram CSS por você. No fim, o navegador sempre recebe CSS.

Neste projeto escolhemos **CSS puro**, escrito à mão, por três motivos:

- **Aprender a base.** Quem entende CSS aprende qualquer framework depois. O contrário não funciona.
- **Nada no meio.** Você edita o arquivo, recarrega a página e vê o resultado, sem nenhuma ferramenta de compilação rodando.
- **O CSS moderno ficou poderoso.** Variáveis, aninhamento e layouts com `grid` e `flex` já vêm no próprio CSS, sem precisar de ferramentas extras.

#### Os arquivos de estilo do projeto

Junto com a autenticação, o projeto ganhou um CSS inicial, em `app/assets/stylesheets/`:

| Arquivo | O que faz |
| --- | --- |
| `00-reset.css` | Zera as diferenças entre navegadores |
| `01-tokens.css` | As cores, fontes e espaçamentos do projeto, com nome (`--cor-roxo`, `--espaco-2`) |
| `02-fontes.css` | As fontes Baloo 2 e Open Sans, hospedadas no próprio projeto |
| `10-base.css` | A aparência padrão das páginas, do menu, das mensagens e dos formulários |

Os números na frente dos nomes **definem a ordem**: o Rails carrega os arquivos dessa pasta em ordem alfabética, e o reset precisa vir primeiro.

O foco do Território Inteligente é o **celular**. Teste sempre com o DevTools (F12) no modo de dispositivo móvel, com 320 px de largura.

---

## Parte 11 — Testando o fluxo completo

1. Ligue o servidor: `bin/dev`.
2. Clique em **Cadastrar** e preencha o formulário.
3. Abra **http://localhost:3000/letter_opener** e clique no e-mail de confirmação.
4. Clique em **Confirmar minha conta**.
5. Clique em **Entrar** e faça o login.
6. Teste o **Sair**.
7. Teste o **Esqueci minha senha**: o e-mail também chega no `letter_opener`.
8. Crie **mais contas de teste**, com e-mails inventados como `fulano@exemplo.com` e `beltrana@exemplo.com`.
9. Agora, **tente quebrar o cadastro**. Faça de propósito os erros que um usuário faria e anote o que o sistema responde:

| Tente | O que o sistema deve fazer |
| --- | --- |
| Enviar o formulário **todo em branco** | Recusar e dizer quais campos faltam |
| Um e-mail **sem `@`**, como `fulano.exemplo.com` | Recusar: e-mail inválido |
| Uma senha **curta**, com 3 letras | Recusar: senha curta demais |
| A **confirmação** da senha diferente da senha | Recusar: as senhas não conferem |
| Um e-mail **que já está cadastrado** | Recusar: e-mail já em uso |
| **Entrar** com a senha errada | Recusar sem dizer se o erro foi no e-mail ou na senha |

> 💡 **Use domínios `exemplo.com` nos testes.** Domínios como `mail.com` ou `email.com` existem de verdade e têm donos. O `exemplo.com` (e o `example.com`, em inglês) é reservado justamente para exemplos: nenhum e-mail de teste vai parar na caixa de alguém.

Encontrou algum caso em que o sistema **aceitou** o que deveria recusar? Ótimo: é um **bug**. Anote o passo a passo e avise o educador. Encontrar falhas antes do usuário é uma das tarefas mais valiosas de quem desenvolve.

### Prevendo os erros do usuário

Todo usuário erra: esquece um campo, digita o e-mail errado, escolhe uma senha curta. Um bom sistema **prevê** esses erros e faz duas coisas: **impede** que dados errados sejam gravados e **explica** o que corrigir, sem perder o que a pessoa já tinha digitado.

No Rails, isso acontece em três etapas, uma em cada camada do MVC:

**1. O model confere: as validações.** As regras ficam no model. O módulo `validatable` do Devise já traz as do `User`: e-mail obrigatório, com formato válido e sem repetir, e senha com pelo menos 6 caracteres. Quando uma regra falha, o Rails **não grava** e anota o motivo numa lista de erros do objeto, o `errors`.

**2. O controller decide: salvou ou não?** Se a gravação falhou, o controller não segue em frente: mostra o formulário de novo, com o código de resposta **422** (*"não deu para processar"*), e o objeto continua com os dados digitados e a lista de erros.

**3. A view mostra: a caixa de erros.** No formulário de cadastro (`app/views/devise/registrations/new.html.erb`), esta linha exibe os erros:

```erb
<%= render "devise/shared/error_messages", resource: resource %>
```

Ela desenha o **partial** `app/views/devise/shared/_error_messages.html.erb`, que funciona mais ou menos assim:

```erb
<% if resource.errors.any? %>
  <div id="error_explanation">
    <ul>
      <% resource.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  </div>
<% end %>
```

| Trecho | O que faz |
| --- | --- |
| `resource` | O usuário que o formulário tentou gravar. É o nome que o Devise usa |
| `errors.any?` | *"Houve algum erro?"* Se não houve, a caixa nem aparece |
| `errors.full_messages` | A lista de mensagens prontas, já em português pela gem `rails-i18n`, como *"E-mail não pode ficar em branco"* |
| `.each do \|message\|` | Mostra cada mensagem como um item da lista |

E tem mais um detalhe que o Rails faz sozinho: **cada campo com erro** ganha em volta uma `<div class="field_with_errors">`. Com uma regra de CSS para essa classe, dá para pintar de vermelho a borda dos campos que precisam de correção. É uma boa tarefa para o time de design.

> 💡 **Manha: por que o login não diz se o erro foi no e-mail ou na senha?** Se o sistema dissesse *"este e-mail não está cadastrado"*, qualquer pessoa poderia descobrir quem tem conta, testando e-mails um por um. Por isso a mensagem é sempre a mesma: *"E-mail ou senha inválidos"*. Ser vago aqui é **de propósito**: é segurança.

No pgAdmin, confira:

```sql
SELECT email, confirmed_at FROM users;
SELECT * FROM schema_migrations;
```

Lembra do capítulo 035, quando a `schema_migrations` estava vazia? Agora ela tem uma linha: a migration que criou a tabela `users`.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Autenticação** | Conferir quem é a pessoa: o login. |
| **Gem** | Uma biblioteca Ruby. O Devise é uma gem. |
| **Initializer** | Arquivo de configuração lido uma vez, quando o Rails liga. |
| **Migration** | Arquivo que muda a estrutura do banco de forma registrada. |
| **Hash** | Uma "impressão digital" que não pode ser desfeita. É assim que a senha é guardada. |
| **bcrypt** | O algoritmo que gera o hash das senhas. |
| **Token** | Um código secreto e único, como o do link de confirmação. |
| **Verbo HTTP** | O tipo de pedido feito ao servidor: `GET`, `POST`, `PATCH`, `DELETE`. |
| **Layout** | A moldura comum a todas as páginas (ou a todos os e-mails). |

---

## O que aprendemos

- Autenticação tem muitas armadilhas de segurança, e o **Devise** já resolveu todas.
- A senha **nunca** é guardada: guardamos o **hash** dela.
- Initializers só valem **depois de reiniciar** o servidor.
- Geradores criam **mais arquivos** do que parece: confira com `git status`.
- O `?` faz parte do nome dos métodos que respondem sim ou não.
- Ações que mudam algo usam **botão** e o verbo certo; links são só para `GET`.
- E-mail tem regras próprias de HTML e CSS.

**Próximo capítulo:** [0110 — Níveis de acesso](0110-niveis-de-acesso.md)
