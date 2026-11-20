# 0290 — Fotos escolhidas da galeria

> **Neste capítulo:** as fotos das academias, das observações e dos equipamentos deixam de ser enviadas dentro de cada formulário e passam a ser **escolhidas da galeria** do capítulo 0280, numa janela com miniaturas. Cada foto anexada vira um vínculo com **moderação**: a de quem não modera entra pendente, e só aparece para o público depois de aprovada. A capa dos equipamentos passa a ser uma dessas fotos. No caminho, conhecemos as **associações polimórficas**, o `<dialog>` do HTML e o `sanitize`, e o código repetido entre os três formulários ganha um lugar próprio.

**Tag deste capítulo:** `cap-0290`

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

O `db:migrate` cria a tabela `fotos` e remove, das observações, a coluna da data do termo, que agora mora na galeria.

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
> git switch -c estudo-0290 cap-0290
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
> git branch -D estudo-0290
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

## Parte 1 — Um ajuste na galeria: "Tirar foto"

Antes da etapa em si, um ajuste no formulário da galeria do capítulo 0280. No celular Android, o botão "Adicionar fotos" abria só a escolha de arquivos, sem oferecer a câmera. A causa era o `accept`:

```erb
accept: "image/jpeg,image/png,image/webp"
```

Quando o `accept` lista tipos específicos, o navegador do celular não tem como garantir que a câmera vai entregar um desses formatos, e então nem oferece a câmera. Com o genérico `image/*`, ela aparece. A troca é segura, porque quem confere o formato de verdade é o **servidor**, pelo `ValidaImagens`. O `accept` é só uma sugestão para o seletor do aparelho.

E já que a pesquisa é de campo, o formulário ganhou **dois botões**:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<div class="botoes-envio">
  <%= f.file_field :arquivos, id: "imagem_camera", name: "imagem[arquivos][]",
                   accept: "image/*", capture: "environment",
                   class: "visualmente-oculto",
                   data: { action: "change->envio-automatico#enviar", tamanho_maximo: Imagem::TAMANHO_MAXIMO } %>
  <label for="imagem_camera" class="botao botao-enviar">
    <span class="quando-parado">Tirar foto</span>
    <span class="quando-enviando">Enviando…</span>
  </label>

  <%= f.file_field :arquivos, multiple: true, accept: "image/*",
                   class: "visualmente-oculto",
                   data: { action: "change->envio-automatico#enviar", tamanho_maximo: Imagem::TAMANHO_MAXIMO } %>
  <%= f.label :arquivos, class: "botao botao-enviar" do %>
    <span class="quando-parado">Escolher fotos</span>
    <span class="quando-enviando">Enviando…</span>
  <% end %>
</div>
```

| Detalhe | Por quê |
| --- | --- |
| `capture: "environment"` | Abre **direto a câmera traseira**, sem passar pela escolha. Por isso este campo não tem `multiple`: é uma foto por vez |
| `name: "imagem[arquivos][]"` | Sem o `multiple`, o Rails geraria o nome sem `[]`, e o controller não receberia a foto como lista. Com o nome forçado, os dois campos chegam no **mesmo parâmetro** |
| `id: "imagem_camera"` | Dois campos do mesmo atributo teriam o mesmo `id`. O segundo continua com o padrão, que é o que o `f.label` usa |

O controller não muda: no envio, só um dos dois campos tem arquivo, e o `compact_blank` descarta o vazio. No computador, o `capture` é ignorado, e "Tirar foto" abre a escolha de arquivos normal.

> 💡 **Testando no celular, na sua rede.** Para abrir o projeto no celular durante o desenvolvimento, suba o servidor ouvindo em todos os endereços, com `bin/dev -b 0.0.0.0`, e abra no celular `http://IP-DO-SEU-PC:3000`. O IP aparece com `hostname -I`. O campo de arquivo com `capture` funciona assim, sem HTTPS, porque quem abre a câmera é o sistema do celular. Já o GPS do capítulo 0240 precisa de HTTPS ou `localhost`.

---

## Parte 2 — O que muda neste capítulo

No capítulo 0280, as fotos ganharam um lugar para ficar: a galeria. Agora, elas ganham um caminho até os registros. As fotos das academias, das observações e dos equipamentos deixam de ser enviadas **dentro** de cada formulário, e passam a ser **escolhidas da galeria**.

E com o caminho vem a moderação. As regras combinadas:

| Regra | Como fica no código |
| --- | --- |
| Uma foto de quem **não modera** entra **pendente**, e só aparece para o público depois de aprovada | O enum `situacao` do model `Foto` |
| Uma foto de **moderador ou admin** entra **aprovada** | O `anexar_imagens` olha o `pode_moderar?` de quem anexa |
| Só se anexa imagem **da própria galeria** | Duas trancas: no controller e no model |
| A foto pode ser removida **pelo autor, enquanto pendente**, e **por quem modera, sempre** | `Foto#removivel_por?` |
| **Apagar a imagem da galeria** a remove de todos os registros, com aviso | `Imagem has_many :fotos, dependent: :destroy` |
| A **capa** do equipamento é uma das fotos, escolhida pelo admin | A coluna `capa` e o `definir_capa` |
| O **termo** de uso das fotos fica só na galeria | Sai da observação |

As fotos que já estavam anexadas pelo jeito antigo eram poucas e foram descartadas.

A tela de moderação, onde moderadores e admin aprovam ou recusam as fotos pendentes, é o próximo capítulo. Até ela chegar, uma foto pode ser aprovada pelo terminal (Parte 11).

---

## Parte 3 — Uma tabela, três donos: o model `Foto`

