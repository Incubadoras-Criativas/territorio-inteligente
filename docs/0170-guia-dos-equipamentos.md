# 0170 — Guia dos equipamentos

> **Neste capítulo:** o Território Inteligente ganha o seu primeiro conteúdo de verdade, o **guia dos equipamentos** das academias ao ar livre. Cada equipamento tem uma página com o jeito certo de usar, escrita pela turma e revisada por uma fisioterapeuta. Vamos ver **onde guardar** esse conteúdo (e por que escolhemos arquivos HTML, e não o banco), o que é um **slug**, como o Rails lê um arquivo do disco a cada visita e por que o Brakeman desconfiou de nós.

**Tag deste capítulo:** `cap-0170`

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

O `db:migrate` cria a tabela `equipamentos`, e o `db:seed` cadastra a lista de equipamentos (Parte 7).

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
> git switch -c estudo-0170 cap-0170
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
> git branch -D estudo-0170
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

## Parte 1 — A decisão: onde mora o conteúdo?

Cada página do guia tem texto, listas, talvez uma tabela: *para que serve o equipamento, como usar, erros comuns, cuidados*. Quem escreve são vocês, a turma. Quem revisa é a Camila, fisioterapeuta. Antes de escrever código, precisamos decidir **onde esse texto vai morar**. Havia três caminhos:

| Caminho | Como seria | Problema |
| --- | --- | --- |
| **1. No banco de dados** | Uma coluna `conteudo` e uma tela de edição no site | Precisaria de um editor de texto no site, com controle de quem edita. E não teria revisão antes de publicar |
| **2. Numa view do Rails** | Um arquivo `.html.erb` por equipamento, em `app/views` | Em produção, o Rails **guarda as views na memória** ao iniciar. Cada texto corrigido exigiria **reiniciar** o servidor |
| **3. Num arquivo HTML, lido a cada visita** | Um arquivo `.html` por equipamento, numa pasta própria | Nenhum dos dois acima: era o caminho que procurávamos |

Escolhemos o **caminho 3**. Ele junta o melhor dos outros dois:

- O texto fica num **arquivo**, que entra no Git. Cada mudança passa por um **Pull Request**, e a Camila pode revisar antes de ir para o ar. Isso vale ouro num conteúdo de saúde.
- O Rails **lê o arquivo do disco a cada visita**. Um texto corrigido aparece no servidor depois do `git pull`, sem reiniciar nada.

> 💡 **Por que a view exige reiniciar e o arquivo não?** Pense numa cozinha de restaurante. A **view** é a receita que o cozinheiro decorou ao chegar de manhã: se a receita mudar no caderno, ele continua fazendo a antiga até o dia seguinte. O **arquivo lido a cada visita** é a receita que ele consulta no caderno **a cada prato**: mudou no caderno, o próximo prato já sai novo.
>
> Em termos técnicos: em desenvolvimento, o Rails confere se as views mudaram a cada pedido (`config.enable_reloading = true`). Em produção, ele compila as views **uma vez** e reaproveita a versão compilada, porque isso é bem mais rápido. Um `File.read` comum, ao contrário, vai ao disco toda vez que roda.

O banco continua tendo um papel: ele guarda a **lista** de equipamentos (o nome e o endereço de cada um). O **texto** fica no arquivo.

---

## Parte 2 — O model e o slug

### 2.1 O que é um slug?

Numa biblioteca, cada livro tem uma etiqueta na lombada, como `ROW-PED-2010`. Ela é curta, não tem espaço nem acento e é **única**: duas obras nunca têm a mesma etiqueta.

Em termos técnicos, um **slug** é a versão de um texto preparada para ir na **URL**: minúsculas, sem acento, palavras separadas por hífen. O nome "Simulador de cavalgada" vira o slug `simulador-de-cavalgada`, e a página fica em:

```
/equipamentos/simulador-de-cavalgada
```

Compare com o jeito padrão do Rails, `/equipamentos/7`. O número não diz nada a quem lê. O slug diz, e ainda serve de **nome do arquivo** do conteúdo: `simulador-de-cavalgada.html`.

