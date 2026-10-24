# 0120 — Perfil: nome e identificador

> **Neste capítulo:** cada usuário ganha um **nome** e um **identificador** único, como `maria` ou `maria-2`, gerado automaticamente a partir do primeiro nome. Vamos escrever uma migration para um banco **que já tem dados**, entender linha a linha o código que gera o identificador, criar o primeiro **administrador** e escrever os primeiros **testes automáticos** do projeto.

**Tag deste capítulo:** `cap-0120`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails db:migrate
bin/rails db:seed
bin/rails test
```

- `db:seed` cria o administrador de desenvolvimento (Parte 7).
- `test` roda os testes automáticos (Parte 8). Devem passar todos.

---

## Parte 1 — O que vamos guardar

| Campo | Exemplo | Quem preenche |
| --- | --- | --- |
| `nome` | Maria da Silva | A pessoa, no cadastro |
| `login` | `maria` | O sistema, automaticamente. A pessoa pode mudar depois |

O **identificador** (`login`) aparece em público, por exemplo, ao lado das fichas que a pessoa enviar. Por isso ele é gerado só com o **primeiro nome**: o nome completo fica guardado, mas não exposto. É o mesmo cuidado do tutorial 010, quando escolhemos o nome de usuário do GitHub.

---

## Parte 2 — Uma migration para um banco com dados

```bash
bin/rails generate migration AddNomeAndLoginToUsers
```

Aqui tem um problema novo. Queremos que `nome` e `login` sejam **obrigatórios** (`null: false`). Mas o banco **já tem** usuários, cadastrados nos testes do capítulo 0100, sem nome e sem login. Se criássemos as colunas já obrigatórias, o PostgreSQL recusaria: *"essas linhas ficariam vazias!"*.

A solução é fazer em três passos:

```ruby
def up
  add_column :users, :nome, :string
  add_column :users, :login, :string

  # Usuários que já existem ganham valores provisórios
  execute <<~SQL
    UPDATE users
       SET nome  = split_part(email, '@', 1),
           login = 'usuario-' || id
  SQL

  change_column_null :users, :nome, false
  change_column_null :users, :login, false
  add_index :users, "lower(login)", unique: true
end

def down
  remove_column :users, :login
  remove_column :users, :nome
end
```

| Passo | Trecho | O que faz |
| --- | --- | --- |
| 1 | `add_column` | Cria as duas colunas, por enquanto **podendo** ficar vazias |
| 2 | `execute <<~SQL ... SQL` | Roda **SQL puro** para preencher quem já existe |
| 3 | `change_column_null ..., false` | Agora que ninguém está vazio, torna as colunas obrigatórias |
| — | `add_index ... unique: true` | Garante, no banco, que não existem dois logins iguais (Parte 5) |

O SQL do passo 2, em detalhe:

- `split_part(email, '@', 1)` corta o e-mail no `@` e pega a primeira parte: `ana@exemplo.com` vira `ana`. É um nome provisório.
- `'usuario-' || id`: em SQL, o `||` **junta textos**. O usuário de `id` 3 ganha o login `usuario-3`.

### Por que `up` e `down` em vez de `change`?

Até aqui, as migrations usavam `change`, e o Rails sabia sozinho como **desfazer** cada uma: o contrário de `add_column` é `remove_column`. Mas o Rails não tem como desfazer um `UPDATE` de SQL: os valores antigos se perderam. Por isso escrevemos as duas direções:

- `up`: o que fazer ao rodar a migration (`db:migrate`);
- `down`: o que fazer para desfazê-la (`db:rollback`).

### Aplicando a migration: o `db:migrate`

Escrever a migration **não muda nada** no banco. Ela é só um arquivo com instruções, como uma receita guardada na gaveta. Quem **executa** a receita é o comando `db:migrate`:

```bash
bin/rails db:migrate
```

O que ele faz:

1. Olha a tabela `schema_migrations` (capítulo 035) para saber quais migrations **já rodaram** neste banco.
2. Executa, em ordem de data, só as que ainda **não rodaram**. O número no começo do nome do arquivo, como `20261024194453`, é a data e a hora em que ela foi criada.
3. Anota cada uma na `schema_migrations`, para nunca rodar a mesma duas vezes.
4. Atualiza o arquivo `db/schema.rb`, o "retrato" de como o banco está agora.

É por isso que, depois de um `git pull` que traz migrations novas, cada pessoa da equipe roda `bin/rails db:migrate`: o banco de cada máquina recebe as mesmas mudanças, na mesma ordem.

---

## Parte 3 — O model

O `app/models/user.rb` completo ficou assim:

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :confirmable

  enum :role, { admin: 0, moderador: 1, comum: 2 }, default: :comum, validate: true

  normalizes :login, with: ->(login) { login.strip.downcase }

  before_validation :gerar_login, on: :create

  validates :nome, presence: true, length: { maximum: 80 }
  validates :login, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ },
                    length: { maximum: 30 }

  private

  def gerar_login
    return if login.present?

    base = nome.to_s.split.first.to_s.parameterize.tr("_", "-").first(20).presence || "usuario"
    existentes = User.where("login ~* ?", "^#{base}(-\\d+)?$").pluck(:login)

    if existentes.none? { |l| l.casecmp?(base) }
      self.login = base
    else
      maior = existentes.filter_map { |l| l[/-(\d+)\z/, 1]&.to_i }.max || 0
      self.login = "#{base}-#{maior + 1}"
    end
  end
end
```