### 3.1 O vínculo

Uma imagem da galeria pode aparecer em **vários** registros: a mesma foto da praça pode ilustrar a academia e uma observação. E cada vínculo tem a sua própria situação: a foto pode estar aprovada na academia e pendente na observação. Por isso, o vínculo é um model próprio, e não um campo da imagem.

Pense numa exposição de fotografia. O fotógrafo tem o seu acervo (a galeria). Cada vez que uma foto vai para uma exposição, ela ganha uma ficha de empréstimo: qual foto, para qual exposição, quem emprestou e se a curadoria aprovou. A mesma foto pode ter várias fichas, uma por exposição.

### 3.2 A migration, escrita à mão

Desta vez, em vez do `generate model`, foi gerada **só a migration**. Assim, nenhum arquivo de fixture é criado sozinho, e não acontece o problema do capítulo 0280.

```bash
# 📖 JÁ ESTÁ NO PROJETO
bin/rails generate migration CreateFotos
```

```ruby
# 📖 JÁ ESTÁ NO PROJETO
class CreateFotos < ActiveRecord::Migration[8.1]
  def change
    create_table :fotos do |t|
      t.references :imagem, null: false, foreign_key: true
      t.references :fotografavel, polymorphic: true, null: false
      t.references :autor, null: false, foreign_key: { to_table: :users }
      t.references :moderador, foreign_key: { to_table: :users }
      t.integer :situacao, null: false, default: 0
      t.boolean :capa, null: false, default: false
      t.datetime :moderado_em

      t.timestamps
    end

    add_index :fotos, %i[fotografavel_type fotografavel_id imagem_id],
              unique: true, name: "index_fotos_uma_vez_por_registro"
  end
end
```

| Linha | O que faz |
| --- | --- |
| `t.references :fotografavel, polymorphic: true` | Cria **duas** colunas: `fotografavel_type` (`"Academia"`, `"Observacao"` ou `"Equipamento"`) e `fotografavel_id`. É assim que uma tabela só serve a três models |
| `foreign_key: { to_table: :users }` | O autor e o moderador são usuários. Sem o `to_table`, o Rails procuraria tabelas chamadas `autors` e `moderadors` |
| `situacao`, com `default: 0` | Toda foto nasce **pendente**, que é o primeiro valor do enum |
| `capa` | Marca qual foto é a capa. Por enquanto, só os equipamentos usam |
| O índice único | Impede anexar **a mesma imagem duas vezes** ao mesmo registro. A regra é garantida pelo próprio banco |

> **O que é uma associação polimórfica?** Pense numa etiqueta de "Achados e perdidos" que diz "pertence à sala 12". Ela não serve só para salas: poderia dizer "pertence ao armário 3" ou "pertence à secretaria". A etiqueta tem dois campos: **o tipo** do lugar e **o número**. A associação polimórfica é isso: em vez de uma coluna `academia_id`, outra `observacao_id` e outra `equipamento_id`, a foto guarda o **tipo** do dono e o **id** dele. O Action Text e o próprio Active Storage usam o mesmo mecanismo.

### 3.3 O model

`app/models/foto.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# O vínculo entre uma imagem da galeria e um registro (academia, observação ou equipamento).
# Quem pode moderar anexa já aprovada; os demais anexam como pendente.
class Foto < ApplicationRecord
  belongs_to :imagem
  belongs_to :fotografavel, polymorphic: true
  belongs_to :autor, class_name: "User"
  belongs_to :moderador, class_name: "User", optional: true

  enum :situacao, { pendente: 0, aprovada: 1, recusada: 2 }

  scope :capas, -> { where(capa: true) }

  validates :imagem_id, uniqueness: { scope: %i[fotografavel_type fotografavel_id] }
  validate :imagem_da_galeria_do_autor

  def removivel_por?(user)
    return false unless user

    user.pode_moderar? || (autor_id == user.id && pendente?)
  end

  private

  def imagem_da_galeria_do_autor
    return unless imagem && imagem.user_id != autor_id

    errors.add(:imagem, "precisa ser da sua galeria")
  end
end
```

- **`removivel_por?`** segue o desenho do `editavel_por?` do concern `Moderavel`: quem modera, sempre; o autor, só enquanto a foto está pendente. Depois de aprovada, a foto passou pela curadoria, e só a curadoria a retira.
- **`imagem_da_galeria_do_autor`**: ninguém anexa uma imagem que não seja da própria galeria, nem mesmo um moderador. Esta é a **segunda tranca**. A primeira está no controller (Parte 5). Com as duas, a regra continua valendo mesmo que um controller futuro esqueça a sua parte.
- **A validação de unicidade** repete a regra do índice. O índice garante, e a validação transforma a tentativa numa mensagem de erro, em vez de uma exceção do banco.

### 3.4 A imagem sabe onde está em uso

Em `app/models/imagem.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  has_many :fotos, dependent: :destroy

  def em_uso? = fotos.exists?
```