### 2.2 A tabela

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate model Equipamento nome:string slug:string:uniq
bin/rails db:migrate
```

O `slug:string:uniq` cria a coluna **e** um índice único no banco. É a segunda trava contra slugs repetidos: a primeira está no model, logo abaixo. Se dois pedidos chegarem ao mesmo tempo e passarem os dois pela validação do model, o banco recusa o segundo.

### 2.3 O model

`app/models/equipamento.rb`:

```ruby
class Equipamento < ApplicationRecord
  normalizes :slug, with: ->(slug) { slug.strip.downcase }
  before_validation :gerar_slug

  validates :nome, presence: true
  validates :slug, presence: true, uniqueness: true,
                   format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ }

  def to_param = slug

  def conteudo
    arquivo.read if arquivo.exist?
  end

  def imagem
    %w[jpg png webp].each do |ext|
      return "/equipamentos/#{slug}.#{ext}" if Rails.public_path.join("equipamentos", "#{slug}.#{ext}").exist?
    end
    nil
  end

  private

  def arquivo = Rails.configuration.x.pasta_equipamentos.join("#{slug}.html")

  def gerar_slug
    self.slug = nome.to_s.parameterize if slug.blank?
  end
end
```

Várias peças aqui você já conhece do `User` no capítulo 0120. As novas:

| Trecho | O que faz |
| --- | --- |
| `normalizes :slug` | Limpa o slug antes de salvar: tira espaços das pontas e passa para minúsculas |
| `gerar_slug` | Se ninguém informou um slug, cria a partir do nome. `"Leg press".parameterize` vira `"leg-press"` |
| `if slug.blank?` | Só gera quando está vazio. Assim, dá para escolher um slug à mão, se precisar |
| `format: { with: ... }` | O slug só pode ter letras minúsculas, números e hífens entre eles. É o **mesmo formato** do identificador do usuário |
| `def to_param = slug` | Ensina o Rails a usar o slug, e não o `id`, nas URLs (veja abaixo) |

> 💡 **`def to_param = slug` numa linha só?** É o **método de uma linha** do Ruby 3 em diante, o *endless method*: quando o método só devolve um valor, dá para escrever sem `end`. As duas formas abaixo são iguais:
>
> ```ruby
> def to_param = slug
>
> def to_param
>   slug
> end
> ```

### 2.4 O `to_param`: ensinando o Rails a montar a URL

Quando você escreve `link_to equipamento.nome, equipamento`, o Rails precisa transformar o objeto num pedaço de URL. Para isso, ele chama `equipamento.to_param`. O padrão devolve o `id`. Nós trocamos pelo slug:

```ruby
equipamento.to_param           # => "leg-press"
equipamento_path(equipamento)  # => "/equipamentos/leg-press"
```

Com uma linha no model, **todos** os links do projeto passam a usar o slug, sem mudar nenhuma view.

---

## Parte 3 — Onde ficam os arquivos

### 3.1 As duas pastas

| O quê | Onde | Exemplo |
| --- | --- | --- |
| Texto do guia | `conteudo/equipamentos/` | `conteudo/equipamentos/leg-press.html` |
| Foto do equipamento | `public/equipamentos/` | `public/equipamentos/leg-press.jpg` |

A regra é uma só: **o nome do arquivo é o slug**. Quem sabe o slug sabe onde está tudo.

**Por que o texto não fica em `public/`?** Tudo o que está em `public/` vai direto para o navegador, sem passar pelo Rails. O texto precisa passar pelo Rails, para ganhar o layout do site, com o cabeçalho e o menu. Já a foto não precisa de nada disso, e servir arquivo pronto é justamente o trabalho da pasta `public/`.

### 3.2 A pasta numa configuração: `config.x`

Em `config/application.rb`:

```ruby
config.x.pasta_equipamentos = Rails.root.join("conteudo/equipamentos")
```

E em `config/environments/test.rb`:

```ruby
config.x.pasta_equipamentos = Rails.root.join("test/fixtures/files/equipamentos")
```

Pense num endereço de entrega. A loja não grava o seu endereço dentro de cada pacote: ela consulta o cadastro na hora de enviar. Se você se mudar, basta atualizar o cadastro.

Em termos técnicos, o `config.x` é a gaveta do Rails para **configurações nossas**. Tudo o que você pendura nele (`config.x.qualquer_nome`) fica disponível no projeto inteiro, em `Rails.configuration.x.qualquer_nome`. O model pergunta *"qual é a pasta?"* e não sabe, nem precisa saber, se está em desenvolvimento ou em teste.

E por que os testes usam **outra** pasta? Porque os testes não podem depender do conteúdo de verdade. Se alguém da turma reescrever o guia do leg press, nenhum teste deve quebrar por isso. Os testes leem arquivos próprios, que ninguém mexe sem querer.

### 3.3 O `conteudo`, linha a linha

```ruby
def conteudo
  arquivo.read if arquivo.exist?