Vamos por partes.

### 3.1 `normalizes`: arrumar antes de guardar

```ruby
normalizes :login, with: ->(login) { login.strip.downcase }
```

Antes de guardar, o Rails passa o login por esta "máquina de arrumar":

- `strip` tira espaços do começo e do fim: `" Ana "` vira `"Ana"`;
- `downcase` passa tudo para minúsculas: `"Ana"` vira `"ana"`.

O `->(login) { ... }` é uma **lambda**: uma função pequena, sem nome, guardada numa variável. Ela recebe o login e devolve o login arrumado.

### 3.2 As validações

```ruby
validates :nome, presence: true, length: { maximum: 80 }
```

O nome é obrigatório e tem no máximo 80 caracteres.

```ruby
validates :login, presence: true,
                  uniqueness: { case_sensitive: false },
                  format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ },
                  length: { maximum: 30 }
```

| Regra | O que exige |
| --- | --- |
| `presence: true` | Obrigatório |
| `uniqueness: { case_sensitive: false }` | Ninguém mais pode ter o mesmo login, sem diferenciar maiúsculas: `ana` e `Ana` são iguais |
| `format: { with: ... }` | O formato, definido por uma **expressão regular** (abaixo) |
| `length: { maximum: 30 }` | No máximo 30 caracteres |

### 3.3 Lendo a expressão regular

Uma **expressão regular** (*regex*) é um padrão que descreve como um texto deve ser. A nossa:

```
/\A[a-z0-9]+(-[a-z0-9]+)*\z/
```

| Pedaço | Significado |
| --- | --- |
| `/ ... /` | Começo e fim da regex |
| `\A` | O começo do texto |
| `[a-z0-9]+` | Uma ou mais letras minúsculas ou números |
| `(-[a-z0-9]+)*` | Zero ou mais vezes: um hífen seguido de letras ou números |
| `\z` | O fim do texto |

Aceita: `ana`, `ana-2`, `joao-pedro`, `kaua2026`.
Recusa: `Ana` (maiúscula), `ana_2` (underline), `-ana` (começa com hífen), `ana--2` (dois hífens seguidos), `ana ` (espaço).

> 💡 **Teste sua regex no console:**
> ```ruby
> "ana-2" =~ /\A[a-z0-9]+(-[a-z0-9]+)*\z/
> "ana_2" =~ /\A[a-z0-9]+(-[a-z0-9]+)*\z/
> ```
> O primeiro devolve `0` (achou, na posição 0). O segundo devolve `nil` (não achou).

### 3.4 `before_validation`: quando o login é gerado

```ruby
before_validation :gerar_login, on: :create
```

Antes de **validar**, e só na **criação** (`on: :create`) de um usuário novo, o Rails chama o método `gerar_login`. Por que antes de validar? Porque assim o login gerado também passa pelas validações: se algo sair errado, aparece uma mensagem de erro, em vez de um login inválido ir parar no banco.

Isso é um **callback**: um método que o Rails chama sozinho num momento certo da vida de um registro.

---

## Parte 4 — `gerar_login`, linha a linha

Este método começou como uma manha antiga do educador, usada em projetos reais por muitos anos, e foi ajustado para este projeto. Vamos ler cada linha.

```ruby
return if login.present?
```

Se a pessoa **já escolheu** um login, não fazemos nada. O `return` sai do método na hora.