O `dependent: :destroy` faz valer a regra combinada: **apagar a imagem a remove de todos os registros**. O `em_uso?` muda a pergunta de confirmação da galeria:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
form: { data: { turbo_confirm: imagem.em_uso? ? "Esta imagem está em uso. Quer mesmo removê-la?" : "Remover esta imagem da sua galeria?" } }
```

---

## Parte 4 — O concern `Fotografavel`

As regras das fotos são as mesmas para os três models. Então, desde o começo, elas moram num concern, como o `Moderavel`.

`app/models/concerns/fotografavel.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Registros que recebem fotos escolhidas da galeria.
module Fotografavel
  extend ActiveSupport::Concern

  included do
    has_many :fotos, as: :fotografavel, dependent: :destroy, autosave: true
  end

  # Visitante: só as aprovadas. Quem modera: todas. Os demais: as aprovadas e as próprias.
  # Filtra as fotos já carregadas: com includes, não consulta o banco de novo.
  def fotos_visiveis_para(user)
    fotos.select do |foto|
      foto.aprovada? || user&.pode_moderar? || foto.autor_id == user&.id
    end
  end

  # A foto marcada como capa ou, se não houver, a primeira aprovada.
  def foto_de_capa
    aprovadas = fotos.select(&:aprovada?)
    aprovadas.find(&:capa?) || aprovadas.min_by(&:created_at)
  end

  # Anexa imagens da galeria de quem está editando. Funciona em registros novos e já salvos:
  # as fotos são gravadas junto com o registro, no save.
  def anexar_imagens(imagens, por:)
    aprovada = por.pode_moderar?
    ja_anexadas = fotos.map(&:imagem_id)

    imagens.reject { |imagem| ja_anexadas.include?(imagem.id) }.each do |imagem|
      fotos.build(imagem: imagem, autor: por,
                  situacao: aprovada ? :aprovada : :pendente,
                  moderador: (por if aprovada), moderado_em: (Time.current if aprovada))
    end
  end

  # Marca para remover, no save, as fotos que a pessoa pode remover. As outras são ignoradas.
  def remover_fotos(ids, por:)
    fotos.select { |foto| ids.include?(foto.id) && foto.removivel_por?(por) }
         .each(&:mark_for_destruction)
  end

  # Marca uma das fotos já anexadas como capa, e desmarca as outras
  def definir_capa(foto_id)
    return if foto_id.blank?

    fotos.each { |foto| foto.capa = (foto.id == foto_id.to_i) }
  end
end
```

### 4.1 `as: :fotografavel`

É o outro lado do polimorfismo. Na `Foto`, `belongs_to :fotografavel, polymorphic: true`. Em cada dono, `has_many :fotos, as: :fotografavel`. O Rails preenche o `fotografavel_type` com o nome da classe sozinho.

### 4.2 Tudo gravado junto: `build`, `mark_for_destruction` e `autosave`

Os três métodos que mudam as fotos (`anexar_imagens`, `remover_fotos` e `definir_capa`) **não gravam nada**. Eles só preparam as mudanças na memória:

- **`fotos.build`** pendura uma foto nova no registro;
- **`mark_for_destruction`** marca uma foto para sair;
- **`foto.capa = ...`** muda a marca da capa.

Quem grava é o **`save` do registro**, graças ao `autosave: true`: ele salva o registro e, em seguida, cria, apaga e altera as fotos, tudo na mesma transação. Se a validação do registro falhar (uma data no futuro, por exemplo), **nenhuma foto é gravada nem apagada**.

É o mesmo mecanismo das quantidades de equipamentos da academia, no capítulo 0230. E é o que permite anexar fotos a uma academia **nova**, que ainda não tem id: com o `build`, o Rails grava a academia primeiro e as fotos logo depois. Um `create` direto falharia.

### 4.3 Filtrar em Ruby, e não no banco: o N+1

A ficha de uma academia mostra **várias** observações, e cada uma com as suas fotos. Se o `fotos_visiveis_para` fizesse um `where`, seriam uma consulta para as fotos de cada observação. Com dez observações, onze consultas, o famoso **N+1**.

Por isso, ele usa o **`select` do Ruby**, que trabalha sobre as fotos **já carregadas**. Quem chama carrega todas de uma vez com `includes` (Parte 7). O `foto_de_capa` segue a mesma ideia, e é o que permite mostrar a miniatura na lista de academias sem uma consulta por item.

> **N+1.** Pense em ir ao mercado buscar os ingredientes de um bolo, um por viagem: ir buscar a farinha, voltar, ir buscar os ovos, voltar... O `includes` é a lista de compras: uma viagem só, com tudo.

---

## Parte 5 — O controller: o que é igual vira concern

As academias, as observações e os equipamentos aplicam as fotos do mesmo jeito. Na segunda vez em que esse código apareceu, ele ganhou um lugar próprio: um **concern de controller**.

`app/controllers/concerns/escolhe_fotos_da_galeria.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Aplica ao registro as fotos escolhidas da galeria e as removidas no formulário.
# As imagens vêm só da galeria de quem está editando: um id de outra pessoa é ignorado.
module EscolheFotosDaGaleria
  extend ActiveSupport::Concern

  private

  def aplicar_fotos(registro)
    escolhas = params.fetch(registro.model_name.param_key, {})
                     .permit(:capa_foto_id, imagem_ids: [], remover_foto_ids: [])

    registro.anexar_imagens(current_user.imagens.where(id: escolhas[:imagem_ids]), por: current_user)
    registro.remover_fotos(Array(escolhas[:remover_foto_ids]).map(&:to_i), por: current_user)
    registro.definir_capa(escolhas[:capa_foto_id])
  end
end
```

- **`current_user.imagens.where(id: ...)`** é a **primeira tranca**. Se alguém trocar o id de uma imagem pelo DevTools, o `where` procura só na galeria de quem está logado, e simplesmente não a encontra.
- **`model_name.param_key`** devolve `"academia"`, `"observacao"` ou `"equipamento"`: a mesma chave que o `form_with` usa nos nomes dos campos. Assim, o concern serve a qualquer model `Fotografavel`.
- **Os ids das fotos ficam fora do `params.expect` de cada controller**, porque não são atributos do registro. O `permit` separado deixa isso explícito.
- **`definir_capa`** só tem efeito quando o formulário manda o `capa_foto_id`, o que acontece só no dos equipamentos.

Nos três controllers, o `create` e o `update` ficaram com a mesma forma:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  def create
    @academia = current_user.academias.build(academia_params)
    aplicar_fotos(@academia)

    if @academia.save
      # ...
  end

  def update
    @academia.assign_attributes(academia_params)
    aplicar_fotos(@academia)

    if @academia.save
      # ...
  end
```

