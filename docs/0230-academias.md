# 0230 — Academias

> **Neste capítulo:** chegamos ao centro do projeto, as **academias ao ar livre**. Qualquer pessoa com conta pode cadastrar uma academia, com a localização, o território, as categorias e os equipamentos que ela tem. O cadastro nasce como **rascunho**, e um moderador revisa e publica. É o capítulo com mais tabelas até aqui, e por isso é também o capítulo em que o Rails mais brilha: vamos ver como ele descreve **relacionamentos** entre tabelas com poucas palavras, e por que às vezes é preciso ensinar português a ele.

**Tag deste capítulo:** `cap-0230`

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

O `db:migrate` cria cinco tabelas novas, e o `db:seed` cadastra o território "Ceilândia" e a categoria "Academia ao ar livre".

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
> git switch -c estudo-0230 cap-0230
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
> git branch -D estudo-0230
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo, os equipamentos, o território e a categoria.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar um `generate` de novo, por exemplo, criaria uma segunda migration igual à primeira, e o `db:migrate` daria erro.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — O que é uma academia, para o sistema

O documento do hackathon pede que moradores e pesquisadores **localizem e validem** as academias no mapa. Antes de escrever código, decidimos o que o sistema precisa saber de cada uma:

| Dado | Por quê |
| --- | --- |
| **Nome** (opcional) | Muitas academias não têm nome conhecido. Quem cadastra na praça não precisa inventar um |
| **Endereço ou referência** | No DF, "QE 38, ao lado da escola" diz mais do que rua e número |
| **Território** | Para agrupar as academias no painel. O piloto é em Ceilândia, mas o sistema não fica preso a ela |
| **Latitude e longitude** | A localização de verdade. É com elas que o mapa desenha o ponto e que o CulturaEduca informa o que há no entorno |
| **Categorias** | Começa com "Academia ao ar livre". A pesquisa já viu outros tipos, como academias de musculação montadas pela própria comunidade |
| **Equipamentos e quantidades** | Quais equipamentos do nosso guia existem ali, e quantos de cada |
| **Visível** | Rascunho até um moderador revisar |
| **Autor** | Quem cadastrou |

E o que **não** entra aqui: as condições observadas (conservação, limpeza, iluminação...), as fotos e os relatos. Esses dados mudam a cada visita, e vão morar numa tabela própria, a das **observações**, no próximo capítulo. A academia é o **lugar**; a observação é **o que alguém viu lá, num dia**.

### Quem pode o quê

| Quem | O que pode fazer com as academias |
| --- | --- |
| Visitante, sem conta | Ver as publicadas |
| **Comum** | Cadastrar (nasce como rascunho), ver e editar **os próprios rascunhos** |
| **Moderador** | Ver todas, editar todas e **publicar** |
| **Admin** | Tudo |

É a primeira vez que o nível **moderador**, criado no capítulo 0110, ganha um papel.

---

## Parte 2 — O Rails pensa em inglês: as inflexões

### 2.1 O problema

O Rails dá nomes às coisas a partir do nome do model: o model `Equipamento` usa a tabela `equipamentos`, as rotas `equipamentos_path` e o controller `EquipamentosController`. Para isso, ele **pluraliza** o nome. Teste no terminal:

```bash
bin/rails runner 'p "equipamento".pluralize, "territorio".pluralize'
```

```
"equipamentos"
"territorios"
```

Até aqui, tudo certo. Agora:

```bash
bin/rails runner 'p "academia".pluralize, "categoria".pluralize'
```

Sem a correção deste capítulo, a resposta seria `"academia"` e `"categoria"`: **iguais ao singular**.

Pense num tradutor que só conhece inglês. Ele vê "academia" e lembra de *media* e *criteria*, palavras do inglês terminadas em "ia" que **já estão no plural** (o singular é *medium* e *criterion*). Para ele, "academia" seria o plural de "academium".

Em termos técnicos, o Rails transforma palavras com **regras de inflexão** escritas para o inglês. Uma delas diz que palavras terminadas em "ia" já são plurais. Para "academia", isso daria uma tabela chamada `academia` e rotas confusas, e os formulários tentariam enviar para endereços que não existem.

### 2.2 A solução

Em `config/initializers/inflections.rb`:

```ruby
# O Rails pluraliza em inglês: palavras terminadas em "ia" (media, criteria)
# ficariam iguais no plural. Ensinamos as nossas.
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular "academia", "academias"
  inflect.irregular "categoria", "categorias"
end
```

O `irregular` ensina os dois sentidos de uma vez: o plural de "academia" é "academias", e o singular de "academias" é "academia".

> 💡 **Manha: antes de criar um model com nome em português, teste a pluralização.** Um `bin/rails runner 'p "nome".pluralize, "nomes".singularize'` leva dois segundos e evita horas procurando por que uma rota não funciona. Os casos mais comuns que precisam de ajuda: palavras terminadas em **"ia"** (academia, categoria, farmácia), em **"ão"** (ação vira "açãos") e em **"l"** (animal vira "animals").

A correção precisa vir **antes** do `generate`. O gerador usa a pluralização para dar nome à tabela, e corrigir depois exige mexer na migration.

---

## Parte 3 — Migrations e relacionamentos

Esta é uma das partes em que o Rails mais facilita a vida. Num projeto com SQL puro, ligar tabelas exige escrever as chaves, os índices e as consultas com `JOIN` à mão. No Rails, cada ligação vira **uma linha** no model, que se lê quase como português.

### 3.1 As tabelas

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate model Territorio nome:string slug:string:uniq
bin/rails generate model Categoria nome:string slug:string:uniq
bin/rails generate model Academia nome:string referencia:string territorio:references \
  latitude:decimal longitude:decimal visivel:boolean autor:references
bin/rails generate model AcademiaCategoria academia:references categoria:references
bin/rails generate model AcademiaEquipamento academia:references equipamento:references quantidade:integer
```

O desenho, com as setas indicando quem aponta para quem:

```
          Territorio
              ▲
              │ territorio_id
              │
User ◄──── Academia ◄──── AcademiaCategoria ────► Categoria
 autor_id     ▲
              │
     AcademiaEquipamento ────► Equipamento
```

### 3.2 O que é uma chave estrangeira?

Pense numa ficha de biblioteca. Em vez de copiar o livro inteiro na ficha de empréstimo, ela guarda só o **número do livro**, e quem quiser os detalhes vai até a estante.

Em termos técnicos, a **chave estrangeira** é uma coluna que guarda o `id` de um registro de **outra** tabela. A academia não guarda o nome do território: guarda o `territorio_id`. Se o nome do território mudar, todas as academias "ficam sabendo" na hora, porque nenhuma delas tinha uma cópia.

O `territorio:references` do gerador cria três coisas de uma vez:
- a coluna `territorio_id`;
- um **índice** nela, para as buscas por território serem rápidas;
- uma **restrição no banco** (`foreign_key: true`): o PostgreSQL não aceita um `territorio_id` que não exista na tabela `territorios`.

### 3.3 A migration da academia

```ruby
create_table :academias do |t|
  t.string :nome
  t.string :referencia
  t.references :territorio, null: false, foreign_key: true
  t.decimal :latitude, precision: 9, scale: 6, null: false
  t.decimal :longitude, precision: 9, scale: 6, null: false
  t.boolean :visivel, default: false, null: false
  t.references :autor, foreign_key: { to_table: :users, on_delete: :nullify }

  t.timestamps