```ruby
base = nome.to_s.split.first.to_s.parameterize.tr("_", "-").first(20).presence || "usuario"
```

Esta linha é uma **corrente de métodos**: cada um trabalha no resultado do anterior. Acompanhe com o nome `"Ana_Paula Souza"`:

| Método | Resultado | O que fez |
| --- | --- | --- |
| `nome.to_s` | `"Ana_Paula Souza"` | Garante que é texto, mesmo se o nome vier vazio (`nil`) |
| `.split` | `["Ana_Paula", "Souza"]` | Separa nas palavras |
| `.first` | `"Ana_Paula"` | Pega só o primeiro nome |
| `.to_s` | `"Ana_Paula"` | De novo garante texto (se não havia palavra nenhuma) |
| `.parameterize` | `"ana_paula"` | Minúsculas, sem acentos, sem símbolos. `"João"` vira `"joao"` |
| `.tr("_", "-")` | `"ana-paula"` | Troca underline por hífen (a regex não aceita `_`) |
| `.first(20)` | `"ana-paula"` | No máximo 20 caracteres, para sobrar espaço para o número |
| `.presence` | `"ana-paula"` | Se o texto ficou vazio, vira `nil` |
| `\|\| "usuario"` | `"ana-paula"` | Se veio `nil`, usa `"usuario"` |

Por que o `.presence || "usuario"`? Porque um nome feito só de emojis ou símbolos vira texto **vazio** depois do `parameterize`. Sem essa proteção, o login ficaria em branco.

```ruby
existentes = User.where("login ~* ?", "^#{base}(-\\d+)?$").pluck(:login)
```

Busca no banco todos os logins que são `base` ou `base-número`:

- `~*` é o operador de **regex do PostgreSQL**, sem diferenciar maiúsculas;
- `"^#{base}(-\\d+)?$"` monta a regex: para `base = "ana"`, fica `^ana(-\d+)?$`, ou seja, `ana`, `ana-1`, `ana-27`...;
- o `?` dentro do `where` é trocado pelo valor com segurança, sem risco de **injeção de SQL**;
- `pluck(:login)` traz **só** a coluna `login`, numa lista: `["ana", "ana-1"]`.

```ruby
if existentes.none? { |l| l.casecmp?(base) }
  self.login = base
```

Se **ninguém** tem exatamente o login `base`, ele está livre: usamos.

```ruby
else
  maior = existentes.filter_map { |l| l[/-(\d+)\z/, 1]&.to_i }.max || 0
  self.login = "#{base}-#{maior + 1}"
end
```

Se `base` já está ocupado, procuramos **o maior número** em uso e somamos 1:

| Trecho | O que faz |
| --- | --- |
| `l[/-(\d+)\z/, 1]` | Pega o número do fim: de `"ana-7"`, tira `"7"`. De `"ana"`, não tira nada (`nil`) |
| `&.to_i` | Se achou, converte para número. O `&.` só chama o método se o valor não for `nil` |
| `filter_map` | Faz isso para cada login e descarta os `nil` |
| `.max \|\| 0` | O maior número, ou `0` se não houver nenhum |

Exemplos:

| Logins que já existem | Novo login |
| --- | --- |
| nenhum | `ana` |
| `ana` | `ana-1` |
| `ana`, `ana-1`, `ana-2` | `ana-3` |
| `ana`, `ana-2` (o `ana-1` foi apagado) | `ana-3` |

> 💡 **Por que o maior número, e não contar quantos existem?**
> A primeira versão desta manha **contava** os logins parecidos. Com `ana` e `ana-2` no banco (porque o `ana-1` foi apagado), a contagem dá 2, e o novo usuário receberia `ana-2`, que **já existe**. Procurar o maior número resolve esse caso. É um bom exemplo de código que funciona nos casos comuns e falha num caso raro: os bugs mais difíceis de achar moram aí.

---

## Parte 5 — Duas proteções contra logins repetidos

Temos a validação `uniqueness` no model **e** o índice único no banco. Por que as duas?

Imagine duas pessoas chamadas Ana se cadastrando **no mesmo instante**:

1. O Rails da Ana 1 pergunta ao banco: *"existe `ana`?"*. Não.
2. O Rails da Ana 2 pergunta ao banco: *"existe `ana`?"*. Ainda não!
3. As duas recebem `ana` e tentam salvar.