O `update(params)` faz duas coisas de uma vez: atribui e salva. Aqui, as fotos precisam entrar **entre** uma coisa e outra, para tudo ser gravado junto. Por isso, o `update` virou `assign_attributes` + `save`.

---

## Parte 6 — O seletor da galeria

### 6.1 Um partial para os três formulários

`app/views/fotos/_seletor.html.erb`:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<%# Escolha de fotos da galeria. Uso: render "fotos/seletor", f: f %>
<% registro = f.object %>
<fieldset class="campo" data-controller="galeria-seletor">
  <legend>Fotos</legend>

  <% anexadas = registro.fotos.select(&:persisted?) %>
  <% if anexadas.any? %>
    <div class="fotos-anexadas">
      <% anexadas.each do |foto| %>
        <div class="foto-anexada">
          <%= image_tag foto.imagem.arquivo.variant(:miniatura), alt: "" %>
          <% if foto.pendente? %>
            <span class="etiqueta-rascunho">Aguardando moderação</span>
          <% end %>
          <% if local_assigns[:escolher_capa] %>
            <label>
              <%= radio_button_tag "#{f.object_name}[capa_foto_id]", foto.id, foto.capa?,
                                   id: "capa_foto_#{foto.id}" %>
              Capa
            </label>
          <% end %>
          <% if foto.removivel_por?(current_user) %>
            <label>
              <%= check_box_tag "#{f.object_name}[remover_foto_ids][]", foto.id, false, id: "remover_foto_#{foto.id}" %>
              Remover
            </label>
          <% end %>
        </div>
      <% end %>
    </div>
  <% end %>

  <button type="button" class="botao-secundario" data-action="galeria-seletor#abrir">
    <%= icone("image") %> Escolher da galeria
  </button>
  <p class="dica" data-galeria-seletor-target="resumo" role="status"></p>
  <div class="previa-fotos" data-galeria-seletor-target="previa"></div>

  <dialog class="janela-galeria" data-galeria-seletor-target="janela"
          data-action="close->galeria-seletor#atualizar">
    <header class="cabecalho-janela">
      <h2>Minha galeria</h2>
      <button type="button" class="fechar-janela" aria-label="Fechar"
              data-action="galeria-seletor#fechar">
        <%= icone("x") %>
      </button>
    </header>

    <% escolhidas = Array(params.dig(f.object_name, :imagem_ids)) %>
    <% disponiveis = current_user.imagens.recentes.with_attached_arquivo
                                 .where.not(id: anexadas.map(&:imagem_id)) %>
    <% if disponiveis.any? %>
      <div class="galeria-escolha">
        <% disponiveis.each do |imagem| %>
          <label class="opcao-imagem">
            <%= check_box_tag "#{f.object_name}[imagem_ids][]", imagem.id, escolhidas.include?(imagem.id.to_s),
                              id: "imagem_#{imagem.id}" %>
            <%= image_tag imagem.arquivo.variant(:miniatura),
                          alt: "Imagem enviada em #{l imagem.created_at, format: :short}" %>
          </label>
        <% end %>
      </div>
    <% else %>
      <p>Não há imagens disponíveis na sua galeria.</p>
    <% end %>

    <p><%= link_to "Enviar fotos para a galeria", imagens_path, target: "_blank" %></p>
    <button type="button" data-action="galeria-seletor#fechar">Pronto</button>
  </dialog>
</fieldset>
```

Cada formulário chama o partial com uma linha:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<%= render "fotos/seletor", f: f %>                      <%# academias e observações %>
<%= render "fotos/seletor", f: f, escolher_capa: true %> <%# equipamentos %>
```

| Detalhe | Por quê |
| --- | --- |
| `f.object` | O registro do formulário: uma academia, uma observação ou um equipamento |
| `f.object_name` | O prefixo dos campos daquele formulário: `"academia"`, `"observacao"` ou `"equipamento"`. Os nomes dos campos não ficam fixos no partial |
| `local_assigns[:escolher_capa]` | Uma variável **opcional** do partial. Só o formulário dos equipamentos a passa, e só ele mostra a opção "Capa" |
| `select(&:persisted?)` | Mostra como "anexadas" só as fotos já gravadas. As que foram escolhidas agora, e ainda não salvas, aparecem na prévia |
| `where.not(id: ...)` | Tira da janela as imagens que já são fotos deste registro |
| `escolhidas` | Se o formulário voltar com erro de validação, as imagens marcadas continuam marcadas. Com o campo de arquivo antigo, as fotos escolhidas se perdiam nesse caso |
| O link com `target: "_blank"` | Abre a galeria em outra aba, para a pessoa não perder o que já preencheu no formulário |

### 6.2 O `<dialog>`

O `<dialog>` é a **janela modal nativa** do HTML. Aberto com `showModal()`, ele escurece o fundo, prende o foco do teclado dentro dele e fecha com a tecla Esc, sem nenhuma biblioteca. As caixas de seleção dentro dele **continuam fazendo parte do formulário**, porque o `<dialog>` está dentro do `<form>`.