end
```

| Trecho | O que faz |
| --- | --- |
| `precision: 9, scale: 6` | Até 9 dígitos, 6 depois da vírgula. Seis casas dão uma precisão de uns 10 cm, mais do que o GPS de qualquer celular |
| `:decimal`, e não `:float` | O `decimal` guarda o número exato que foi digitado. O `float` guarda uma aproximação, e `-15.816600` poderia virar `-15.81659999` |
| `t.references :autor` | Uma chave estrangeira com nome próprio: a coluna é `autor_id`, mas aponta para a tabela `users` (`to_table: :users`) |
| `on_delete: :nullify` | Se a pessoa apagar a conta, as academias que ela cadastrou **ficam**, com o `autor_id` vazio. Dado de campo não some porque alguém saiu |

> 💡 **Por que o nome ficou opcional?** Na primeira versão, o nome era obrigatório (`null: false`). Testando o cadastro, percebemos que a turma teria que **inventar** um nome para cada academia na praça. A coluna passou a aceitar vazio, numa migration separada, e a tela mostra um **título** calculado (Parte 4.4). Repare que a mudança foi feita com uma migration **nova**, e não editando a antiga: a antiga já tinha rodado, e as tabelas de ligação já dependiam dela.
>
> ```ruby
> def change
>   change_column_null :academias, :nome, true
> end
> ```

### 3.4 As tabelas de ligação

Uma academia pode ter várias categorias, e uma categoria tem várias academias. Uma relação assim, de **muitos para muitos**, precisa de uma tabela no meio, que só guarda os pares:

| academia_id | categoria_id |
| --- | --- |
| 1 | 1 |
| 2 | 1 |
| 2 | 3 |

Na migration dela, um índice **único** no par:

```ruby
t.index [ :academia_id, :categoria_id ], unique: true
```

Assim, o banco recusa a mesma academia duas vezes na mesma categoria, mesmo que um erro no código tente.

A `AcademiaEquipamento` é igual, com uma diferença: ela guarda um dado próprio, a **quantidade**.

```ruby
t.integer :quantidade, default: 1, null: false
t.index [ :academia_id, :equipamento_id ], unique: true
```

### 3.5 Os relacionamentos nos models

```ruby
class Academia < ApplicationRecord
  belongs_to :territorio
  belongs_to :autor, class_name: "User", optional: true

  has_many :academia_categorias, dependent: :destroy
  has_many :categorias, through: :academia_categorias
  has_many :academia_equipamentos, dependent: :destroy, autosave: true
  has_many :equipamentos, through: :academia_equipamentos
end
```

Leia em voz alta: *"a academia **pertence a** um território; **tem muitas** categorias, **por meio das** ligações academia–categoria"*. É quase português.

| Relacionamento | Lado | O que o Rails ganha |
| --- | --- | --- |
| `belongs_to :territorio` | Quem **tem** a chave estrangeira | `academia.territorio` devolve o território. E valida: sem território, a academia não salva |
| `has_many :academias` | O outro lado, no `Territorio` | `territorio.academias` devolve todas as academias dele |
| `has_many :categorias, through:` | Atravessando a tabela de ligação | `academia.categorias` devolve as categorias, sem nenhum `JOIN` escrito à mão |

O SQL que o Rails escreve para `academia.categorias`:

```sql
SELECT categorias.* FROM categorias
INNER JOIN academia_categorias ON categorias.id = academia_categorias.categoria_id
WHERE academia_categorias.academia_id = 2;
```

Uma linha de Ruby; seis de SQL.

**`class_name: "User"`:** o relacionamento se chama `autor`, mas o model é o `User`. Quando o nome não segue a convenção, o `class_name` avisa o Rails.

**`optional: true`:** desde o Rails 5, todo `belongs_to` é obrigatório. O autor pode ficar vazio (Parte 3.3), então avisamos.

Do outro lado, no `User`:

```ruby
has_many :academias, foreign_key: :autor_id, inverse_of: :autor, dependent: :nullify
```

O `foreign_key: :autor_id` diz qual coluna procurar, porque o Rails esperaria `user_id`.

### 3.6 O que acontece quando algo é apagado: o `dependent`

| Opção | Quando o "pai" é apagado... | Usado em |
| --- | --- | --- |
| `dependent: :destroy` | ...os filhos são apagados junto | Academia → as ligações com categorias e equipamentos. Sem a academia, a ligação não faz sentido |
| `dependent: :nullify` | ...os filhos ficam, com a chave vazia | User → academias |
| `dependent: :restrict_with_error` | ...o Rails **recusa** apagar, com uma mensagem de erro | Território e Equipamento. Não dá para apagar o território "Ceilândia" se houver academias nele |

Repare que o `on_delete: :nullify` da migration e o `dependent: :nullify` do model dizem a mesma coisa em dois lugares: o banco garante a regra mesmo que alguém apague direto pelo SQL, e o Rails a aplica quando o caminho é o model.

---

## Parte 4 — Os models

### 4.1 Um concern para o slug

O território e a categoria precisam de slug, como o equipamento desde o capítulo 0170. Copiar as mesmas linhas três vezes seria pedir para elas ficarem diferentes com o tempo.

Pense numa receita de massa básica de uma padaria. Ela é a mesma para o pão de queijo, a pizza e a esfirra: está escrita **uma vez**, e cada receita diz só "use a massa básica".

Em termos técnicos, um **concern** é um módulo com código que vários models compartilham. `app/models/concerns/tem_slug.rb`:

```ruby
# Nome obrigatório e slug gerado a partir dele, único e no formato
# letras-numeros-e-hifens. Usado em Equipamento, Territorio e Categoria.
module TemSlug
  extend ActiveSupport::Concern

  FORMATO_SLUG = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

  included do
    normalizes :slug, with: ->(slug) { slug.strip.downcase }
    before_validation :gerar_slug

    validates :nome, presence: true
    validates :slug, presence: { if: -> { nome.present? } },
                     uniqueness: true,
                     format: { with: FORMATO_SLUG, allow_blank: true }
  end

  # Usa o slug do banco: se uma edição falhar, o formulário continua no endereço certo
  def to_param = slug_in_database || slug

  private

  def gerar_slug
    self.slug = nome.to_s.parameterize if slug.blank?
  end
