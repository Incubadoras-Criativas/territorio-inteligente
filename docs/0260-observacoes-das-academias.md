# 0260 — Observações das academias

> **Neste capítulo:** a academia é o **lugar**; a observação é **o que alguém viu lá, num dia**. Cada visita de campo vira uma observação, com as condições do lugar (conservação, acessibilidade, limpeza, iluminação e uso), um **relato com texto formatado**, **fotos** com termo de consentimento e a escolha de aparecer ou não como autor. Nada se perde: a ficha da academia mostra a observação mais recente e todo o histórico. É também o capítulo em que duas regras repetidas viram **concerns**, e em que conhecemos o **Action Text**.

**Tag deste capítulo:** `cap-0260`

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

O `db:migrate` cria duas tabelas: a das observações e a do Action Text, que guarda os textos formatados.

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
> git switch -c estudo-0260 cap-0260
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
> git branch -D estudo-0260
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

## Parte 1 — Por que uma tabela separada?

A primeira ideia seria guardar as condições na própria academia: uma coluna para a conservação, outra para a limpeza... Mas a pesquisa de campo **volta** às academias. Se a limpeza estava ruim em novembro e boa em dezembro, guardar só "boa" apagaria a informação mais importante: **a academia melhorou**.

Por isso, cada visita vira um registro novo, numa tabela filha:

```ruby
class Academia < ApplicationRecord
  has_many :observacoes, dependent: :destroy
end

class Observacao < ApplicationRecord
  belongs_to :academia
end
```

Pense no prontuário de um posto de saúde. O paciente tem uma ficha só, e cada consulta é uma folha nova, com a data. Nenhuma consulta apaga a anterior, e é a sequência de folhas que mostra se o tratamento está funcionando.

É a **pesquisa-ação** da seção 6 do documento do hackathon em forma de dados: observar, registrar, voltar e comparar. E o custo de fazer certo desde o começo é quase o mesmo de fazer do jeito simples: uma tabela e um `has_many`. Mudar depois custaria caro, porque os dados antigos já teriam sido sobrescritos.

---

## Parte 2 — Duas regras, um lugar só: os concerns

A observação precisa de duas regras que **já existiam**: a da moderação (como a academia) e a da validação de fotos (como o equipamento). Copiar as duas seria pedir para elas ficarem diferentes com o tempo. Na **segunda** vez que uma regra aparece, ela ganha um lugar próprio.

### 2.1 `Moderavel`

`app/models/concerns/moderavel.rb`:

```ruby
# Conteúdo enviado por usuários que passa por moderação antes de ser publicado.
# Rascunho: o autor vê e edita. Publicado: todos veem, só quem modera edita.
module Moderavel
  extend ActiveSupport::Concern

  included do
    belongs_to :autor, class_name: "User", optional: true
    scope :visiveis, -> { where(visivel: true) }
  end

  class_methods do
    # Visitante: só os publicados. Comum: os publicados e os próprios rascunhos. Moderador e admin: todos.
    def permitidas_para(user)
      return visiveis unless user
      return all if user.pode_moderar?

      visiveis.or(where(autor: user))
    end
  end

  def editavel_por?(user)
    return false unless user

    user.pode_moderar? || (autor_id == user.id && !visivel?)
  end
end
```

Três partes de um concern, cada uma com o seu papel:

| Parte | Vira o quê | Exemplo |
| --- | --- | --- |
| `included do ... end` | Linhas escritas **dentro da classe** | `belongs_to :autor`, `scope :visiveis` |
| `class_methods do ... end` | Métodos **da classe** | `Academia.permitidas_para(user)` |
| Métodos soltos | Métodos **de cada registro** | `academia.editavel_por?(user)` |

O `permitidas_para` é o antigo `academias_permitidas` do controller (capítulo 0230), que subiu para o model. Agora ele serve a qualquer model moderável: `Academia.permitidas_para(user)` e `academia.observacoes.permitidas_para(user)`.

A academia ficou com uma linha no lugar de três trechos:

```ruby
class Academia < ApplicationRecord
  include Moderavel
  # ...
end
```

### 2.2 `ValidaImagens`

A validação de tipo e tamanho das fotos, do capítulo 0220, saiu do `Equipamento`. `app/models/concerns/valida_imagens.rb`:

```ruby
# Anexos de imagem: só JPG, PNG ou WebP, com até 10 MB cada.
# Uso no model: valida_imagens :capa, :fotos
module ValidaImagens
  extend ActiveSupport::Concern

  TIPOS_DE_IMAGEM = %w[image/jpeg image/png image/webp].freeze
  TAMANHO_MAXIMO = 10.megabytes

  class_methods do
    def valida_imagens(*nomes)
      validate { validar_imagens(nomes) }
    end
  end

  private

  def validar_imagens(nomes)
    nomes.each do |nome|
      anexo = public_send(nome)
      anexos = anexo.respond_to?(:attachments) ? anexo.attachments.to_a : [ anexo.attachment ].compact

      anexos.each do |item|
        errors.add(nome, "precisa ser uma imagem JPG, PNG ou WebP") unless item.blob.content_type.in?(TIPOS_DE_IMAGEM)
        errors.add(nome, "precisa ter no máximo 10 MB") if item.blob.byte_size > TAMANHO_MAXIMO
      end
    end
  end
end
```

O **`valida_imagens`** é um método de classe que se usa como as validações do próprio Rails:

```ruby
class Equipamento < ApplicationRecord
  include ValidaImagens
  valida_imagens :capa, :fotos
end

class Observacao < ApplicationRecord
  include ValidaImagens
  valida_imagens :fotos
end
```

É o mesmo jeito que o Rails usa para o `validates` e o `has_many`: um método de classe que, chamado dentro da classe, acrescenta comportamento a ela. O `*nomes` aceita quantos anexos forem passados, e o `respond_to?(:attachments)` distingue um `has_many_attached` (várias fotos) de um `has_one_attached` (uma só).

### 2.3 A refatoração tem um teste: os testes que já existiam

Os dois concerns só **mudaram de lugar** o código que já existia. A prova de que a mudança não quebrou nada são os testes da academia e do equipamento, que continuaram passando antes de qualquer linha da observação ser escrita. Refatorar sem testes é trocar a fiação de uma casa sem desligar a chave.

---

## Parte 3 — O Action Text e o Trix

### 3.1 O que é?

O relato precisa de mais do que uma caixa de texto: quem foi a campo quer destacar o importante em negrito, fazer uma lista do que viu, separar em parágrafos.

Pense na diferença entre um bilhete escrito à mão e um documento num editor de texto. O conteúdo pode ser o mesmo, mas o editor deixa organizar.

Em termos técnicos, o **Action Text** é a parte do Rails que guarda **texto formatado**, e o **Trix** é o editor que aparece no formulário, com os botões de negrito, itálico, listas e títulos. O texto fica numa tabela própria do Action Text, e não numa coluna da observação.

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails action_text:install
bin/rails db:migrate
```

O instalador cria a tabela, liga o Trix no `importmap` e cria um CSS, que foi renomeado para `06-actiontext.css`, para entrar na nossa ordem.

No model, uma linha:

```ruby
has_rich_text :relato
```

No formulário, uma linha:

```erb
<%= f.rich_textarea :relato %>
```

E, na ficha, o relato aparece já formatado e **limpo**: o Action Text remove qualquer HTML perigoso antes de mostrar, então não é preciso `html_safe`, nem há risco de XSS.

### 3.2 Desligando os anexos do Trix

O Trix deixa **arrastar imagens para dentro do texto**. Essas imagens iriam direto para o Active Storage, por um caminho próprio, **por fora** de tudo o que construímos para as fotos: o limite de tamanho, a validação de tipo e o termo de consentimento.

Por isso, os anexos do Trix foram desligados, em duas camadas. No `app/javascript/application.js`, o arquivo arrastado é recusado:

```js
// Fotos entram só pelo campo de fotos, com o termo de consentimento.
// O Trix aceitaria imagens arrastadas para o texto, por fora dessas regras.
document.addEventListener("trix-file-accept", (evento) => evento.preventDefault())
```

E, no `06-actiontext.css`, o botão de anexar some:

```css
/* Sem o botão de anexar arquivo: fotos só pelo campo de fotos */
trix-toolbar .trix-button-group--file-tools {
  display: none;
}
```

> 💡 **Toda porta de entrada precisa das mesmas regras.** Quando um sistema tem dois caminhos para a mesma coisa, as regras costumam ser lembradas em um e esquecidas no outro. Aqui, o caminho mais fácil foi fechar a segunda porta.

---

## Parte 4 — O model da observação

### 4.1 A tabela

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate model Observacao academia:references autor:references data_da_visita:date \
  conservacao:integer acessibilidade:integer limpeza:integer iluminacao:integer uso:integer \
  visivel:boolean exibir_autor:boolean termo_fotos_aceito_em:datetime
```