### 6.3 O controller Stimulus: `galeria_seletor_controller.js`

```js
// 📖 JÁ ESTÁ NO PROJETO
import { Controller } from "@hotwired/stimulus"

// Abre a galeria numa janela e mostra, no formulário, as imagens escolhidas.
// Um toque numa miniatura escolhida a desmarca.
export default class extends Controller {
  static targets = [ "janela", "resumo", "previa" ]

  connect() {
    this.atualizar()
  }

  abrir() {
    this.janelaTarget.showModal()
  }

  fechar() {
    this.janelaTarget.close()
  }

  atualizar() {
    const marcadas = [ ...this.janelaTarget.querySelectorAll("input[type=checkbox]:checked") ]

    this.previaTarget.replaceChildren(...marcadas.map((caixa) => this.miniatura(caixa)))
    this.resumoTarget.textContent =
      marcadas.length === 0 ? "" :
      marcadas.length === 1 ? "1 foto escolhida. Ela será anexada ao salvar." :
      `${marcadas.length} fotos escolhidas. Elas serão anexadas ao salvar.`
  }

  // Uma cópia da miniatura da janela, que desmarca a imagem ao ser tocada
  miniatura(caixa) {
    const botao = document.createElement("button")
    botao.type = "button"
    botao.className = "previa-foto"
    botao.setAttribute("aria-label", "Desmarcar esta foto")
    botao.append(caixa.closest("label").querySelector("img").cloneNode())
    botao.addEventListener("click", () => {
      caixa.checked = false
      this.atualizar()
    })
    return botao
  }
}
```

- **As caixas marcadas são a única fonte da verdade.** A prévia não guarda nada: a cada atualização, ela é **redesenhada** a partir das caixas. Por isso, a prévia e a janela nunca discordam.
- **O evento `close`** do `<dialog>` dispara de qualquer jeito que a janela feche: pelo X, pelo "Pronto" ou pela tecla Esc. Ligado ao `atualizar`, ele garante que a prévia esteja sempre em dia.
- **`cloneNode()`**: a miniatura já foi carregada dentro da janela. A cópia aparece na hora, sem baixar nada de novo.
- **"Será anexada ao salvar"** deixa claro que a foto ainda não está gravada.
- **O `connect()`** desenha a prévia assim que a página carrega. Se o formulário voltar com erro, as escolhidas reaparecem.

### 6.4 O CSS

No `50-galeria.css`:

```css
/* 📖 JÁ ESTÁ NO PROJETO */
/* A janela de escolha da galeria */
.janela-galeria {
  width: min(40rem, 100% - 2rem);
  max-height: 80vh;
  margin: auto;
  padding: var(--espaco-2);
  border: 0;
  border-radius: var(--raio);
}

.janela-galeria::backdrop {
  background: rgb(0 0 0 / 0.4);
}

.cabecalho-janela {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--espaco-1);
}

.fechar-janela {
  display: grid;
  place-items: center;
  width: 2.75rem;
  height: 2.75rem;
  padding: 0;
  border: 0;
  border-radius: 50%;
  background: none;
  color: var(--cor-texto);
}

.fechar-janela:hover {
  background: var(--cor-roxo-claro);
}

.galeria-escolha {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(90px, 1fr));
  gap: var(--espaco-1);
  margin-block: var(--espaco-2);
}

.opcao-imagem {
  position: relative;
  display: block;
  border-radius: var(--raio);
  cursor: pointer;
}

.opcao-imagem img {
  width: 100%;
  aspect-ratio: 1;
  object-fit: cover;
  border-radius: var(--raio);
}

.opcao-imagem input {
  position: absolute;
  top: 6px;
  left: 6px;
  width: 1.25rem;
  height: 1.25rem;
}

/* A imagem escolhida ganha a moldura laranja, como o avatar escolhido */
.opcao-imagem:has(input:checked) {
  outline: 3px solid var(--cor-laranja);
  outline-offset: 2px;
}

.opcao-imagem:has(input:focus-visible) {
  outline: 3px solid var(--cor-roxo);
  outline-offset: 2px;
}

/* As fotos já anexadas, no formulário */
.fotos-anexadas {
  display: flex;
  flex-wrap: wrap;
  gap: var(--espaco-2);
  margin-bottom: var(--espaco-2);
}

.foto-anexada {
  display: grid;
  gap: 4px;
  justify-items: start;
}

.foto-anexada img {
  width: 5rem;
  height: 5rem;
  object-fit: cover;
  border-radius: var(--raio);
}

/* As fotos escolhidas da galeria, ainda não salvas */
.previa-fotos {
  display: flex;
  flex-wrap: wrap;
  gap: var(--espaco-1);
}

.previa-fotos:empty {
  display: none;
}

.previa-foto {
  padding: 0;
  border: 0;
  background: none;
  cursor: pointer;
}

.previa-foto img {
  width: 5rem;
  height: 5rem;
  object-fit: cover;
  border-radius: var(--raio);
  outline: 3px solid var(--cor-laranja);
  outline-offset: 2px;
}
```

- **`margin: auto` no `<dialog>`**: o navegador centraliza o diálogo modal com margens automáticas. O nosso `00-reset.css` zera as margens de **todos** os elementos, e o diálogo ficaria grudado no topo. Esta linha devolve a centralização.
- **`width: min(40rem, 100% - 2rem)`**: no computador, a janela tem até 40rem. No celular, ocupa a tela, menos uma margem de 1rem de cada lado.
- **`::backdrop`**: o fundo escurecido atrás do diálogo modal.
- **A moldura laranja** quer dizer "escolhida", tanto na janela quanto na prévia. É o mesmo padrão da galeria de avatares do perfil.
- **`.previa-fotos:empty`**: sem nenhuma escolhida, a prévia some, e não deixa um espaço vazio.
- **O X com 44px de lado** respeita a área mínima de toque, mesmo com o ícone menor.