end
```

- O bloco **`included do ... end`** roda **dentro da classe** que incluir o concern, como se as linhas estivessem escritas lá.
- Os métodos fora do bloco viram métodos dos models.

Nos três models, uma linha:

```ruby
class Territorio < ApplicationRecord
  include TemSlug

  has_many :academias, dependent: :restrict_with_error
end
```

O `Equipamento` perdeu todas as linhas que o concern faz e ficou só com o que é dele: a trava do slug, as fotos e o guia. Os testes dos capítulos anteriores continuaram passando, o que prova que a troca não mudou o comportamento. Isso se chama **refatorar**: mudar o código por dentro sem mudar o que ele faz por fora, e os testes são a garantia.

A academia **não** usa o concern: o endereço dela é o `id` (`/academias/12`). Duas academias podem ter o mesmo nome, ou nenhum, e um slug não faria sentido.

### 4.2 A academia

```ruby
class Academia < ApplicationRecord
  # ... os relacionamentos da Parte 3.5 ...

  scope :visiveis, -> { where(visivel: true) }

  validates :categorias, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
end
```

- `validates :categorias, presence: true`: toda academia precisa de pelo menos uma categoria.
- A latitude vai de -90 (polo sul) a 90 (polo norte), e a longitude, de -180 a 180. Fora disso, o ponto não existe no planeta.

### 4.3 O atributo virtual `quantidades`

O formulário mostra a lista de todos os equipamentos, cada um com um campo de quantidade. O que chega ao servidor é algo assim:

```ruby
{ "3" => "2", "5" => "0", "7" => "1" }   # equipamento_id => quantidade
```

Não existe coluna `quantidades`. Mas o model pode ter um **atributo virtual**: um par de métodos, um que lê e outro que escreve, que o formulário usa como se fosse uma coluna.

```ruby
# Para o formulário: { equipamento_id => quantidade }
def quantidades
  academia_equipamentos.reject(&:marked_for_destruction?).to_h { |item| [ item.equipamento_id, item.quantidade ] }
end

# Recebe { "3" => "2", "5" => "0" }: quantidade zero remove o equipamento
def quantidades=(valores)
  valores.to_h.each do |equipamento_id, quantidade|
    equipamento_id = equipamento_id.to_i
    quantidade = quantidade.to_i
    item = academia_equipamentos.find { |existente| existente.equipamento_id == equipamento_id }

    if quantidade.positive?
      item ? item.quantidade = quantidade : academia_equipamentos.build(equipamento_id:, quantidade:)
    elsif item
      item.mark_for_destruction
    end
  end
end
```

Para cada equipamento:

| Quantidade | Já existia? | O que acontece |
| --- | --- | --- |
| Maior que zero | Não | `build`: cria a ligação, ainda sem salvar |
| Maior que zero | Sim | Atualiza a quantidade |
| Zero | Sim | `mark_for_destruction`: marca para apagar |
| Zero | Não | Nada |

Nada é salvo dentro deste método. Quem salva é o `autosave: true` do `has_many`: quando a academia é salva, o Rails salva junto as ligações novas, as alteradas e apaga as marcadas, **tudo ou nada**. Se a academia tiver um erro, nenhuma ligação muda.

Um método que termina com **`=`** é o jeito do Ruby de escrever um **setter**: `academia.quantidades = {...}` chama esse método. É o mesmo mecanismo que o Rails usa para `academia.nome = "..."`.

### 4.4 O título

```ruby
# Nome é opcional: na praça, nem sempre se sabe. A tela usa o título.
def titulo
  nome.presence || referencia.presence || "Academia nº #{id}"
