# 0160 — Lista de usuários: dados de exemplo, busca e rolagem infinita

> **Neste capítulo:** a lista de usuários ganha cara de sistema profissional. Vamos encher o banco de desenvolvimento com **200 usuários de exemplo**, criar uma **busca** por nome ou identificador e fazer a lista carregar aos poucos, de 20 em 20, enquanto você rola a tela: a **rolagem infinita**. Tudo isso sem escrever uma linha de JavaScript.

**Tag deste capítulo:** `cap-0160`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bundle install
bin/rails db:migrate
bin/rails db:seed
bin/rails test
```

O `db:seed` cria os 200 usuários de exemplo (Parte 1).

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
> git switch -c estudo-0160 cap-0160
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
> git branch -D estudo-0160
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

## Parte 1 — 200 usuários de exemplo

Uma lista com 5 usuários não mostra problema nenhum. Com 200, aparecem as perguntas de verdade: *como encontro alguém? A página demora? Cabe no celular?* Para testar isso, precisamos de muitos usuários **falsos**.

### 1.1 A gem Faker

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bundle add faker --group development
```

O **Faker** gera dados falsos que parecem reais: nomes, endereços, telefones. O `--group development` garante que ele **nunca** é instalado no servidor de produção.

### 1.2 O seed

No `db/seeds.rb`, **dentro** do `if Rails.env.development?`, depois do admin:

```ruby
  # Usuários de exemplo, para ver a lista com volume
  if User.count < 50
    Faker::Config.locale = "pt-BR"

    200.times do |i|
      User.create!(nome: "#{Faker::Name.first_name} #{Faker::Name.last_name}",
                   email: "exemplo#{i}@exemplo.com",
                   password: "123456") do |u|
        u.skip_confirmation!
      end
    end
  end
```

| Trecho | Por quê |
| --- | --- |
| `if User.count < 50` | Rodar o seed de novo **não** cria mais 200 |
| `Faker::Config.locale = "pt-BR"` | Nomes brasileiros |
| `first_name` + `last_name` | O `Faker::Name.name` às vezes começa com "Sr." ou "Dra.", e o login viraria `sr-12` |
| `"exemplo#{i}@exemplo.com"` | Um e-mail diferente para cada um. O domínio `exemplo.com` é reservado para exemplos e nunca pertence a ninguém |
| `password: "123456"` | Uma senha fácil de lembrar, aceitável **só** porque estes usuários existem apenas no seu computador |
| `u.skip_confirmation!` | Sem isso, seriam 200 e-mails de confirmação na caixa do `letter_opener` |

> ⚠️ **Dados de exemplo nunca vão para produção.** No servidor de verdade, a lista tem só pessoas de verdade. É por isso que tudo isso fica dentro do `if Rails.env.development?`.

Repare também: com 200 nomes, vários primeiros nomes se repetem. O `gerar_login` do capítulo 0120 numera cada um: `maria`, `maria-1`, `maria-2`... É um teste real da manha do identificador.

```bash
bin/rails db:seed
```

---

## Parte 2 — A busca

Em `app/controllers/admin/users_controller.rb`, o `index` ganhou a busca:

```ruby
def index
  usuarios = User.order(:nome)

  if params[:q].present?
    termo = "%#{User.sanitize_sql_like(params[:q])}%"
    usuarios = usuarios.where("nome ILIKE :termo OR login ILIKE :termo", termo: termo)
  end

  @pagy, @users = pagy(:offset, usuarios, limit: 20)
end
```

| Trecho | O que faz |
| --- | --- |
| `params[:q].present?` | Só filtra se alguém digitou algo na busca |
| `"%#{...}%"` | Em SQL, o `%` quer dizer "qualquer coisa". `%ana%` encontra "Ana", "Mariana", "Ana Paula" |
| `ILIKE` | O `LIKE` do PostgreSQL que **não** diferencia maiúsculas de minúsculas: "ana" encontra "Ana" |
| `nome ILIKE :termo OR login ILIKE :termo` | Procura no nome **ou** no identificador |
| `User.sanitize_sql_like(...)` | Proteção: se alguém digitar `%` ou `_` na busca, eles viram letras comuns, e não "qualquer coisa" |

Lembra do SQL do 1º trimestre? O Rails monta esta consulta por baixo:

```sql
SELECT * FROM users
WHERE (nome ILIKE '%ana%' OR login ILIKE '%ana%')
ORDER BY nome
LIMIT 20 OFFSET 0;
```

Repare que o código **constrói a consulta aos poucos**: começa com todos em ordem e, se houver busca, acrescenta o filtro. O Rails só vai ao banco no fim, quando precisa dos dados.

E o formulário, no topo da lista:

```erb
<%= form_with url: admin_users_path, method: :get, class: "busca" do |f| %>
  <%= f.label :q, "Buscar por nome ou identificador" %>
  <%= f.search_field :q, value: params[:q] %>
  <%= f.submit "Buscar" %>
<% end %>
```

- `method: :get`: uma busca não muda nada, só consulta, então usa `GET`. A busca vai para a URL (`/admin/users?q=ana`), e dá para salvar o link ou compartilhar.
- `value: params[:q]`: depois de buscar, o campo continua mostrando o que você digitou.

---

## Parte 3 — A paginação com o Pagy

### 3.1 A gem

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bundle add pagy --version "~> 43.8"
```

O `~> 43.8` aceita atualizações da 43.8 em diante, mas **não** a 44. É o que o próprio Pagy recomenda, porque cada versão grande muda a forma de usar.

> 💡 **Manha: tutorial da internet tem prazo de validade.** A maioria dos tutoriais de Pagy na internet foi escrita para versões antigas, e o código deles **não funciona** na 43:
>
> | Antes (até a 9) | Agora (43) |
> | --- | --- |
> | `include Pagy::Backend` | `include Pagy::Method` |
> | `pagy(User.all)` | `pagy(:offset, User.all)` |
> | `pagy_next_url(@pagy)` | `@pagy.page_url(:next)` |
>
> Antes de copiar um exemplo, confira a versão da gem no `Gemfile.lock` e a documentação **oficial** daquela versão.

### 3.2 No controller

Em `app/controllers/application_controller.rb`, dentro da classe:

```ruby
include Pagy::Method
```

E no `index`, a última linha:

```ruby
@pagy, @users = pagy(:offset, usuarios, limit: 20)
```

O método `pagy` devolve **duas** coisas de uma vez:

- `@pagy`: as informações da paginação (página atual, se existe próxima, endereço da próxima);
- `@users`: só os 20 usuários da página atual.

O `limit: 20` é um número **par** de propósito: a zebra do capítulo 0150 recomeça em cada página, e com um número par as cores continuam alternando certinho.

---

## Parte 4 — A rolagem infinita com Turbo Frames

### 4.1 A ideia

Em vez de botões "página 1, 2, 3", a próxima página aparece **sozinha** quando você chega ao fim da lista. Quem faz isso é o **Turbo**, a parte do Hotwire que já vem com o Rails.

O Turbo tem os **Turbo Frames**: pedaços da página que se atualizam sozinhos. E um frame com `loading: :lazy` é **preguiçoso**: só busca o seu conteúdo quando aparece na tela.

### 4.2 A view

`app/views/admin/users/index.html.erb`, abaixo do formulário de busca:

```erb
<%= turbo_frame_tag "pagina_#{@pagy.page}", target: "_top" do %>
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

  <% if @pagy.next %>
    <%= turbo_frame_tag "pagina_#{@pagy.next}", src: @pagy.page_url(:next), loading: :lazy, target: "_top" do %>
      <p>Carregando mais usuários…</p>
    <% end %>
  <% end %>
<% end %>
```

### 4.3 Passo a passo do que acontece

1. A página 1 abre com um frame `pagina_1`: 20 usuários e, no fim, um frame **vazio** chamado `pagina_2`, com o texto "Carregando mais usuários…".
2. Você rola a tela. Quando o frame `pagina_2` aparece, o Turbo busca, sozinho, o endereço da página 2 (`/admin/users?page=2`).
3. A resposta é a mesma view, agora com o frame `pagina_2` cheio: mais 20 usuários e um frame vazio `pagina_3` no fim.
4. O Turbo pega **só** o frame `pagina_2` da resposta e encaixa no lugar do vazio.
5. Isso se repete até a última página, onde `@pagy.next` é vazio e nenhum frame novo aparece.

| Trecho | O que faz |
| --- | --- |
| `turbo_frame_tag "pagina_#{@pagy.page}"` | Um frame com o número da página atual |
| `if @pagy.next` | Só cria o próximo frame se houver próxima página |
| `src: @pagy.page_url(:next)` | O endereço que o frame vai buscar. O Pagy mantém o `?q=` da busca: a rolagem continua **dentro** do resultado |
| `loading: :lazy` | Só busca quando o frame aparece na tela |
| `target: "_top"` | Links dentro do frame abrem a **página inteira**. Sem isso, "Alterar nível" tentaria abrir dentro do frame, e a tela quebraria |

### 4.4 Veja acontecer

Abra o DevTools (F12), vá na aba **Network**, filtre por **Fetch/XHR** e role a lista. A cada 20 usuários, aparece um pedido novo: `users?page=2`, `users?page=3`... Cada um é o Turbo buscando a próxima página.

### 4.5 O CSS

No `30-admin.css`:

```css
turbo-frame {
  display: block;
}