Antes, a pluralização: como "academia", a palavra "observação" confundiria o Rails, que pluralizaria `observacao` como `observacaos`. É mais uma linha no `config/initializers/inflections.rb`:

```ruby
inflect.irregular "observacao", "observacoes"
```

Na migration, os mesmos cuidados da academia: o `autor` com `on_delete: :nullify`, e o `visivel` e o `exibir_autor` com `default: false, null: false`.

### 4.2 As condições: enums

```ruby
ESCALA = { boa: 0, regular: 1, ruim: 2, inutilizavel: 3, nao_se_aplica: 4 }.freeze
ESCALA_DE_USO = { muito_usada: 0, pouco_usada: 1, sem_uso: 2 }.freeze
CONDICOES = %i[conservacao acessibilidade limpeza iluminacao].freeze

# Vazio quer dizer "não observado"
CONDICOES.each { |condicao| enum condicao, ESCALA, prefix: true, validate: { allow_nil: true } }
enum :uso, ESCALA_DE_USO, prefix: true, validate: { allow_nil: true }
```

Você já conhece o `enum` do capítulo 0110, nos níveis de acesso. Aqui ele aparece com três novidades:

| Trecho | Por quê |
| --- | --- |
| `prefix: true` | As quatro condições usam os **mesmos** valores (boa, ruim...). Sem o prefixo, o Rails tentaria criar quatro métodos `boa?` e daria erro. Com ele, os métodos viram `conservacao_boa?`, `limpeza_boa?`... |
| `validate: { allow_nil: true }` | Um valor fora da escala vira **erro de validação**, e não uma exceção que derruba a página. E o vazio é permitido |
| `CONDICOES.each { ... }` | Quatro enums iguais, criados num laço. É a metaprogramação do capítulo 0200 de novo |

**Vazio quer dizer "não observado".** É diferente de "não se aplica". Se ninguém conferiu a iluminação porque a visita foi de dia, o campo fica vazio. Assim, o painel nunca vai confundir "não tem como avaliar" com "esqueceram de avaliar".

O **uso** tem uma escala própria. Conservação e limpeza podem ser boas ou ruins; uma academia "muito usada" não é "boa" no mesmo sentido.

### 4.3 A data da visita

```ruby
attribute :data_da_visita, :date, default: -> { Date.current }

validates :data_da_visita, presence: true,
                           comparison: { less_than_or_equal_to: ->(_observacao) { Date.current } }
```

- O **`attribute ... default:`** faz a observação nova já nascer com a data de hoje. Dá para mudar: alguém pode lançar à noite o que viu de manhã.
- A **`comparison`** recusa datas no futuro. Ninguém observa o que ainda não aconteceu.
- O **`->`** (uma *lambda*) faz o `Date.current` ser calculado **na hora da validação**. Sem ele, a data seria calculada uma vez, quando o servidor liga, e no dia seguinte a validação estaria um dia atrasada.

### 4.4 Uma observação vazia não salva

```ruby
validate :nao_pode_ser_vazia

def nao_pode_ser_vazia
  preenchida = CONDICOES.any? { |condicao| public_send(condicao).present? } ||
               uso.present? || relato.to_plain_text.strip.present? || fotos.attached?
  errors.add(:base, "Preencha pelo menos uma condição, o relato ou uma foto.") unless preenchida
end
```

O erro vai para o **`:base`**, e não para um campo, porque não é culpa de nenhum campo específico. O FormularioBuilder mostra esses erros no `erros_restantes`, antes do botão (capítulo 0200).

O **`to_plain_text`** tira a formatação do relato. Um relato só com uma linha em branco formatada não conta como preenchido.

---

## Parte 5 — As fotos e o termo de consentimento

### 5.1 As fotos

```ruby
has_many_attached :fotos do |anexo|
  anexo.variant :miniatura, resize_to_limit: [ 160, 160 ], format: :webp
  anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
end

valida_imagens :fotos
```

O mesmo do capítulo 0220: versões menores em WebP e a validação, agora pelo concern. No formulário, o mesmo truque do "Manter esta foto", com o `signed_id`.

A foto da **observação** faz mais sentido do que uma foto da academia: ela mostra **o estado do lugar naquele dia**. O histórico de fotos vira a prova de que algo melhorou ou piorou.