end
```

O `presence` devolve o texto, ou `nil` se ele estiver vazio. O `||` pega o primeiro que não for `nil`. Então: o nome, se houver; senão, a referência; senão, o número.

**Por que não gravar um nome automático, como "Academia 37"?** Testamos a ideia e desistimos, por dois motivos:
- **Dois alunos salvando ao mesmo tempo** poderiam calcular o mesmo número. É o tipo de erro que só aparece no dia da pesquisa, com a turma inteira cadastrando.
- **O banco ficaria com um nome inventado.** Na exportação para análise, "Academia 37" pareceria um nome que alguém deu, e não "ninguém deu nome".

Com o título calculado, o banco continua honesto, e o moderador pode dar um nome de verdade na revisão.

### 4.5 Quem pode editar

```ruby
# Rascunho: o autor edita. Publicada: só quem modera.
def editavel_por?(user)
  return false unless user

  user.pode_moderar? || (autor_id == user.id && !visivel?)
end
```

E no `User`:

```ruby
def pode_moderar? = admin? || moderador?
```

A regra mora **no model**, e não no controller nem na view. Assim, o controller (para barrar) e a view (para mostrar ou esconder o link "Editar") fazem a mesma pergunta, e ninguém precisa repetir a regra.

---

## Parte 5 — O controller e as três regras de permissão

### 5.1 Fora do admin

```ruby
resources :academias, only: [ :index, :show, :new, :create, :edit, :update ]
```

A rota fica **fora** do `namespace :admin`: quem cadastra academias é qualquer pessoa com conta.

### 5.2 O controller

```ruby
class AcademiasController < ApplicationController
  before_action :authenticate_user!, except: [ :index, :show ]
  before_action :carregar_academia, only: [ :show, :edit, :update ]
  before_action :exigir_permissao_de_edicao, only: [ :edit, :update ]

  def index
    @academias = academias_permitidas.includes(:territorio).order(:nome)
  end

  def new
    @academia = Academia.new(categorias: Categoria.where(slug: "academia-ao-ar-livre"))
  end

  def create
    @academia = current_user.academias.build(academia_params)

    if @academia.save
      redirect_to @academia, notice: aviso_de_cadastro
    else
      render :new, status: :unprocessable_content
    end
  end

  # ... show, edit e update seguem o padrão dos capítulos anteriores ...

  private

  # Visitante: só as publicadas. Comum: as publicadas e os próprios rascunhos. Moderador e admin: todas.
  def academias_permitidas
    return Academia.visiveis unless user_signed_in?
    return Academia.all if current_user.pode_moderar?

    Academia.visiveis.or(Academia.where(autor: current_user))
  end

  def carregar_academia
    @academia = academias_permitidas.find(params[:id])
  end

  def exigir_permissao_de_edicao
    redirect_to @academia, alert: "Você não pode editar esta academia." unless @academia.editavel_por?(current_user)
  end

  # Só quem modera pode publicar: para os outros, o campo visivel é ignorado
  def academia_params
    campos = [ :nome, :referencia, :territorio_id, :latitude, :longitude ]
    campos << :visivel if current_user.pode_moderar?

    params.expect(academia: [ *campos, categoria_ids: [], quantidades: {} ])
  end