end
```

- `arquivo` monta o caminho: a pasta configurada + `slug` + `.html`.
- `arquivo.exist?` confere se o arquivo existe. Um equipamento recém-cadastrado ainda não tem texto.
- `arquivo.read` lê o arquivo inteiro, **a cada vez** que o método é chamado: é aqui que mora a decisão da Parte 1.
- Se o arquivo não existe, o `if` não roda e o método devolve `nil`. A view usa isso para mostrar "em construção".

### 3.4 A `imagem`, linha a linha

O método procura uma foto com o slug, tentando três formatos, nesta ordem: `jpg`, `png` e `webp`.

- O `return` dentro do `each` **sai do método na hora**, com o endereço da primeira foto que encontrar.
- Se nenhuma existir, o laço termina e o método devolve `nil`.
- O endereço devolvido não tem `public/`: o que está em `public/equipamentos/leg-press.jpg` aparece no navegador como `/equipamentos/leg-press.jpg`.

Repare que `imagem` fica **acima** do `private`, porque a view precisa chamá-lo. Já `arquivo` e `gerar_slug` são detalhes internos do model e ficam abaixo.

---

## Parte 4 — Rotas, controller e views

### 4.1 A rota

Em `config/routes.rb`:

```ruby
resources :equipamentos, only: [ :index, :show ], param: :slug
```

- `only: [ :index, :show ]`: só a lista e a página de cada equipamento. Ninguém cadastra equipamento pelo site, por enquanto.
- `param: :slug`: o pedaço variável da URL se chama `:slug`, e não `:id`. No controller, ele chega em `params[:slug]`.

### 4.2 O controller

`app/controllers/equipamentos_controller.rb`:

```ruby
class EquipamentosController < ApplicationController
  def index
    @equipamentos = Equipamento.order(:nome)
  end

  def show
    @equipamento = Equipamento.find_by!(slug: params[:slug])
  end
end
```

- Não tem `before_action :authenticate_user!`: o guia é **público**. Qualquer pessoa na praça, com o celular na mão, pode consultar.
- `find_by!` com **exclamação**: se o slug não existe, ele levanta um erro, e o Rails responde **404, página não encontrada**. Sem a exclamação, o `@equipamento` seria `nil`, e a view quebraria com um erro 500, bem mais feio.

### 4.3 A lista

`app/views/equipamentos/index.html.erb`. Cada equipamento é um cartão com a foto e o nome. Quem ainda não tem foto ganha um quadrado com um **"?"**, que avisa: *esta foto ainda está faltando, alguém pode tirar?*

```erb
<h1>Guia dos equipamentos</h1>

<ul class="lista-equipamentos" role="list">
  <% @equipamentos.each do |equipamento| %>
    <li>
      <%= link_to equipamento, class: "cartao-equipamento" do %>
        <% if equipamento.imagem %>
          <%= image_tag equipamento.imagem, alt: "" %>
        <% else %>
          <span class="sem-imagem" aria-hidden="true">?</span>
        <% end %>
        <span><%= equipamento.nome %></span>
      <% end %>
    </li>
  <% end %>