### 5.2 O termo

A seção 7 do documento do hackathon pede **consentimento** e **proteção de imagens de terceiros**. O formulário tem uma caixa:

> *As fotos não mostram pessoas, ou as pessoas que aparecem autorizaram o uso.*

```ruby
attribute :termo_fotos, :boolean

validates :termo_fotos, acceptance: { allow_nil: false, message: "precisa ser aceito para enviar fotos" },
                        if: :fotos_novas?

before_save :registrar_termo, if: :fotos_novas?

def registrar_termo
  self.termo_fotos_aceito_em = Time.current
end
```

- **`attribute :termo_fotos`** é um atributo **virtual**, sem coluna: só para a caixa do formulário.
- **O que fica gravado é o horário do aceite**, no `termo_fotos_aceito_em`. É o registro que a LGPD pede: quem enviou, quando, e que declarou ter o consentimento.
- **`if: :fotos_novas?`**: o termo só é exigido quando chegam fotos **novas**.

> 💡 **Manha: o `acceptance` aceita o vazio, se você deixar.** A validação `acceptance` foi feita para caixas de "Li e aceito", e por padrão ela **não valida nada quando o valor é `nil`**. No formulário, isso não aparece: uma caixa desmarcada envia `"0"`. Mas um pedido montado sem a caixa passaria sem o termo. O teste do model pegou esse caso, e o **`allow_nil: false`** fecha a brecha. Para um termo de consentimento, vazio é "não aceitou".

### 5.3 O que é uma foto "nova"?

```ruby
# Foto nova = arquivo enviado agora. As fotos mantidas no formulário
# (pelo "Manter esta foto") já existem, e não pedem o termo de novo.
def fotos_novas?
  mudanca = attachment_changes["fotos"]
  mudanca.respond_to?(:blobs) && mudanca.blobs.any?(&:new_record?)
end
```

Pense num envelope ainda aberto em cima da mesa: dá para ver o que vai ser enviado antes de fechar e pôr no correio.

Em termos técnicos, antes do `save`, o Active Storage guarda as fotos escolhidas no **`attachment_changes`**, uma área de "mudanças pendentes". Um arquivo enviado agora vira um blob **novo**, ainda não gravado (`new_record?`). Uma foto mantida pelo checkbox aponta para um blob **que já existe**. Por isso, editar só o relato de uma observação com fotos não pede o termo de novo: as fotos que voltam são as antigas.

> 💡 **Manha: num registro já salvo, o `attach` grava na hora.** `observacao.fotos.attach(...)` numa observação **já salva** grava a foto imediatamente, sem esperar o `save` e sem passar pelas validações. Numa observação **nova**, ele só prepara. Por isso, o teste do termo usa uma observação nova (`build`), que imita o formulário. No controller, as fotos chegam por `update(fotos: [...])`, que também espera o `save`.

---

## Parte 6 — Rotas aninhadas e o controller

### 6.1 A observação mora dentro da academia

```ruby
resources :academias, only: [ :index, :show, :new, :create, :edit, :update ] do
  resources :observacoes, only: [ :new, :create, :edit, :update ]
end
```

Os endereços ficam:

| Ação | Endereço |
| --- | --- |
| Nova observação | `/academias/3/observacoes/new` |
| Editar observação | `/academias/3/observacoes/7/edit` |

Uma observação nunca existe sem a academia dela, e a URL mostra isso. As **rotas aninhadas** dão ao controller o `params[:academia_id]`, e os helpers ganham os dois objetos: `edit_academia_observacao_path(academia, observacao)`.

### 6.2 O controller

```ruby
class ObservacoesController < ApplicationController
  before_action :authenticate_user!
  before_action :carregar_academia
  before_action :carregar_observacao, only: [ :edit, :update ]
  before_action :exigir_permissao_de_edicao, only: [ :edit, :update ]

  # ... new, create, edit e update no padrão de sempre ...

  private

  def carregar_academia
    @academia = Academia.permitidas_para(current_user).find(params[:academia_id])
  end

  def carregar_observacao
    @observacao = @academia.observacoes.permitidas_para(current_user).find(params[:id])
  end

  # Só quem modera pode publicar: para os outros, o campo visivel é ignorado
  def observacao_params
    campos = [ :data_da_visita, *Observacao::CONDICOES, :uso, :relato, :exibir_autor, :termo_fotos ]
    campos << :visivel if current_user.pode_moderar?

    params.expect(observacao: [ *campos, fotos: [] ])
  end
end
```