---

## Parte 7 — Cada model, sua troca

Os models das observações e dos equipamentos tinham `has_many_attached :fotos`, do Active Storage. O concern cria `has_many :fotos`. **Os dois não podem conviver**, porque os dois definem o método `fotos`. Por isso, cada model trocou um pelo outro de uma vez: model, formulário e páginas juntos.

### 7.1 Academias

A academia não tinha fotos próprias: bastou incluir o concern.

```ruby
# 📖 JÁ ESTÁ NO PROJETO
class Academia < ApplicationRecord
  include Moderavel
  include Fotografavel
```

No controller, as fotos são carregadas de uma vez, para a lista, a ficha e as observações da ficha:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  def index
    @academias = Academia.permitidas_para(current_user).order(:nome)
                         .includes(fotos: { imagem: { arquivo_attachment: :blob } })
  end

  def show
    @fotos = @academia.fotos_visiveis_para(current_user)
    @observacoes = @academia.observacoes.permitidas_para(current_user).recentes
                            .with_rich_text_relato
                            .includes(:autor, fotos: { imagem: { arquivo_attachment: :blob } })
  end
```

O `includes(fotos: { imagem: { arquivo_attachment: :blob } })` lê de dentro para fora: as fotos, a imagem de cada foto, o anexo de cada imagem e o blob de cada anexo. Tudo carregado numa leva só, qualquer que seja o tamanho da lista.

Na lista das academias, cada item ganhou a miniatura da **primeira foto aprovada**:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<li class="item-academia">
  <% if (capa = academia.foto_de_capa) %>
    <%= image_tag capa.imagem.arquivo.variant(:miniatura), alt: "", class: "miniatura" %>
  <% end %>
  <div>
    <strong><%= link_to academia.titulo, academia %></strong>
    <% unless academia.visivel? %>
      <br><span class="etiqueta-rascunho-texto">Rascunho</span>
    <% end %>
  </div>
</li>
```

O `alt: ""` marca a miniatura como **decorativa**: o nome da academia já está no link ao lado, e repetir o nome faria o leitor de tela anunciá-lo duas vezes. Uma foto pendente nunca enfeita a lista pública, porque o `foto_de_capa` só considera as aprovadas.

O estilo do item fica em um arquivo novo, o `45-academias.css`, um por assunto:

```css
/* 📖 JÁ ESTÁ NO PROJETO */
.item-academia {
  display: flex;
  align-items: center;
  gap: var(--espaco-2);
}
```

### 7.2 Observações

No `observacao.rb`, **saíram**:
- `include ValidaImagens` e `valida_imagens :fotos`: o formato das imagens agora é conferido na galeria;
- o bloco `has_many_attached :fotos`;
- o `termo_fotos`, a sua validação, o `before_save :registrar_termo` e os métodos `fotos_novas?` e `registrar_termo`: o termo agora é aceito na galeria.

**Entrou** o `include Fotografavel`, e a regra "não pode ser vazia" mudou num ponto:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
    preenchida = CONDICOES.any? { |condicao| public_send(condicao).present? } ||
                 uso.present? || relato.to_plain_text.strip.present? ||
                 fotos.reject(&:marked_for_destruction?).any?
```

- Uma observação **nova**, só com fotos escolhidas da galeria, conta como preenchida, porque as fotos montadas com o `build` já estão na lista.
- Uma observação que tinha **só** fotos, e teve todas marcadas para remover, volta a ser vazia, e não salva.

A coluna `termo_fotos_aceito_em` da tabela de observações perdeu o sentido e foi removida:

```bash
# 📖 JÁ ESTÁ NO PROJETO
bin/rails generate migration RemoveTermoFotosAceitoEmFromObservacoes termo_fotos_aceito_em:datetime
```

O tipo da coluna no fim do comando permite à migration **desfazer** a remoção, num `db:rollback`.

Na ficha da academia, as fotos de cada observação viraram uma grade de miniaturas, com toque para ampliar:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
  <% fotos = observacao.fotos_visiveis_para(current_user) %>
  <% if fotos.any? %>
    <ul class="galeria" role="list">
      <% fotos.each_with_index do |foto, i| %>
        <li>
          <%= link_to url_for(foto.imagem.arquivo.variant(:media)), target: "_blank" do %>
            <%= image_tag foto.imagem.arquivo.variant(:miniatura), loading: "lazy",
                          alt: "Foto #{i + 1} da observação de #{l(observacao.data_da_visita)}" %>
          <% end %>
          <% if foto.pendente? %>
            <span class="etiqueta-rascunho">Aguardando moderação</span>
          <% end %>
        </li>
      <% end %>
    </ul>
  <% end %>
```

Quem não modera vê as aprovadas e as próprias pendentes, com a etiqueta. Quem modera vê todas. O visitante, só as aprovadas.

### 7.3 Equipamentos

No `equipamento.rb`, saíram o `ValidaImagens`, o `has_one_attached :capa` e o `has_many_attached :fotos`, e entrou o `include Fotografavel`.