end
```

### 5.3 As três perguntas, cada uma num lugar

| Pergunta | Onde mora a resposta | O que acontece com quem não pode |
| --- | --- | --- |
| **Quem vê?** | `academias_permitidas` | O rascunho alheio nem é encontrado: 404 |
| **Quem edita?** | `editavel_por?`, no model | Volta para a página da academia, com um aviso |
| **Quem publica?** | `academia_params` | O campo `visivel` nem entra na lista. Mesmo que alguém o envie pelo DevTools, o Rails descarta |

O teste `"comum cadastra, e a academia nasce como rascunho dele, mesmo tentando publicar"` (Parte 8) prova a terceira linha: ele envia `visivel: "1"` como usuário comum e confere que a academia nasceu escondida.

### 5.4 Detalhes que valem a pena

- **`.or(...)`**: junta duas consultas com OU. *"As visíveis, OU as que eu cadastrei."*
- **`current_user.academias.build(...)`**: cria a academia **já ligada** ao autor. Ninguém consegue cadastrar em nome de outra pessoa, porque o autor nem é um campo do formulário.
- **`includes(:territorio)`**: busca os territórios de todas as academias de uma vez, evitando o problema N+1 do capítulo 0220.
- **`Academia.new(categorias: ...)`**: o formulário de cadastro já abre com "Academia ao ar livre" marcada.
- **`categoria_ids: []` e `quantidades: {}`**: o `[]` aceita uma **lista** de ids; o `{}`, um **hash** com quaisquer chaves.
- **`*campos`**: o asterisco "abre" a lista dentro da outra. `[ *[:a, :b], :c ]` vira `[:a, :b, :c]`.

---

## Parte 6 — O formulário

### 6.1 Os campos

`app/views/academias/_form.html.erb` usa o mesmo padrão dos outros formulários: o `f.aviso_erros` no topo, cada campo num `<div class="campo">` e o `f.erros_restantes` antes do botão. As novidades:

```erb
<div class="campo">
  <%= f.label :territorio_id, "Território" %>
  <%= f.collection_select :territorio_id, Territorio.order(:nome), :id, :nome,
                          { prompt: "Escolha o território" }, { required: true } %>
</div>
```

O **`collection_select`** monta um `<select>` a partir de uma lista de registros: o valor de cada opção é o `id`, e o texto é o `nome`.

```erb
<%= f.number_field :latitude, step: "any", required: true %>
```

O **`step: "any"`** deixa o campo numérico aceitar casas decimais. Sem ele, o navegador só aceitaria números inteiros e recusaria `-15.8166`.

```erb
<fieldset class="campo">
  <legend>Categorias</legend>
  <%= f.erro_de(:categorias) %>
  <%= f.collection_check_boxes :categoria_ids, Categoria.order(:nome), :id, :nome do |c| %>
    <div><%= c.check_box %> <%= c.label %></div>
  <% end %>
</fieldset>
```

O **`fieldset`** com **`legend`** agrupa campos relacionados. O leitor de tela anuncia "Categorias, grupo" antes de ler as opções.

O **`collection_check_boxes`** é o primo do `collection_select`: uma caixa de marcar para cada categoria.

```erb
<% quantidades = academia.quantidades %>
<% Equipamento.order(:nome).each do |equipamento| %>
  <div class="campo-quantidade">
    <%= label_tag "academia_quantidades_#{equipamento.id}", equipamento.nome %>
    <%= number_field_tag "academia[quantidades][#{equipamento.id}]", quantidades.fetch(equipamento.id, 0),
                         min: 0, id: "academia_quantidades_#{equipamento.id}" %>
  </div>
<% end %>
```

O nome `academia[quantidades][3]` faz o Rails montar o hash `{ "3" => "2" }` dentro de `params[:academia][:quantidades]`, que chega direto ao `quantidades=` do model.

E o campo **visível** só aparece para quem pode publicar:

```erb
<% if current_user.pode_moderar? %>
  ...
<% end %>
```

Esconder o campo é cortesia. A regra de verdade está no `academia_params` (Parte 5.3).

### 6.2 Os erros do `belongs_to` e dos grupos de campos

Testando o formulário sem território, o erro **não** aparecia embaixo do select, e sim no fim do formulário. O motivo: o `belongs_to :territorio` coloca o erro no nome da **associação**, `:territorio`, mas o campo do formulário se chama `:territorio_id`. O FormularioBuilder do capítulo 0200 procurava erros em `:territorio_id` e não achava nada.

A solução foi ensinar o builder, e não remendar o model. Um campo terminado em `_id` passa a mostrar também os erros da associação:

```ruby
# Um campo territorio_id mostra os erros de territorio_id e os da associação territorio
def atributos_do_campo(atributo)
  nome = atributo.to_s
  nome.end_with?("_id") ? [ atributo.to_sym, nome.delete_suffix("_id").to_sym ] : [ atributo.to_sym ]
end

def mensagens_de_erro(atributo)
  return [] unless object.respond_to?(:errors)

  atributos_do_campo(atributo).flat_map { |nome| object.errors.full_messages_for(nome) }