</ul>
```

O `alt: ""` vazio é de propósito: o nome do equipamento já está escrito ao lado, e o leitor de tela não precisa ler a mesma coisa duas vezes.

### 4.4 A página do equipamento

`app/views/equipamentos/show.html.erb`:

```erb
<h1><%= @equipamento.nome %></h1>

<% if @equipamento.imagem %>
  <%= image_tag @equipamento.imagem, alt: "Foto do equipamento #{@equipamento.nome}" %>
<% end %>

<% if @equipamento.conteudo %>
  <%= @equipamento.conteudo.html_safe %>
<% else %>
  <p>Este guia ainda está em construção.</p>
<% end %>

<%= link_to "Voltar para a lista", equipamentos_path %>
```

O `html_safe` merece uma parte só para ele.

---

## Parte 5 — O `html_safe` e o alerta do Brakeman

### 5.1 Por que o Rails escapa o HTML

Lembra do capítulo 0140? Quando alguém se cadastra com `<script>` no nome, o ERB **escapa** o texto antes de mostrar: os sinais `<` e `>` aparecem na tela como letras, e o navegador não executa nada. Essa proteção contra o ataque chamado **XSS** (*Cross-Site Scripting*) vem ligada por padrão em **toda** view.

Só que, no guia, nós **queremos** que o HTML funcione: os `<h2>`, `<ul>` e `<strong>` do arquivo precisam virar títulos, listas e negrito. O `html_safe` diz ao Rails: *"este texto é confiável, não escape"*.

### 5.2 O Brakeman desconfia

Ao rodar o `bin/brakeman`, apareceu um alerta de confiança **média**: *Cross-Site Scripting*. O Brakeman viu um `html_safe` aplicado a algo que vem de fora do código, e fez o trabalho dele: avisar.

Um alerta **não** quer dizer que existe uma falha. Quer dizer que **alguém precisa olhar**. Então olhamos. De onde vem o texto?

1. Vem **só** de arquivos na pasta `conteudo/equipamentos/`, que fazem parte do código.
2. Esses arquivos só mudam por **Pull Request**, revisado antes do merge.
3. **Nenhum** visitante consegue escrever nessa pasta pelo site.
4. O caminho do arquivo é montado com o slug, e o slug só aceita letras, números e hífens. Ninguém consegue montar um caminho como `../../config/master.key`, porque nem o ponto nem a barra passam na validação.

O texto é tão confiável quanto o próprio código Ruby do projeto. O alerta pode ser marcado como **analisado e aceito**.

### 5.3 O `brakeman.ignore`

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/brakeman -I
```

O `-I` abre o modo **interativo**, que passa pelos alertas um a um:

1. Na primeira pergunta, escolha **1** para inspecionar todos os alertas.
2. No alerta do XSS, responda **`n`**: *ignorar e escrever uma nota*.
3. Escreva a nota explicando **por quê**:
   *"Conteúdo vem só de arquivos HTML em conteudo/equipamentos, revisados via PR; o slug é validado no model."*
4. No fim, salve. O Brakeman cria o arquivo `config/brakeman.ignore`.

Depois disso, o `bin/brakeman` mostra **0 alertas** e **1 ignorado**. O CI do GitHub volta a passar.

> ⚠️ **Ignorar um alerta é uma decisão, e decisão se registra.** A nota fica no `brakeman.ignore`, dentro do Git. Daqui a um ano, quem abrir o arquivo vai saber o que foi ignorado e por quê. E, se um dia alguém mudar o `show` para usar outra coisa, o Brakeman percebe que o código mudou e volta a alertar.

---

## Parte 6 — Escrevendo o guia de um equipamento

### 6.1 O modelo

O arquivo `conteudo/equipamentos/_MODELO.html` é o ponto de partida de toda página do guia. Ele traz as seções que cada equipamento precisa ter, com o HTML pronto, só esperando o texto.