A **capa** passou a ser uma das fotos. Como o admin sempre pode moderar, as fotos que ele escolhe entram aprovadas, e o `foto_de_capa` devolve a marcada como capa ou, se nenhuma estiver marcada, a primeira. Na página do equipamento:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
  <% capa = @equipamento.foto_de_capa %>
  <% if capa %>
    <%= image_tag capa.imagem.arquivo.variant(:media), alt: "Foto do equipamento #{@equipamento.nome}", class: "capa" %>
  <% end %>

  <%# ...o guia... %>

  <% outras = @equipamento.fotos.select(&:aprovada?) - [ capa ] %>
  <% if outras.any? %>
    <h2>Fotos</h2>
    <ul class="galeria" role="list">
      <% outras.each_with_index do |foto, i| %>
        <li>
          <%= link_to url_for(foto.imagem.arquivo.variant(:media)), target: "_blank" do %>
            <%= image_tag foto.imagem.arquivo.variant(:miniatura), loading: "lazy",
                          alt: "Foto #{i + 1} do equipamento #{@equipamento.nome}" %>
          <% end %>
        </li>
      <% end %>
    </ul>
  <% end %>
```

O **`- [ capa ]`** tira a capa da galeria: ela já aparece grande no topo, e não se repete embaixo.

---

## Parte 8 — O guia com `sanitize`

O guia de cada equipamento é um arquivo HTML escrito por alunos, exibido dentro do layout (capítulo 0170). Até aqui, ele era exibido com `html_safe`, **sem nenhum filtro**, e a segurança dependia da revisão de cada PR.

O Brakeman, o verificador de segurança do CI, sempre avisou sobre isso, e o aviso estava marcado como aceito no arquivo `config/brakeman.ignore`. Cada aviso aceito é guardado ali por uma **impressão digital** (*fingerprint*), calculada a partir do código que gera o aviso. Neste capítulo, a consulta do `show` dos equipamentos ganhou o `includes` das fotos, a impressão digital mudou, e o aviso voltou a aparecer, com a entrada antiga marcada como obsoleta.

Em vez de só atualizar a impressão digital, o guia passou a ser exibido com **`sanitize`**:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
  <% if (conteudo = @equipamento.conteudo) %>
    <%= sanitize conteudo %>
```

O `sanitize` do Rails deixa passar o HTML comum (parágrafos, títulos, listas, imagens, links, a classe `class`) e **remove** o que é perigoso: `<script>`, atributos como `onclick`, e endereços `javascript:` em links. É como o detector de metais na entrada de um prédio: a revisão dos PRs continua, mas agora há uma segunda barreira, que funciona em todo pedido.

Com isso, o aviso deixou de existir, e a entrada obsoleta saiu do `brakeman.ignore`.

> Se um dia um guia precisar de uma tag que o `sanitize` corta, ela pode ser liberada com `sanitize conteudo, tags: ...`. Mas libere só o necessário: cada tag a mais na lista é uma porta a mais.

---

## Parte 9 — Os testes

### 9.1 O model `Foto`: `test/models/foto_test.rb`

| Teste | O que garante |
| --- | --- |
| Nasce pendente | O valor padrão da `situacao` |
| Não anexa a imagem da galeria de outra pessoa | A segunda tranca |
| Não anexa a mesma imagem duas vezes ao mesmo registro | A regra de unicidade |
| O autor remove enquanto pendente; quem modera remove sempre | O `removivel_por?` |
| Apagar a imagem remove a foto do registro | O `dependent: :destroy` da imagem |

### 9.2 Os controllers

| Teste | O que garante |
| --- | --- |
| Comum anexa imagem da própria galeria a uma academia, e a foto nasce pendente | O caminho principal |
| Imagem da galeria de outra pessoa é ignorada | A primeira tranca |
| Moderadora anexa já aprovada | A regra de quem modera |
| Registra observação só com uma foto da galeria | A regra do "não pode ser vazia", com fotos |
| Admin escolhe fotos e define a capa do equipamento | O `definir_capa` e o `foto_de_capa` |

Um detalhe que vale para qualquer teste de controller que use `params.expect`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
    patch academia_path(academia), params: { academia: { nome: academia.nome, imagem_ids: [ imagem.id ] } }
    assert_redirected_to academia_path(academia)