.lista-usuarios {
  margin-bottom: var(--espaco-1);
}
```

O `turbo-frame` é uma tag nova, e o navegador não sabe que ela deve ocupar a linha toda. O `display: block` resolve. E o `margin-bottom` dá, entre uma página e outra, o mesmo espaço que há entre os cartões: ninguém percebe onde termina uma página e começa a outra.

E o formulário de busca:

```css
.busca {
  display: flex;
  flex-wrap: wrap;
  align-items: end;
  gap: var(--espaco-1);
  margin-block: var(--espaco-2);
  max-width: 40rem;
}

.busca label {
  flex-basis: 100%;
}

.busca input[type="search"] {
  flex: 1;
  padding: var(--espaco-1);
  border: 2px solid var(--cor-roxo);
  border-radius: var(--raio);
  background: var(--cor-branco);
}
```

O rótulo ocupa a linha inteira (`flex-basis: 100%`), e embaixo o campo estica (`flex: 1`) até encostar no botão.

---

## Parte 5 — O teste da busca

No `test/controllers/admin/users_controller_test.rb`:

```ruby
test "a busca encontra pelo nome e deixa os outros de fora" do
  sign_in users(:admin)
  get admin_users_url(q: "ana")
  assert_match "ana@exemplo.com", response.body
  assert_no_match "admin@exemplo.com", response.body
end
```

- `get admin_users_url(q: "ana")` faz a busca como o formulário faria.
- `response.body` é o HTML que o servidor devolveu.
- `assert_match` confere que a Ana **está** no resultado; `assert_no_match`, que o admin **não** está.

```bash
bin/rails test
```

---

## Parte 6 — Testando no navegador

1. Entre como admin e abra **Usuários**.
2. Role até o fim: os usuários vão aparecendo de 20 em 20. Acompanhe na aba Network.
3. Busque um nome comum, como "Maria", e role: só aparecem as Marias. Teste também um nome composto.
4. Na página 3 ou 4, clique em **Alterar nível**: a tela de edição abre inteira.

### Tente quebrar

| Tente buscar | O que o sistema deve fazer |
| --- | --- |
| O campo **vazio** | Mostrar a lista inteira, como se não houvesse busca |
| Só **`%`** | Procurar o caractere `%` de verdade e, como nenhum nome tem `%`, mostrar a lista **vazia** |
| Só **`_`** | O mesmo: procurar o `_` de verdade, e não "qualquer letra" |
| Letras **maiúsculas**, como `MARIA` | Encontrar as Marias: o `ILIKE` não diferencia maiúsculas |
| Um nome que **não existe** | Mostrar a lista vazia, sem erro |

As linhas do `%` e do `_` mostram o `sanitize_sql_like` funcionando. Sem ele, a busca por `%` viraria `%%%` no SQL, que quer dizer *"qualquer coisa"*, e devolveria **todos** os usuários. Uma busca que devolve tudo quando deveria devolver nada é um tipo de falha que passa despercebida, e por isso vale testar de propósito.

> 💡 Quando a busca não encontra ninguém, a página fica só com o título e o formulário. Uma mensagem como *"Nenhum usuário encontrado"* ajudaria quem usa: fica como sugestão de melhoria para uma próxima tarefa.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Dados de exemplo** (*fake data*) | Dados falsos que parecem reais, para testar o sistema com volume. |
| **Paginação** | Dividir uma lista grande em pedaços, as páginas. |
| **`LIMIT` e `OFFSET`** | Em SQL: "traga 20" e "pule os primeiros 40". É assim que se busca a página 3. |
| **`ILIKE`** | A busca por texto do PostgreSQL que não diferencia maiúsculas de minúsculas. |
| **Turbo Frame** | Um pedaço da página que o Turbo atualiza sozinho. |
| **Carregamento preguiçoso** (*lazy loading*) | Só buscar algo quando ele aparece na tela. |

---

## O que aprendemos

- Testar com volume revela problemas que uma lista pequena esconde.
- Dados de exemplo ficam **só** em desenvolvimento.
- A consulta ao banco pode ser montada aos poucos, e a busca do usuário precisa ser **protegida**.
- Uma busca usa `GET`: não muda nada e cabe num link.
- Com Turbo Frames, a rolagem infinita sai em HTML puro.
- Tutorial da internet tem prazo de validade: confira a versão da gem.

**Próximo capítulo:** em breve.

---

## Fontes

- [Pagy — documentação oficial](https://ddnexus.github.io/pagy/)
- [Pagy — guia de atualização para a versão 43](https://ddnexus.github.io/pagy/guides/upgrade-guide)