end
```

O `collection_select` entrou no builder, como o `select` do capítulo 0200. E, para os **grupos** que não passam pelo builder (as caixas de marcar e os campos `_tag`), um método público:

```ruby
# Para grupos que não passam pelo builder (caixas de marcar, campos _tag):
# mostra os erros do atributo onde for chamado
def erro_de(atributo)
  mensagens = mensagens_de_erro(atributo)
  return if mensagens.empty?

  mostrados.merge(atributos_do_campo(atributo))
  mensagem_de_erro(atributo, mensagens)
end
```

É o `<%= f.erro_de(:categorias) %>` logo depois do `<legend>`. Com isso, os três tipos de campo seguem o padrão: o campo comum, o `belongs_to` e o grupo.

### 6.3 O CSS

Testando o formulário, apareceram dois ajustes no `10-base.css`:

- O select e os campos numéricos ficavam pequenos, ao lado do rótulo, porque a regra de estilo dos campos só cobria texto, e-mail e senha. O `input[type="number"]` e o `select` entraram na lista.
- Com os rótulos como bloco (`form label { display: block; }`), o rótulo de cada caixa de marcar foi para a linha de baixo. A correção:

```css
/* Caixa de marcar e o rótulo dela ficam na mesma linha */
input[type="checkbox"] + label {
  display: inline;
}
```

O **`+`** quer dizer "o label que vem **logo depois** de uma caixa de marcar".

> 💡 No modo celular do DevTools do Chromium, a lista de opções de um `<select>` pode aparecer **fora** da tela do celular simulado. É um defeito do simulador: no Firefox e num celular de verdade, quem abre a lista é o próprio sistema, no lugar certo.

---

## Parte 7 — A navegação

A barra de abas tem espaço para quatro abas em 320 px. Com uma quinta, "Equipamentos" deixaria de caber. A aba **Início** deu lugar a **Academias**, com o ícone `map-pin` do Lucide. O "Início" continua no menu completo e no nome do site, no cabeçalho.

```erb
<%= link_to academias_path, class: "aba", aria: { current: ("page" if controller_name == "academias") } do %>
  <%= icone("map-pin") %><span>Academias</span>
<% end %>
```

No menu completo, "Academias" entrou antes de "Equipamentos". Quando o mapa chegar, essa aba vai levar a ele, que será a tela principal do projeto.

---

## Parte 8 — O seed e os testes

### 8.1 O seed

No `db/seeds.rb`, **fora** do `if Rails.env.development?`, porque o servidor também precisa deles:

```ruby
Territorio.find_or_create_by!(nome: "Ceilândia")
Categoria.find_or_create_by!(nome: "Academia ao ar livre")
```

### 8.2 Os fixtures

Cinco arquivos novos em `test/fixtures/`. Repare como os fixtures usam os **nomes** dos relacionamentos, e não os ids:

```yaml
# academias.yml
publicada:
  nome: PEC da QNM 15
  territorio: ceilandia
  latitude: -15.816600
  longitude: -48.106000
  visivel: true
  autor: ana