```

- **O `nome` vai junto, mesmo sem mudar.** O `imagem_ids` não está na lista do `params.expect(academia: [...])`, então é filtrado. Se ele fosse o único campo, a `academia` ficaria **vazia**, e o `expect` trata um hash vazio como parâmetro ausente: a resposta é **400 Bad Request**, e nada é salvo. No uso real, o formulário sempre manda os outros campos.
- **O `assert_redirected_to` logo depois do pedido**: se um dia o pedido voltar com 400, o teste falha **ali**, com uma mensagem clara. Sem ele, um teste que só confere "nenhuma foto foi criada" passaria **pelo motivo errado**.

> 💡 **Lembrete sobre fixtures.** Em `academias(:publicada)`, o nome da fixture é a **chave** do YAML, a palavra antes dos dois-pontos, e não o valor do campo `nome` do registro.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 10 — Testando no navegador

Como **comum**:

1. Na **Minha galeria**, teste o **"Tirar foto"** no celular: a câmera abre direto.
2. Edite um rascunho seu de academia → **Escolher da galeria** → marque duas → feche pelo **X**. As duas aparecem com a moldura laranja embaixo do botão, com "2 fotos escolhidas".
3. Toque numa das miniaturas da prévia: ela é desmarcada.
4. Apague a latitude e salve. A academia volta com o erro, e a foto escolhida **continua lá**.
5. Corrija e salve. A ficha mostra a foto com "Aguardando moderação". Numa aba anônima, a foto **não aparece**.
6. Registre uma observação **só com uma foto**, sem condições nem relato. Ela salva.
7. Na galeria, tente remover a imagem que está em uso: a confirmação avisa.

Como **moderadora** (a Bia, nos dados de exemplo):

8. Anexe uma foto a uma academia: ela entra sem a etiqueta.

Como **admin**:

9. Num equipamento, escolha três fotos da galeria e salve. Edite de novo, marque a segunda como **Capa** e salve. Na página pública, ela aparece grande no topo, e as outras duas embaixo. Na lista de equipamentos, aparece a miniatura dela.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Pelo DevTools, trocar o valor de uma caixa da janela pelo id de uma imagem de outra pessoa | Ignorar a imagem |
| Como comum, remover uma foto **aprovada** que você anexou | Não mostrar a opção "Remover" |
| Pelo DevTools, enviar `remover_foto_ids[]` com o id de uma foto aprovada | Não remover |
| Anexar a mesma imagem duas vezes à mesma academia | Não aparecer na janela: ela já está anexada |
| Pôr um `<script>` num guia de equipamento | Não executar: o `sanitize` remove |

---

## Parte 11 — Para quem administra o servidor

### 11.1 As fotos antigas

Os anexos do jeito antigo ficaram órfãos no banco. Depois do deploy, eles foram apagados com:

```bash
RAILS_ENV=production mise exec -- bin/rails runner 'ActiveStorage::Attachment.where(record_type: "Observacao", name: "fotos").or(ActiveStorage::Attachment.where(record_type: "Equipamento", name: %w[capa fotos])).find_each(&:purge_later)'
```

O `purge_later` apaga cada anexo e o arquivo do disco, em segundo plano, pela fila do Solid Queue.

### 11.2 Aprovar uma foto antes da tela de moderação

Até a tela de moderação chegar, no próximo capítulo, uma foto pode ser aprovada pelo terminal:

```bash
RAILS_ENV=production mise exec -- bin/rails runner 'Foto.find(ID).update!(situacao: :aprovada, moderado_em: Time.current)'
```

O `ID` é o número da foto, que aparece, por exemplo, no `name` da caixa "Remover" no formulário, pelo DevTools.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Associação polimórfica** | Como uma etiqueta que diz o **tipo** e o **número** do dono: uma tabela só pode pertencer a vários models. |
| **`as:`** | O lado do dono numa associação polimórfica: `has_many :fotos, as: :fotografavel`. |
| **`autosave: true`** | Faz o `save` do registro gravar também as mudanças nas associações: as novas, as marcadas para remover e as alteradas. |
| **`mark_for_destruction`** | Marca um registro associado para ser apagado no próximo `save` do dono. |
| **N+1** | Uma consulta para a lista e mais uma para cada item. Evitado com `includes`. |
| **Concern de controller** | Como o concern de model, mas para código repetido entre controllers. |
| **`param_key`** | O nome que o `form_with` usa como prefixo dos campos de um model: `"academia"`, `"observacao"`. |
| **`local_assigns`** | As variáveis passadas a um partial. Com ele, uma variável pode ser opcional. |
| **`<dialog>`** | A janela modal nativa do HTML. |
| **`::backdrop`** | O fundo atrás de um `<dialog>` modal. |
| **`sanitize`** | Filtra um HTML, deixando passar o comum e removendo o perigoso. |
| **Impressão digital (*fingerprint*)** | O código que identifica um aviso do Brakeman. Muda quando o código que gera o aviso muda. |
| **`capture`** | O atributo do campo de arquivo que abre a câmera do celular diretamente. |

---

## O que aprendemos

- Quando um vínculo tem dados próprios (situação, autor, moderador), ele vira um model.
- Uma tabela polimórfica serve a vários donos com as mesmas regras.
- Duas trancas para a mesma regra: uma no controller, outra no model.
- Preparar tudo na memória e gravar num `save` só faz o registro e as fotos darem certo ou errado juntos.
- Filtrar em Ruby sobre dados já carregados evita o N+1.
- Na segunda vez que um código aparece, ele ganha um lugar próprio: concern de model, concern de controller ou partial.
- A prévia redesenhada a partir das caixas marcadas nunca discorda delas: uma fonte da verdade só.
- Num teste de controller, conferir o redirecionamento logo depois do pedido evita passar pelo motivo errado.
- Um aviso de segurança que volta é uma chance de trocar o "aceito" por uma proteção de verdade.

**Próximo capítulo:** a tela de moderação, com as fotos pendentes, o contador no menu e o resumo diário por e-mail.

---

## Fontes

- [Rails Guides — Active Record Associations: Polymorphic Associations](https://guides.rubyonrails.org/association_basics.html#polymorphic-associations)
- [Rails API — `autosave` e `mark_for_destruction`](https://api.rubyonrails.org/classes/ActiveRecord/AutosaveAssociation.html)
- [Rails Guides — Active Record Query Interface: Eager Loading](https://guides.rubyonrails.org/active_record_querying.html#eager-loading-associations)
- [Rails API — `ActionController::Parameters#expect`](https://api.rubyonrails.org/classes/ActionController/Parameters.html#method-i-expect)
- [Rails API — `sanitize`](https://api.rubyonrails.org/classes/ActionView/Helpers/SanitizeHelper.html#method-i-sanitize)
- [Brakeman — Ignoring false positives](https://brakemanscanner.org/docs/ignoring_false_positives/)
- [MDN — `<dialog>`](https://developer.mozilla.org/pt-BR/docs/Web/HTML/Element/dialog)
- [MDN — atributo `capture`](https://developer.mozilla.org/en-US/docs/Web/HTML/Attributes/capture)
- [Stimulus Handbook — Targets](https://stimulus.hotwired.dev/reference/targets)