A validação do model não percebe, porque cada uma perguntou antes de a outra salvar. Isso se chama **condição de corrida** (*race condition*).

O **índice único** no banco é a última barreira: o PostgreSQL só aceita a primeira, e a segunda recebe um erro. A validação existe para mostrar uma **mensagem amigável** nos casos comuns; o índice existe para **garantir**, em todos os casos.

```ruby
add_index :users, "lower(login)", unique: true
```

O `lower(login)` faz o índice comparar os logins em minúsculas: `ana` e `ANA` contam como iguais.

---

## Parte 6 — Liberando os campos no Devise

O Devise só aceita os campos que ele conhece (`email` e `password`). Para aceitar também o `nome` e o `login`, em `app/controllers/application_controller.rb`:

```ruby
before_action :configure_permitted_parameters, if: :devise_controller?

protected

def configure_permitted_parameters
  devise_parameter_sanitizer.permit(:sign_up, keys: [:nome])
  devise_parameter_sanitizer.permit(:account_update, keys: [:nome, :login])
end
```

| Trecho | O que faz |
| --- | --- |
| `before_action ..., if: :devise_controller?` | Antes de cada pedido, mas só nas telas do Devise |
| `permit(:sign_up, keys: [:nome])` | No **cadastro**, aceita também o `nome` |
| `permit(:account_update, keys: [:nome, :login])` | Na **edição da conta**, aceita `nome` e `login` |

São os **strong parameters** do capítulo 0110. Repare: o `role` não está em lugar nenhum. Ninguém escolhe o próprio nível.

Nos formulários, acrescentamos o campo de nome em `app/views/devise/registrations/new.html.erb`:

```erb
<div class="field">
  <%= f.label :nome %>
  <%= f.text_field :nome, autofocus: true, autocomplete: "name" %>
</div>
```

E, em `app/views/devise/registrations/edit.html.erb`, o nome e o login:

```erb
<div class="field">
  <%= f.label :login %>
  <%= f.text_field :login, autocomplete: "username" %>
</div>
```

O `autocomplete` ajuda o celular a sugerir o preenchimento. O `autofocus` coloca o cursor no campo quando a página abre, e só um campo da página pode ter.

As palavras "Nome" e "Identificador" que aparecem nas telas vêm do `config/locales/pt-BR.yml`.

---

## Parte 7 — O primeiro administrador

Em `db/seeds.rb`:

```ruby
# Administrador de DESENVOLVIMENTO. A senha fica no código, então
# este bloco nunca roda em produção: lá o admin é criado de outro jeito.
if Rails.env.development?
  User.find_or_create_by!(email: "admin@territorio.local") do |u|
    u.nome = "Admin"
    u.login = "admin"
    u.password = "troque-esta-senha"
    u.role = :admin
    u.skip_confirmation!
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `if Rails.env.development?` | Só em desenvolvimento. A senha está escrita no código, que vai para o GitHub |
| `find_or_create_by!(email: ...)` | Procura um usuário com este e-mail; se não existir, cria. Rodar o seed duas vezes **não** cria dois admins |
| `do \|u\| ... end` | Os dados usados só se for preciso **criar** |
| `u.role = :admin` | Aqui, e só aqui, alguém nasce administrador |
| `u.skip_confirmation!` | Cria já confirmado, sem e-mail |

```bash
bin/rails db:seed
```

Agora entre no sistema com `admin@territorio.local` e a senha `troque-esta-senha`.

> ⚠️ **Por que o `if` é tão importante?** No Rails 8, o comando `db:prepare` também roda os seeds quando cria um banco novo, **inclusive no servidor**. Sem o `if`, o servidor de produção nasceria com um administrador de senha conhecida por qualquer pessoa que leia o código.

---

## Parte 8 — Os primeiros testes automáticos

Até aqui, testamos tudo **à mão**: abrir o navegador, cadastrar, conferir. Um **teste automático** é um código que faz essa conferência sozinho, em segundos, toda vez que você quiser.

### 8.1 As fixtures

Para os testes, o Rails usa um banco **separado**, o `territorio_inteligente_test` do capítulo 035. As **fixtures** são os dados de exemplo que entram nesse banco antes de cada teste. Em `test/fixtures/users.yml`:

```yaml
ana:
  email: ana@exemplo.com
  nome: Ana
  login: ana
  encrypted_password: <%= Devise::Encryptor.digest(User, "senha-segura-123") %>
  confirmed_at: <%= Time.current %>
