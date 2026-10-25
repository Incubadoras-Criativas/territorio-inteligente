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

Quer ver o projeto **exatamente** como ele estava ao final deste capítulo? Use a tag:

```bash
git checkout cap-0100
```

O git vai avisar que você está em *detached HEAD*: é como visitar uma foto antiga do projeto. Dá para olhar e rodar, mas não para trabalhar ali. Para voltar ao presente: `git switch main`.

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
bin/rails generate controller Paginas inicio
```

E, em `config/routes.rb`, dissemos que ela é a **raiz** do site (o endereço `/`):

```ruby
root "paginas#inicio"
```

Leia `paginas#inicio` como: *"controller `Paginas`, action `inicio`"*. É o garçom do capítulo 000: o pedido chega em `/`, e o `PaginasController` atende.

> 💡 **Manha 3: o gerador cria mais coisas do que você pediu.**
> Esse comando criou também uma rota `get "paginas/inicio"` e um **teste** em `test/controllers/paginas_controller_test.rb`. Como preferimos usar só a `root`, apagamos a rota extra, e o teste quebrou, porque procurava por ela. Corrigimos o teste no capítulo 0120.
> **Regra de ouro:** depois de qualquer `bin/rails generate`, rode `git status` e veja **tudo** o que apareceu.

---

## Parte 5 — O model `User`

```bash
bin/rails generate devise User
```

Esse comando criou:

- o model `app/models/user.rb`;
- uma **migration** em `db/migrate/`, que cria a tabela `users`;
- a linha `devise_for :users` em `config/routes.rb`, que cria todas as rotas de autenticação.

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