Repare na **corrente de permissões**: primeiro, a academia precisa ser uma que a pessoa pode ver; depois, a observação precisa ser **daquela** academia **e** uma que a pessoa pode ver. Ninguém edita a observação de uma academia trocando o número na URL.

O **`find`** é a última trava: o `permitidas_para` devolve a **lista** do que a pessoa pode ver, e o `find` tira dela o registro pedido. Se ele não estiver na lista, a resposta é 404.

### 6.3 A visita única

No `AcademiasController#create`, depois de cadastrar a academia, o aluno vai direto para a primeira observação:

```ruby
redirect_to new_academia_observacao_path(@academia),
            notice: "#{aviso_de_cadastro} Agora, registre o que você observou."
```

Para quem está na praça, é um cadastro em duas telas seguidas, na mesma visita. Nas visitas seguintes, ele abre a ficha da academia e toca em "Registrar observação".

---

## Parte 7 — O formulário e a ficha

### 7.1 As escalas como botões de opção

```erb
<% (Observacao::CONDICOES + [ :uso ]).each do |condicao| %>
  <% escala = condicao == :uso ? Observacao::ESCALA_DE_USO : Observacao::ESCALA %>
  <fieldset class="campo">
    <legend><%= Observacao.human_attribute_name(condicao) %></legend>
    <%= f.erro_de(condicao) %>
    <div class="opcoes-escala">
      <% escala.each_key do |valor| %>
        <label><%= f.radio_button condicao, valor %> <%= t("escalas.#{valor}") %></label>
      <% end %>
      <label><%= f.radio_button condicao, "" %> Não observei</label>
    </div>
  </fieldset>
<% end %>
```

- **Um laço desenha os cinco grupos.** Uma condição nova na escala aparece no formulário sem mexer na view.
- **O "Não observei" envia vazio**, e o enum entende o vazio como `nil`.
- **Os textos vêm do `pt-BR.yml`**, na chave `escalas`: o banco guarda `inutilizavel`, e a tela mostra "Inutilizável".
- **Botões grandes, em duas colunas**, fáceis de tocar com o polegar.

### 7.2 A identificação opcional

```erb
<fieldset class="campo">
  <legend>Mostrar o seu identificador nesta observação?</legend>
  <label><%= f.radio_button :exibir_autor, false %> Não, mostrar só a data</label>
  <label><%= f.radio_button :exibir_autor, true %> Sim, mostrar "<%= (observacao.autor || current_user).login %>"</label>
</fieldset>
```

A seção 7 do hackathon fala em **autoria opcional** e **minimização de dados**. Por padrão, a observação aparece só com a data. Quem quiser o crédito escolhe aparecer, e aparece pelo **identificador**, e não pelo nome completo: parte de quem vai a campo é menor de idade, e o identificador já basta para o crédito.

No model:

```ruby
def autor_publico
  autor if exibir_autor?
end
```

O moderador continua vendo quem fez cada observação, com o aviso *"só moderadores veem"*.

### 7.3 A ficha: `render @observacoes`

No `AcademiasController#show`:

```ruby
@observacoes = @academia.observacoes.permitidas_para(current_user).recentes
                        .with_rich_text_relato.with_attached_fotos.includes(:autor)
```

O **`with_rich_text_relato`** e o **`with_attached_fotos`** evitam o problema N+1 do capítulo 0220, agora para os relatos e as fotos.

Na view, uma linha desenha todas:

```erb
<%= render @observacoes %>
```

É uma convenção do Rails: para cada observação da lista, ele usa o partial **`observacoes/_observacao.html.erb`**, com a variável local `observacao`. O nome do partial vem do nome do model. A mais recente vem primeiro, pelo `scope :recentes`.

No partial, as condições aparecem numa **lista de definições** (`<dl>`, `<dt>`, `<dd>`), a estrutura do HTML feita para pares "nome: valor", que o leitor de tela anuncia como tal. Só aparecem as condições observadas: o vazio não ocupa espaço na tela.

---

## Parte 8 — Os testes

### 8.1 O model

| Teste | O que garante |
| --- | --- |
| Observação vazia não salva | A regra do "pelo menos uma coisa" |
| Data no futuro é recusada | A `comparison` |
| Valor fora da escala vira erro, e não exceção | O `validate:` do enum |
| Foto nova exige o termo, e o aceite fica registrado | O consentimento e o horário gravado |
| O autor só aparece se ele quiser | A identificação opcional |