```

- `ana:` é o nome da fixture. Nos testes, ela vira `users(:ana)`.
- `encrypted_password` guarda o **hash** da senha, e não a senha (capítulo 0100). O `<%= ... %>` gera esse hash.
- `confirmed_at` faz a Ana já nascer confirmada.

> 💡 **Manha: as fixtures que o Devise gera quebram os testes.**
> O Devise cria este arquivo com dois usuários **vazios**. Com o índice único de e-mail, os dois "e-mails vazios" são iguais, e o banco de teste recusa. Por isso substituímos o conteúdo.

### 8.2 Os testes do model

Em `test/models/user_test.rb`:

```ruby
require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "usuário novo nasce comum" do
    assert User.new.comum?
  end

  test "gera o login a partir do primeiro nome" do
    user = User.create!(email: "maria@exemplo.com", password: "senha-segura-123", nome: "Maria da Silva")
    assert_equal "maria", user.login
  end

  test "numera o login quando o primeiro nome já existe" do
    user = User.create!(email: "ana2@exemplo.com", password: "senha-segura-123", nome: "Ana Souza")
    assert_equal "ana-1", user.login
  end
end
```

| Teste | O que garante |
| --- | --- |
| "usuário novo nasce comum" | A regra de segurança do capítulo 0110. Se alguém mudar o padrão sem querer, este teste avisa |
| "gera o login a partir do primeiro nome" | Maria da Silva vira `maria` |
| "numera o login quando o primeiro nome já existe" | A fixture `ana` já ocupa o login `ana`, então a nova Ana vira `ana-1` |

- `assert` confere se algo é verdadeiro.
- `assert_equal esperado, obtido` confere se dois valores são iguais.
- `create!`, com `!`, levanta um erro se não conseguir salvar: o teste falha e mostra o motivo.

### 8.3 O teste da página inicial

Lembra da Manha 3 do capítulo 0100? O gerador do controller criou um teste que procurava a rota `paginas/inicio`, que apagamos. Corrigimos em `test/controllers/paginas_controller_test.rb`:

```ruby
require "test_helper"

class PaginasControllerTest < ActionDispatch::IntegrationTest
  test "a página inicial abre para quem não está logado" do
    get root_url
    assert_response :success
  end
end
```

- `get root_url` abre a página inicial, como um navegador faria.
- `assert_response :success` confere se a página abriu sem erro.

> 💡 **Manha: o nome do teste diz o que ele garante.**
> Quando um teste falha, o nome dele é a primeira coisa que aparece. "A página inicial abre para quem não está logado" explica o problema sozinho. "test_should_get_inicio" não diz nada.

### 8.4 Rodando os testes

```bash
bin/rails test
```

Resultado esperado:

```
4 runs, 4 assertions, 0 failures, 0 errors, 0 skips
```

Cada ponto (`.`) que aparece durante a execução é um teste que passou. Um `F` é uma falha; um `E`, um erro.

A partir de agora, a regra da equipe é: **rode `bin/rails test` antes de cada commit.**

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Callback** | Um método que o Rails chama sozinho num momento certo, como antes de validar. |
| **Validação** | Uma regra que o registro precisa cumprir para ser salvo. |
| **Expressão regular** (*regex*) | Um padrão que descreve como um texto deve ser. |
| **Lambda** | Uma função pequena e sem nome. |
| **Condição de corrida** | Erro que acontece quando duas coisas ocorrem ao mesmo tempo e uma não vê a outra. |
| **Índice único** | Uma regra do banco que impede valores repetidos numa coluna. |
| **Seed** | Dados iniciais que o projeto coloca no banco. |
| **Teste automático** | Código que confere sozinho se outro código funciona. |
| **Fixture** | Dado de exemplo usado nos testes. |

---

## O que aprendemos

- Migrations em bancos com dados: crie a coluna, **preencha**, e só depois torne obrigatória.
- `up` e `down` quando o Rails não sabe desfazer sozinho.
- Uma corrente de métodos transforma um valor passo a passo.
- Procurar o **maior** número resolve o caso que a contagem não resolvia.
- Validação no model **e** índice no banco: a primeira avisa, o segundo garante.
- O primeiro administrador nasce no seed, **só em desenvolvimento**.
- Testes automáticos conferem em segundos o que levaríamos minutos para testar à mão.

**Próximo capítulo:** em breve.