```

O `territorio: ceilandia` aponta para o fixture `ceilandia` de `territorios.yml`, e o Rails calcula o id. O mesmo vale para o `autor: ana`.

E uma usuária moderadora, a `bia`, em `users.yml`. O login dela é `biamod`, e não `bia`, por um motivo que vale contar: um teste do capítulo 0130 cria uma conta pelo Google com o nome "Bia" e espera o login `bia`. Com o fixture ocupando esse login, o `gerar_login` fez o que deveria e criou `bia-1`, e o teste antigo quebrou. Fixtures também ocupam espaço no banco de teste, e podem colidir com o que os outros testes esperam.

### 8.3 O que os testes conferem

No model (`academia_test.rb`):
- o autor edita o próprio rascunho, mas não depois de publicado;
- a moderadora edita qualquer academia;
- o `quantidades=` cria, altera e remove equipamentos;
- uma latitude fora do planeta é recusada;
- sem nome, o título usa a referência.

No controller (`academias_controller_test.rb`):
- o visitante vê a publicada e não vê o rascunho (404);
- o visitante não cadastra (vai para o login);
- o comum cadastra, e a academia nasce como rascunho dele, **mesmo tentando publicar**;
- o comum não edita a academia publicada;
- a moderadora publica;
- sem território, o erro aparece embaixo do campo.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 9 — Testando no navegador

1. **Como comum:** Academias → Cadastrar academia. Preencha **sem nome**, só com a referência, e com coordenadas reais: no OpenStreetMap, clique com o botão direito num lugar e escolha "Mostrar endereço". Marque alguns equipamentos e salve.
2. A página mostra o aviso de rascunho, e o título é a referência.
3. **Ainda como comum:** edite o próprio rascunho. Funciona.
4. **Numa aba anônima:** a academia não aparece na lista, e o endereço dela dá 404.
5. **Como admin ou moderador:** a academia aparece com "Rascunho". Edite, dê um nome, marque "Visível" e salve. Na aba anônima, ela aparece.
6. **De volta ao comum:** o link "Editar" sumiu da academia publicada.
7. **Clique em "Ver no mapa":** o ponto deve cair no lugar certo do OpenStreetMap.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Salvar sem território | Mostrar o erro **embaixo** do select |
| Desmarcar todas as categorias | Mostrar o erro embaixo do grupo "Categorias" |
| Latitude `120` | Recusar: não existe latitude acima de 90 |
| Como comum, enviar `academia[visivel]=1` pelo DevTools | Salvar a academia como rascunho mesmo assim |
| Como comum, abrir `/academias/<id>/edit` de uma academia de outra pessoa | Dar 404, se for rascunho; ou voltar com um aviso, se for publicada |
| Pôr quantidade `0` num equipamento que existia | Remover o equipamento da academia |
| Duas abas: na primeira, editar a academia; na segunda, publicá-la como moderador; depois, salvar a primeira | O comum ser barrado: a academia já não é rascunho |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Inflexão** | Como um tradutor que só conhece inglês: a regra que o Rails usa para passar uma palavra do singular para o plural e de volta. |
| **Chave estrangeira** | Como o número do livro na ficha de empréstimo: uma coluna que guarda o `id` de um registro de outra tabela. |
| **`belongs_to` / `has_many`** | Os dois lados de uma ligação: quem guarda a chave estrangeira pertence a alguém, e esse alguém tem muitos. |
| **Muitos para muitos** | Uma ligação em que os dois lados têm vários do outro, resolvida com uma tabela no meio. |
| **`has_many :through`** | Um relacionamento que atravessa a tabela do meio, sem `JOIN` escrito à mão. |
| **`dependent`** | O que acontece com os filhos quando o pai é apagado: apagar junto, esvaziar a chave ou recusar. |
| **Concern** | Como a massa básica da padaria: um módulo com código que vários models compartilham. |
| **Refatorar** | Mudar o código por dentro sem mudar o que ele faz por fora, com os testes como garantia. |
| **Atributo virtual** | Um par de métodos que o formulário usa como se fosse uma coluna, sem existir no banco. |
| **Setter** | Um método terminado em `=`, chamado quando se escreve `objeto.atributo = valor`. |

---

## O que aprendemos

- Antes de criar um model com nome em português, teste a pluralização.
- Chave estrangeira no banco, relacionamento no model: o banco garante, o Rails facilita.
- Uma relação de muitos para muitos precisa de uma tabela no meio, com índice único no par.
- Ao apagar, decida o destino dos filhos: apagar junto, esvaziar ou recusar.
- Código repetido em vários models vira um concern, e os testes garantem a troca.
- Dado inventado não entra no banco: o título é calculado na tela.
- Três perguntas de permissão, três lugares: quem vê, quem edita, quem publica.
- Migration que já rodou não se edita: muda-se com uma migration nova.

**Próximo capítulo:** [0240 — Localização com mapa e GPS](0240-localizacao-com-mapa-e-gps.md)

---

## Fontes

- [Rails Guides — Active Record Associations](https://guides.rubyonrails.org/association_basics.html)
- [Rails Guides — Active Record Migrations: foreign keys](https://guides.rubyonrails.org/active_record_migrations.html#foreign-keys)
- [Rails API — `ActiveSupport::Inflector::Inflections#irregular`](https://api.rubyonrails.org/classes/ActiveSupport/Inflector/Inflections.html#method-i-irregular)
- [Rails API — `ActiveSupport::Concern`](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)
- [Rails Guides — Action View Form Helpers: collection helpers](https://guides.rubyonrails.org/form_helpers.html#making-select-boxes-with-ease)