### 8.2 O controller

| Teste | O que garante |
| --- | --- |
| Depois de cadastrar a academia, vai para a primeira observação | A visita única |
| Comum registra, e a observação nasce como rascunho, mesmo tentando publicar | A moderação |
| A ficha não mostra o rascunho alheio a visitantes | O `permitidas_para` |
| A moderadora publica | O caminho da publicação |

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 9 — Testando no navegador

Como comum:
1. **Cadastre uma academia:** ao salvar, você cai em "Nova observação".
2. **Salve vazio:** aparece *"Preencha pelo menos uma condição, o relato ou uma foto"*.
3. **Marque condições e escreva no Trix**, com negrito e uma lista. A ficha mostra a observação como rascunho.
4. **Arraste uma imagem para dentro do Trix:** nada acontece.
5. **Envie uma foto sem marcar o termo:** o erro aparece. Marque e salve.
6. **Escolha aparecer como autor** e confira o identificador na ficha.

Como moderador:

7. **Publique a observação** e confira numa aba anônima: ela aparece com a data, e sem autor se o autor não quis aparecer.
8. **Edite só o relato** de uma observação com foto: o termo não é pedido de novo.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Data de amanhã | Recusar |
| `observacao[conservacao]=otima` pelo DevTools | Mostrar um erro, e não uma página de erro do servidor |
| Enviar foto com `termo_fotos` apagado do formulário pelo DevTools | Recusar: vazio não é aceite |
| Como comum, `observacao[visivel]=1` pelo DevTools | Salvar como rascunho mesmo assim |
| Abrir `/academias/<id>/observacoes/<id>/edit` de uma observação de outra pessoa | Dar 404 se for rascunho, ou voltar com um aviso se for publicada |
| Arrastar uma imagem para o Trix | Nada acontecer |
| Escrever `<script>` no relato | Aparecer como texto, sem executar |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Observação** | Como a folha de uma consulta no prontuário: o registro de uma visita, com data, que não apaga as anteriores. |
| **Pesquisa-ação** | Observar, registrar, voltar e comparar, para agir sobre o que se vê. |
| **Action Text** | A parte do Rails que guarda texto formatado. |
| **Trix** | O editor de texto formatado do Action Text. |
| **Rota aninhada** | Um recurso que mora dentro de outro na URL: `/academias/3/observacoes`. |
| **`prefix:`** (enum) | Põe o nome do campo na frente dos métodos do enum, para dois enums poderem usar os mesmos valores. |
| **Lambda** (`->`) | Um pedaço de código guardado para rodar depois, na hora certa. |
| **`attachment_changes`** | Como o envelope aberto em cima da mesa: as fotos escolhidas que ainda não foram gravadas. |
| **`render @colecao`** | Desenha um partial para cada item da lista, pelo nome do model. |
| **Lista de definições** | O `<dl>` do HTML, feito para pares "nome: valor". |

---

## O que aprendemos

- O que muda com o tempo merece uma tabela própria: o histórico é o dado.
- Na segunda vez que uma regra aparece, ela vira um concern.
- Refatorar com os testes passando é a garantia de que nada quebrou.
- Toda porta de entrada precisa das mesmas regras, ou precisa ser fechada.
- Vazio é "não observado", e não "não se aplica".
- Um termo de consentimento grava o momento do aceite, e vazio não é aceite.
- A autoria é escolha de quem contribui, e o identificador basta para o crédito.
- A URL pode contar a relação entre os dados: a observação mora dentro da academia.

**Próximo capítulo:** em breve.

---

## Fontes

- [Rails Guides — Action Text Overview](https://guides.rubyonrails.org/action_text_overview.html)
- [Trix — editor](https://github.com/basecamp/trix)
- [Rails Guides — Routing: nested resources](https://guides.rubyonrails.org/routing.html#nested-resources)
- [Rails API — `ActiveRecord::Enum`](https://api.rubyonrails.org/classes/ActiveRecord/Enum.html)
- [Rails Guides — Active Record Validations: acceptance](https://guides.rubyonrails.org/active_record_validations.html#acceptance)
- [Rails API — `ActiveSupport::Concern`](https://api.rubyonrails.org/classes/ActiveSupport/Concern.html)
- [Rails Guides — Layouts and Rendering: rendering collections](https://guides.rubyonrails.org/layouts_and_rendering.html#rendering-collections)