O sublinhado no começo do nome garante duas coisas: o modelo aparece **no topo** da lista de arquivos, e nenhum slug pode começar com `_`, então ele nunca vai aparecer no site por engano.

### 6.2 O passo a passo

1. Descubra o slug do equipamento: é o fim do endereço da página dele. Para "Leg press", `leg-press`.
2. Copie o modelo com o nome do slug:

   ```bash
   cp conteudo/equipamentos/_MODELO.html conteudo/equipamentos/leg-press.html
   ```

3. Escreva o conteúdo no arquivo novo e acompanhe no navegador. Não precisa reiniciar o servidor: basta recarregar a página.
4. Se tiver uma foto **sua** do equipamento, salve como `public/equipamentos/leg-press.jpg`.
5. Abra um Pull Request. A revisão da Camila acontece ali, antes do merge.

> ⚠️ **Fotos de pessoas.** A foto do guia mostra o **equipamento**. Se aparecer uma pessoa, ela precisa ter autorizado por escrito, e menores de idade só com autorização dos responsáveis. É a LGPD, a lei que protege os dados pessoais, e o rosto é um dado pessoal. Na dúvida, fotografe o equipamento vazio.

> ⚠️ **Só HTML simples.** Títulos, parágrafos, listas, negrito e tabelas. Nada de `<script>`, `<style>` ou `<iframe>`: a aparência vem do CSS do site, e o revisor recusa o PR que trouxer qualquer um desses.

---

## Parte 7 — A lista de equipamentos no seed

No `db/seeds.rb`, **fora** do `if Rails.env.development?`:

```ruby
[
  "Simulador de caminhada", "Simulador de cavalgada", "Remada sentada",
  "Puxador alto", "Leg press", "Surf", "Esqui", "Rotação diagonal",
  "Rotação vertical", "Multiexercitador", "Alongador"
].each do |nome|
  Equipamento.find_or_create_by!(nome:)
end
```

- **Fora** do `if`, porque esta lista é dado **de verdade**: o servidor de produção também precisa dela. Compare com os 200 usuários de exemplo do capítulo 0160, que ficam **dentro**.
- `find_or_create_by!`: procura um equipamento com esse nome e só cria se não achar. Rodar o seed dez vezes não cria dez leg presses.
- `(nome:)` é um atalho do Ruby para `(nome: nome)`.

> 📝 Esta lista é **provisória**. A versão final vem da pesquisa de campo e da revisão da Camila. Os nomes que a turma encontrar nas praças podem ser diferentes destes.

---

## Parte 8 — O CSS dos cartões

O arquivo `app/assets/stylesheets/40-equipamentos.css` cuida da lista: cada cartão tem a foto (ou o "?") à esquerda e o nome à direita, com o mesmo branco e o mesmo canto arredondado dos cartões da administração. O quadrado do "?" usa o `--cor-roxo-claro`, para combinar com o restante.

O número 40 segue a ordem: o CSS de base (00 a 10), a navegação (20), a administração (30) e, agora, os equipamentos.

---

## Parte 9 — Os testes

### 9.1 Os arquivos de teste

Lembra que os testes leem outra pasta? Ela é `test/fixtures/files/equipamentos/`, e tem **um** arquivo HTML. O banco de teste tem dois equipamentos, em `test/fixtures/equipamentos.yml`:

| Fixture | Tem arquivo HTML? |
| --- | --- |
| `barra_fixa` | Sim |
| `remada` | Não |

Com um de cada, dá para testar os dois caminhos: o guia que existe e o que está "em construção".

### 9.2 O que os testes conferem

No model (`test/models/equipamento_test.rb`):

- o slug é gerado a partir do nome;
- um slug com espaço, acento ou barra é recusado;
- o `conteudo` lê o arquivo quando ele existe e devolve `nil` quando não existe;
- a `imagem` devolve `nil` quando não há foto.

No controller (`test/controllers/equipamentos_controller_test.rb`):

- a lista abre sem login e mostra os equipamentos;
- o equipamento sem foto mostra o quadrado `.sem-imagem`;
- a página de um equipamento com arquivo mostra o conteúdo;
- a página de um equipamento sem arquivo mostra "Este guia ainda está em construção".

```bash
bin/rails test
bin/brakeman --no-pager
```

---

## Parte 10 — Testando no navegador

1. Abra `/equipamentos` **sem estar logado**: a lista aparece, em ordem alfabética.
2. Clique num equipamento: a URL mostra o slug, como `/equipamentos/leg-press`.
3. Crie um arquivo de teste a partir do modelo, como `conteudo/equipamentos/leg-press.html`, e recarregue a página: o texto aparece **sem reiniciar o servidor**.
4. Salve qualquer foto como `public/equipamentos/leg-press.jpg` e veja a lista: o "?" virou foto.
5. Apague os dois arquivos de teste antes do commit.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| `/equipamentos/nao-existe` | Responder **404**. Em desenvolvimento, aparece a tela de erro do Rails com `ActiveRecord::RecordNotFound`. Em produção, a página 404 |
| `/equipamentos/..%2Fconfig` (o `%2F` é uma barra disfarçada) | Responder 404: o Rails procura o slug `../config` **no banco**, e nenhum slug tem ponto ou barra |
| Um equipamento sem arquivo HTML | Mostrar "Este guia ainda está em construção.", sem erro |
| `/equipamentos/LEG-PRESS` | Abrir o leg press normalmente: o `normalizes` também vale nas **buscas**, e o `find_by!` procura por `leg-press` |
| No console (`bin/rails console`), `Equipamento.create!(nome: "Leg press")` | Recusar: o slug `leg-press` já existe |

A segunda linha é a mais importante. Um ataque comum contra sites que leem arquivos do disco é o *path traversal*: usar `../` para "subir" pastas e ler um arquivo secreto. Aqui, ele não funciona por dois motivos ao mesmo tempo. O endereço é procurado no **banco**, não no disco, e o slug que monta o caminho só aceita letras, números e hífens.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Slug** | Como a etiqueta na lombada de um livro: curta e única. É o texto preparado para a URL, em minúsculas, sem acento e com hífens. |
| **`to_param`** | O método que o Rails chama para transformar um objeto em pedaço de URL. |
| **`config.x`** | A gaveta do Rails para configurações nossas, consultada no projeto inteiro. |
| **Cache de views** | Em produção, o Rails "decora" as views ao iniciar, como um cozinheiro que decora a receita. Mudou a view, precisa reiniciar. |
| **XSS** (*Cross-Site Scripting*) | Um ataque em que alguém consegue fazer o site executar um código dele no navegador de outras pessoas. |
| **`html_safe`** | Diz ao Rails que um texto é confiável e não deve ser escapado. Use só com texto que vem do próprio projeto. |
| **Path traversal** | Um ataque que usa `../` no endereço para chegar a arquivos fora da pasta permitida. |

---

## O que aprendemos

- Antes do código, a decisão: **onde mora** cada tipo de dado. A lista vai para o banco; o texto revisado vai para arquivos no Git.
- Um slug deixa a URL legível e ainda serve de nome de arquivo.
- Com o `to_param`, uma linha no model muda todos os links do projeto.
- Ler um arquivo a cada visita dispensa reiniciar o servidor quando o texto muda.
- Alerta de segurança não se ignora no escuro: analisa, decide e **registra a decisão**.
- Validar o formato do slug protege contra um ataque inteiro.

**Próximo capítulo:** [0180 — Menu para celular](0180-menu-para-celular.md)

---

## Fontes

- [Rails Guides — Configuring Rails Applications: custom configuration](https://guides.rubyonrails.org/configuring.html#custom-configuration)
- [Rails API — `ActiveRecord::Integration#to_param`](https://api.rubyonrails.org/classes/ActiveRecord/Integration.html#method-i-to_param)
- [Brakeman — Ignoring false positives](https://brakemanscanner.org/docs/ignoring_false_positives/)
- [OWASP — Path Traversal](https://owasp.org/www-community/attacks/Path_Traversal)
