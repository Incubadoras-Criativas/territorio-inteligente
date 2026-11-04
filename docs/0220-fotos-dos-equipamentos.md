# 0220 — Fotos dos equipamentos

> **Neste capítulo:** cada equipamento ganha uma **foto de capa**, que aparece no cartão da lista e no topo da página, e uma **galeria** de fotos abaixo do guia. O administrador envia as fotos pelo próprio formulário, e o Rails guarda os arquivos com o **Active Storage**, gerando sozinho versões menores e mais leves para o celular. Vamos também ver por que um limite de tamanho precisa de **três** camadas, e não de uma.

**Tag deste capítulo:** `cap-0220`

---

## Para ter o código deste capítulo na sua máquina

Este capítulo traz duas novidades para o seu computador: uma biblioteca do sistema e uma permissão no PostgreSQL.

**1. A `libvips`**, a biblioteca que gera as versões menores das fotos:

```bash
sudo apt install libvips42t64
```

Se o `apt` não achar o pacote, tente `sudo apt install libvips`. O nome muda entre versões do Ubuntu.

**2. O seu usuário do PostgreSQL como superusuário** (a explicação está na Parte 2.3):

```bash
sudo -u postgres psql -c "ALTER USER $USER WITH SUPERUSER;"
```

**3. O de sempre:**

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bundle install
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
> git switch -c estudo-0220 cap-0220
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
> git branch -D estudo-0220
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo e os equipamentos.
>
> ⚠️ O dump guarda os **registros** das fotos, mas não os **arquivos**, que ficam na pasta `storage/`. Se você enviou fotos de teste, elas podem aparecer quebradas depois de uma viagem no tempo. Para os estudos, não faz diferença.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar o `active_storage:install` de novo, por exemplo, criaria migrations repetidas, e o `db:migrate` daria erro.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — A decisão: onde moram as fotos?

No capítulo 0170, o texto do guia ficou num **arquivo HTML no Git**, revisado por Pull Request. A primeira ideia para as fotos foi a mesma: arquivos em `public/equipamentos/`, com o slug no nome. Mudamos de ideia antes de publicar a primeira foto, por três motivos:

1. **Quem envia as fotos não é quem escreve código.** As fotos vêm da pesquisa de campo, tiradas no celular. Exigir um Pull Request para cada foto travaria o trabalho.
2. **O servidor não deve gravar na pasta do código.** Se as fotos fossem enviadas pelo site e guardadas em `public/`, o servidor estaria mexendo em arquivos do Git, o mesmo problema que impediu a renomeação automática do slug no capítulo 0190.
3. **Foto de celular é pesada.** Uma foto tem 3 ou 4 MB. Na praça, com o pacote de dados do celular, uma lista com dez fotos assim seria lenta e cara.

Ficou assim:

| O quê | Onde mora | Quem muda |
| --- | --- | --- |
| **Texto do guia** | Arquivo HTML no Git | A turma, por Pull Request, com revisão |
| **Fotos** | Active Storage | O administrador, pelo formulário |

O método `imagem` do capítulo 0170, que procurava fotos em `public/equipamentos/`, foi removido. Como nenhuma foto tinha sido publicada, não houve nada para migrar.

---

## Parte 2 — O Active Storage

### 2.1 O que é?

Pense no guarda-volumes de um supermercado. Você entrega a mochila, recebe uma ficha com um número e guarda a ficha no bolso. A mochila fica no armário; no bolso, só a ficha.

Em termos técnicos, o **Active Storage** é a parte do Rails que cuida de arquivos enviados pelos usuários. O arquivo vai para um **serviço de armazenamento**: no nosso caso, a pasta `storage/` do servidor, mas poderia ser um serviço na nuvem. No banco ficam só as **fichas**: o nome do arquivo, o tipo, o tamanho e a qual registro ele pertence.

### 2.2 A instalação

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails active_storage:install
bin/rails db:migrate
```

A migration cria três tabelas:

| Tabela | O que guarda |
| --- | --- |
| `active_storage_blobs` | Os dados de cada arquivo: nome, tipo, tamanho e uma "impressão digital" do conteúdo |
| `active_storage_attachments` | A ligação: "o blob 7 é a capa do equipamento 3" |
| `active_storage_variant_records` | As versões menores que já foram geradas |

**Blob** é como se chama, em computação, um "monte de bytes" guardado sem que o banco saiba o que tem dentro.

### 2.3 O erro de permissão nos testes

Depois da instalação, os testes passaram a falhar com uma mensagem estranha:

```
PG::InsufficientPrivilege: ERROR: permission denied for table pg_constraint
```

O motivo: o Active Storage trouxe as **primeiras chaves estrangeiras** do projeto. A tabela `active_storage_attachments` aponta para a `active_storage_blobs`, e o banco garante que nenhuma ligação aponte para um blob que não existe.

Para carregar os fixtures, o Rails desliga essas garantias por um instante, insere os dados e depois confere se está tudo coerente. Essa conferência mexe numa tabela interna do PostgreSQL que só um **superusuário** pode alterar. Até aqui, sem chaves estrangeiras, a permissão nunca tinha sido necessária.

No computador de desenvolvimento, a solução comum é dar o papel de superusuário ao seu usuário do PostgreSQL:

```bash
sudo -u postgres psql -c "ALTER USER $USER WITH SUPERUSER;"
```

- `sudo -u postgres` roda o comando como o usuário `postgres`, o dono do banco.
- `$USER` é o seu nome de usuário no Linux, o mesmo que o PostgreSQL usa para você.

> ⚠️ **Só no seu computador.** Um superusuário pode fazer qualquer coisa no banco. No computador de desenvolvimento, isso é normal. No servidor de produção, **nunca**: lá, o Rails roda com um usuário comum, e os testes não rodam.

### 2.4 A biblioteca do sistema: `libvips`

O Rails não sabe redimensionar imagens sozinho. Quem faz isso é a **libvips**, uma biblioteca do sistema operacional, chamada pela gem `image_processing`, que já vinha no `Gemfile` desde a criação do projeto. Por isso a `libvips` precisa estar instalada em toda máquina que rode o projeto: a sua, as do laboratório e o servidor.

> 💡 **Uma decisão sobre versões.** Durante este capítulo, o Dependabot, o robô do GitHub que acompanha as dependências, abriu um PR para atualizar o `image_processing` da versão 1 para a 2. O PR foi **fechado**: o `Gemfile` pede a 1.x (`~> 1.2`), que é a que o Rails 8.1 conhece, e trocar uma versão grande no meio do protótipo é risco sem ganho. Nem toda atualização deve ser aceita na hora. Algumas esperam o momento certo.

---

## Parte 3 — O model

### 3.1 Capa e galeria

No `app/models/equipamento.rb`:

```ruby
TIPOS_DE_IMAGEM = %w[image/jpeg image/png image/webp].freeze
TAMANHO_MAXIMO = 10.megabytes

# A foto do cartão e do topo da página
has_one_attached :capa do |anexo|
  anexo.variant :miniatura, resize_to_limit: [ 160, 160 ], format: :webp
  anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
end

# A galeria, abaixo do guia
has_many_attached :fotos do |anexo|
  anexo.variant :media, resize_to_limit: [ 800, 800 ], format: :webp
end

validate :imagens_validas
```

| Trecho | O que faz |
| --- | --- |
| `has_one_attached :capa` | Uma foto por equipamento. Parece um campo do model, mas o arquivo mora nas tabelas do Active Storage |
| `has_many_attached :fotos` | Várias fotos: a galeria |
| `.freeze` | "Congela" a lista: ninguém consegue mudá-la depois, nem sem querer |
| `10.megabytes` | O Rails ensina o Ruby a entender tamanhos: `10.megabytes` é `10485760` |

Repare na semelhança com o `has_one` e o `has_many` das associações entre models. O Active Storage usa os mesmos nomes de propósito: um equipamento **tem uma** capa e **tem muitas** fotos.

### 3.2 As variantes

Pense numa gráfica que guarda o original de um cartaz e imprime cópias de vários tamanhos sob encomenda: uma para a parede, outra para o folheto. O original fica guardado, e cada tamanho só é impresso quando alguém pede, uma vez só.

Em termos técnicos, uma **variante** é uma versão transformada do arquivo original: menor, em outro formato ou cortada. O Active Storage guarda o original e gera cada variante **na primeira vez que alguém a pede**. Depois, guarda o resultado e reaproveita.

| Variante | Usada em | Transformação |
| --- | --- | --- |
| `:miniatura` | Cartão da lista | Cabe em 160×160 |
| `:media` | Página do equipamento | Cabe em 800×800 |

O `format: :webp` converte para **WebP**, um formato de imagem bem mais leve que o JPG, com a mesma qualidade visível. Uma foto de celular de 4 MB vira uma miniatura de poucos KB.

### 3.3 `resize_to_limit` ou `resize_to_fill`?

A primeira versão da miniatura usava `resize_to_fill`. No teste com a foto do alongador, que é **alta e estreita**, o cartão mostrava só o meio do poste: as alças, que são a parte que identifica o equipamento, tinham sido cortadas.

| | `resize_to_fill` | `resize_to_limit` |
| --- | --- | --- |
| O que faz | **Preenche** o quadrado, cortando as sobras | **Cabe** dentro do quadrado, sem cortar nada |
| Foto alta | Só o meio aparece | Aparece inteira, mais estreita |
| Bom para | Rostos, paisagens, fundos | Objetos, como os nossos equipamentos |

Ficou o `resize_to_limit`, com `object-fit: contain` no CSS do cartão (Parte 6). A foto inteira, mesmo pequena, identifica o equipamento melhor do que um pedaço grande dela.

> 💡 Mudar a transformação de uma variante não exige apagar nada. O Active Storage identifica cada variante pela **transformação**, e não pelo nome: com a regra nova, a miniatura nova é gerada sozinha na próxima visita.

### 3.4 Validando tipo e tamanho

O Rails **não** valida sozinho o tipo nem o tamanho dos anexos. Sem uma validação, daria para enviar um PDF de 200 MB como capa. Abaixo do `private`:

```ruby
def imagens_validas
  anexos = fotos.attachments.to_a
  anexos << capa.attachment if capa.attached?

  anexos.each do |anexo|
    unless anexo.blob.content_type.in?(TIPOS_DE_IMAGEM)
      errors.add(anexo.name.to_sym, "precisa ser uma imagem JPG, PNG ou WebP")
    end

    if anexo.blob.byte_size > TAMANHO_MAXIMO
      errors.add(anexo.name.to_sym, "precisa ter no máximo 10 MB")
    end
  end
end
```

- `fotos.attachments.to_a` e `capa.attachment` juntam numa lista só todos os anexos, inclusive os que acabaram de ser escolhidos e ainda não foram salvos.
- `anexo.blob.content_type` é o **tipo do arquivo**, que o Rails descobre lendo o começo do conteúdo, e não só pela extensão do nome.
- `anexo.name` é `"capa"` ou `"fotos"`. Assim, o erro aparece embaixo do campo certo.

---

## Parte 4 — Mostrando as fotos

### 4.1 O cartão e o problema N+1

No `EquipamentosController`:

```ruby
def index
  @equipamentos = equipamentos_permitidos.with_attached_capa.order(:nome)
end
```

Pense numa ida ao supermercado. Você pode buscar os 11 itens da lista numa viagem só, ou voltar 11 vezes, uma para cada item. Nas duas, a geladeira fica cheia, mas uma delas é bem mais lenta.

Em termos técnicos, sem o `with_attached_capa`, a lista faria **uma consulta para buscar os equipamentos e mais uma para a capa de cada um**: 11 equipamentos, 12 consultas. É o famoso **problema N+1**: 1 consulta para a lista e N para os itens. O `with_attached_capa` busca todas as capas de uma vez. É a mesma ideia do `includes`, que você vai usar nas associações entre models.

> 💡 **Veja acontecer.** Com o `bin/dev` rodando, abra a lista de equipamentos e olhe o terminal. Cada linha `SELECT` é uma consulta ao banco. Tire o `with_attached_capa`, recarregue a página e conte de novo. Depois, devolva.

No cartão, `app/views/equipamentos/index.html.erb`:

```erb
<% if equipamento.capa.attached? %>
  <%= image_tag equipamento.capa.variant(:miniatura), alt: "" %>
<% else %>
  <span class="sem-imagem" aria-hidden="true">?</span>
<% end %>
```

Quem ainda não tem capa continua com o quadrado do "?", o convite do capítulo 0170: *esta foto ainda está faltando*.

### 4.2 A página

No `show.html.erb`, a capa vai logo abaixo do título:

```erb
<% if @equipamento.capa.attached? %>
  <%= image_tag @equipamento.capa.variant(:media), alt: "Foto do equipamento #{@equipamento.nome}", class: "capa" %>
<% end %>
```

E a galeria, depois do guia:

```erb
<% if @equipamento.fotos.attached? %>
  <h2>Fotos</h2>
  <ul class="galeria" role="list">
    <% @equipamento.fotos.each_with_index do |foto, i| %>
      <li><%= image_tag foto.variant(:media), alt: "Foto #{i + 1} do equipamento #{@equipamento.nome}", loading: "lazy" %></li>
    <% end %>
  </ul>
<% end %>
```

- `each_with_index` dá cada foto e a sua posição, começando do zero. Por isso o `i + 1` no texto alternativo.
- `loading: "lazy"`: a foto só é baixada quando aparece na tela. É a mesma ideia dos Turbo Frames preguiçosos do capítulo 0160, agora feita pelo próprio navegador.

---

## Parte 5 — O formulário do admin

### 5.1 Os campos

No `admin/equipamentos/_form.html.erb`:

```erb
<div class="campo">
  <%= f.label :capa, "Foto de capa" %>
  <% if equipamento.capa.attached? && equipamento.capa.persisted? %>
    <%= image_tag equipamento.capa.variant(:miniatura), alt: "Capa atual", class: "miniatura" %>
  <% end %>
  <%= f.file_field :capa, accept: "image/jpeg,image/png,image/webp",
                          data: { tamanho_maximo: Equipamento::TAMANHO_MAXIMO } %>
  <p class="dica">JPG, PNG ou WebP, até 10 MB. Uma foto nova substitui a atual.</p>
</div>

<div class="campo">
  <%= f.label :fotos, "Fotos da galeria" %>
  <% equipamento.fotos.select(&:persisted?).each do |foto| %>
    <label class="foto-existente">
      <%= check_box_tag "equipamento[fotos][]", foto.signed_id, true, id: "manter_foto_#{foto.id}" %>
      <%= image_tag foto.variant(:miniatura), alt: "" %>
      Manter esta foto
    </label>
  <% end %>
  <%= f.file_field :fotos, multiple: true, accept: "image/jpeg,image/png,image/webp",
                           data: { tamanho_maximo: Equipamento::TAMANHO_MAXIMO } %>
  <p class="dica">Pode escolher várias de uma vez. Para remover uma foto, desmarque "Manter esta foto".</p>
</div>
```

| Trecho | O que faz |
| --- | --- |
| `f.file_field` | O campo de arquivo. No celular, ele já oferece **tirar uma foto** ou **escolher da galeria** |
| `accept: "image/..."` | O seletor de arquivos mostra só imagens. É cortesia: quem vale é a validação do model |
| `multiple: true` | Permite escolher várias fotos de uma vez |
| `persisted?` | Só mostra as fotos que **já estão salvas**. Se o formulário voltar com erro, as recém-escolhidas ainda não existem de verdade |

### 5.2 O truque do "Manter esta foto"

Num `has_many_attached`, salvar o formulário **substitui a lista inteira** de fotos. Sem nenhum cuidado, enviar uma foto nova apagaria todas as antigas.

A solução usa o **`signed_id`** de cada foto. Pense num ingresso com um carimbo que não se falsifica: quem tem o ingresso entra, e ninguém consegue fabricar um ingresso novo. Em termos técnicos, o `signed_id` é a identificação da foto, assinada com a chave secreta do Rails. O servidor confia nele porque ninguém consegue inventar um válido.

Cada foto existente vai num checkbox **marcado**, com o `signed_id` como valor:

- **Marcado:** o `signed_id` volta junto com as fotos novas, e a foto continua na galeria.
- **Desmarcado:** o navegador não envia nada dele, a foto fica de fora da lista e é removida.

Quem faz a conta é o próprio Rails: a lista que chega (os `signed_id` mantidos mais os arquivos novos) vira a galeria. O controller só precisa aceitar a lista:

```ruby
def equipamento_params
  params.expect(equipamento: [ :nome, :slug, :visivel, :capa, fotos: [] ])
end
```

O `fotos: []` aceita uma **lista** de valores, e não um só.

Usamos `check_box_tag`, e não `f.check_box`, porque o `f.check_box` acrescenta um campo escondido com `"0"` para quando a caixa está desmarcada. Aqui, desmarcado tem que ser **nada**.

### 5.3 Os erros no lugar certo

O `file_field` entrou na lista do `FormularioBuilder` do capítulo 0200:

```ruby
CAMPOS = %i[
  text_field email_field password_field search_field
  number_field telephone_field url_field date_field textarea file_field
]
```

Com isso, *"Capa precisa ser uma imagem JPG, PNG ou WebP"* aparece embaixo do campo da capa, com a borda vermelha, sem nenhuma linha a mais no formulário.

### 5.4 Uma limitação de todo site

Se o formulário voltar com erro, os arquivos escolhidos **somem** do campo, e é preciso escolher de novo. Não é um defeito nosso: por segurança, o navegador não deixa uma página preencher um campo de arquivo sozinha. Senão, um site mal-intencionado poderia "escolher" um arquivo do seu computador e enviá-lo sem você perceber.

---

## Parte 6 — O CSS

### 6.1 O campo de arquivo estourando a tela

O campo de arquivo tem uma largura natural, a do botão "Escolher arquivo" mais o texto "Nenhum arquivo escolhido", maior que 320 px. No primeiro teste no celular, ele empurrou a página para o lado, como o botão do Devise no capítulo 0200.

Trocar o campo por um botão próprio, feito à mão, perderia o que ele já faz de graça: a câmera do celular, o nome do arquivo escolhido e o suporte ao leitor de tela. A solução foi só de CSS, no `15-formularios.css`:

```css
input[type="file"] {
  width: 100%;
  max-width: 100%;
  font-size: 0.875rem;
}

/* O botão "Escolher arquivo", com a cara dos nossos botões */
input[type="file"]::file-selector-button {
  margin-right: var(--espaco-1);
  padding: var(--espaco-1) var(--espaco-2);
  border: 2px solid var(--cor-roxo);
  border-radius: var(--raio);
  background: var(--cor-branco);
  color: var(--cor-roxo);
  font: inherit;
  font-weight: 700;
  cursor: pointer;
}

input[type="file"]::file-selector-button:hover {
  background: var(--cor-roxo-claro);
}
```

O **`::file-selector-button`** é o pseudo-elemento do botão "Escolher arquivo". Ele aceita CSS como qualquer botão. O estilo é de botão **secundário** (contorno roxo, fundo branco), para não competir com o **Salvar**.

O texto "Escolher arquivo" e "Nenhum arquivo escolhido" vem do navegador, no idioma do sistema, e não dá para trocar sem JavaScript.

### 6.2 As fotos

No `40-equipamentos.css`:

```css
.cartao-equipamento img {
  width: 4rem;
  height: 4rem;
  border-radius: var(--raio);
  object-fit: contain;
}

.capa,
.galeria img {
  width: 100%;
  height: auto;
  border-radius: var(--raio);
}

.galeria {
  display: grid;
  gap: var(--espaco-2);
  padding: 0;
}
```

O **`object-fit: contain`** encaixa a foto inteira no quadrado de 4 rem, sem esticar nem cortar. O espaço que sobra fica com o fundo branco do cartão. As miniaturas do formulário do admin usam a mesma regra, para o admin ver a capa como ela vai aparecer no cartão.

---

## Parte 7 — Limite de tamanho em três camadas

### 7.1 O problema

A validação do model roda **depois** que o arquivo inteiro chegou ao servidor. Ela impede que o arquivo seja **guardado**, mas o upload já aconteceu. Alguém enviando um arquivo de 2 GB ocuparia a conexão e o disco do servidor até o fim do envio, só para ouvir um "não" no final.

Não é uma falha do Rails: o servidor sempre precisa receber o pedido para a aplicação saber o que tem dentro. A proteção precisa estar **antes** do Rails.

### 7.2 As três camadas

Pense na entrada de um show. Na fila, um aviso diz: "proibido entrar com garrafas". No portão, a segurança confere as bolsas. E, lá dentro, quem achar uma garrafa ainda pode retirá-la. Cada camada pega o que a anterior deixou passar.

| Camada | Onde | Para quê |
| --- | --- | --- |
| **Navegador** | Controller Stimulus | **Avisar na hora**, antes de enviar |
| **Servidor web** | Nginx | **Barrar** o pedido grande antes de chegar ao Rails |
| **Model** | `imagens_validas` | **A última palavra**, valendo para qualquer caminho |

### 7.3 No navegador

O `validacao_controller.js` do capítulo 0210 ganhou uma conferência de tamanho para os campos de arquivo:

```js
// Campos de arquivo com data-tamanho-maximo: confere antes de enviar
conferirTamanho(campo) {
  const maximo = Number(campo.dataset.tamanhoMaximo)
  if (campo.type !== "file" || !maximo) return

  const grande = [ ...campo.files ].find((arquivo) => arquivo.size > maximo)
  campo.setCustomValidity(grande ? `"${grande.name}" passa de ${maximo / 1024 / 1024} MB.` : "")
}

// Ao escolher um arquivo: confere na hora
escolher(event) {
  if (this.validavel(event.target)) this.conferir(event.target)
}
```

- O `conferir` chama o `conferirTamanho` antes do `checkValidity`.
- O **`setCustomValidity`** cria uma regra nossa: com um texto, o campo fica inválido; com texto vazio, volta a ser válido. O `checkValidity` passa a respeitá-la, e o `mensagem` devolve esse texto quando a regra quebrada é `customError`.
- O evento **`change`**, ligado ao `escolher` no `data-action` do `<main>`, acontece quando a pessoa escolhe os arquivos. O erro aparece **na hora**, antes de qualquer envio.

O limite vem do model, pelo atributo `data-tamanho-maximo` do campo: `data: { tamanho_maximo: Equipamento::TAMANHO_MAXIMO }`. A regra fica num lugar só, e o navegador só a lê. É o mesmo princípio do `@minimum_password_length` do capítulo 0210.

### 7.4 No Nginx

Na configuração do site no servidor:

```nginx
client_max_body_size 50m;
```

O Nginx recusa o pedido grande **enquanto ele ainda está chegando**, com o erro **413** (*"pedido grande demais"*), e o pedido nem chega ao Rails. São 50 MB, e não 10, porque um envio pode trazer várias fotos de uma vez.

> ⚠️ **O padrão do Nginx é 1 MB.** Sem essa linha, a primeira foto de celular enviada no servidor daria erro 413. É uma das primeiras coisas a configurar quando o projeto for para a VPS.

---

## Parte 8 — Os testes

### 8.1 Os arquivos de teste

Os testes usam dois arquivos em `test/fixtures/files/`:

- **`foto.jpg`:** uma foto pequena, com menos de 100 KB. Arquivos grandes deixam o repositório pesado para todo mundo que o clonar.
- **`nao-e-imagem.txt`:** um arquivo de texto, para testar a recusa.

### 8.2 O model

```ruby
test "aceita uma capa JPG" do
  equipamento = equipamentos(:remada)
  equipamento.capa.attach(io: file_fixture("foto.jpg").open, filename: "foto.jpg", content_type: "image/jpeg")
  assert equipamento.valid?
end

test "recusa um arquivo que não é imagem" do
  equipamento = equipamentos(:remada)
  equipamento.capa.attach(io: file_fixture("nao-e-imagem.txt").open, filename: "nao-e-imagem.txt", content_type: "text/plain")
  assert_not equipamento.valid?
  assert_includes equipamento.errors[:capa].first, "JPG, PNG ou WebP"
end
```

O `file_fixture("foto.jpg")` devolve o caminho de um arquivo em `test/fixtures/files/`, e o `.open` abre o arquivo para o `attach` ler.

### 8.3 O formulário

```ruby
test "admin envia a capa e uma foto da galeria" do
  sign_in users(:admin)
  equipamento = equipamentos(:rascunho)

  patch admin_equipamento_url(equipamento), params: { equipamento: {
    capa: fixture_file_upload("foto.jpg", "image/jpeg"),
    fotos: [ fixture_file_upload("foto.jpg", "image/jpeg") ]
  } }

  equipamento.reload
  assert equipamento.capa.attached?
  assert_equal 1, equipamento.fotos.count
end

test "arquivo que não é imagem mostra o erro embaixo do campo" do
  sign_in users(:admin)

  patch admin_equipamento_url(equipamentos(:rascunho)), params: { equipamento: {
    capa: fixture_file_upload("nao-e-imagem.txt", "text/plain")
  } }

  assert_response :unprocessable_content
  assert_select "#equipamento_capa_erro", text: /JPG, PNG ou WebP/
end
```

O **`fixture_file_upload`** simula um arquivo escolhido no formulário, como se a pessoa tivesse clicado em "Escolher arquivo".

O segundo teste confere três capítulos de uma vez: a validação do model (este), o `FormularioBuilder` (0200) e o código 422 (0190).

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 9 — Testando no navegador

Entre como admin e, em 320 px:

1. **Capa:** envie uma foto de celular a um equipamento. Ela aparece no cartão da lista e no topo da página.
2. **Galeria:** envie 3 fotos de uma vez. Depois, envie mais uma: as 3 antigas continuam.
3. **Remover:** desmarque "Manter esta foto" numa delas e salve. Ela some.
4. **Arquivo errado:** tente um PDF como capa. O erro aparece embaixo do campo.
5. **O peso:** no DevTools, aba **Network**, filtre por **Img** e compare o tamanho da miniatura do cartão com o da foto original.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Escolher uma imagem com mais de 10 MB | Mostrar o erro **na hora**, antes de enviar |
| Renomear um `.txt` para `.jpg` e enviar | Recusar: o Rails descobre o tipo pelo **conteúdo**, e não pelo nome |
| Desmarcar **todas** as fotos e salvar | Remover a galeria inteira, e a página não mostrar mais o título "Fotos" |
| Enviar uma foto e, no mesmo envio, apagar o nome do equipamento | Voltar com o erro do nome, e a foto escolhida sumir do campo (Parte 5.4) |
| Abrir a lista com o terminal do `bin/dev` à vista | Ver poucas consultas `SELECT`, mesmo com várias capas (Parte 4.1) |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Active Storage** | Como o guarda-volumes do supermercado: o arquivo fica no armário, e o banco guarda só a ficha. |
| **Blob** | Um "monte de bytes" guardado sem que o banco saiba o que tem dentro. |
| **Variante** | Como as cópias de um cartaz em vários tamanhos: uma versão transformada do original, gerada uma vez e guardada. |
| **WebP** | Um formato de imagem bem mais leve que o JPG, com a mesma qualidade visível. |
| **`signed_id`** | Como um ingresso carimbado: a identificação de um arquivo, assinada para não ser falsificada. |
| **Problema N+1** | Como voltar ao supermercado uma vez por item: uma consulta para a lista e mais uma para cada item. |
| **Chave estrangeira** | Uma garantia do banco de que uma ligação nunca aponta para um registro que não existe. |
| **Superusuário** | Um usuário do banco que pode fazer qualquer coisa. Só no computador de desenvolvimento. |
| **Erro 413** | A resposta "pedido grande demais", dada antes de o pedido chegar à aplicação. |

---

## O que aprendemos

- Cada tipo de dado mora onde faz sentido: texto revisado no Git, fotos enviadas no Active Storage.
- O servidor não grava na pasta do código.
- Foto de celular é pesada: o usuário na praça recebe versões menores, em WebP.
- Para objetos, a foto **inteira** pequena vale mais que um pedaço grande.
- Num `has_many_attached`, salvar substitui a lista: o `signed_id` mantém o que deve ficar.
- O problema N+1 se resolve buscando tudo de uma vez.
- Limite de tamanho tem três camadas: o navegador avisa, o Nginx barra e o model decide.
- Nem toda atualização de gem entra na hora: algumas esperam o momento certo.

**Próximo capítulo:** [0230 — Academias](0230-academias.md)

---

## Fontes

- [Rails Guides — Active Storage Overview](https://guides.rubyonrails.org/active_storage_overview.html)
- [Rails Guides — Active Storage: transforming images](https://guides.rubyonrails.org/active_storage_overview.html#transforming-images)
- [image_processing — `resize_to_limit` e `resize_to_fill`](https://github.com/janko/image_processing/blob/master/doc/vips.md)
- [MDN — `::file-selector-button`](https://developer.mozilla.org/en-US/docs/Web/CSS/::file-selector-button)
- [MDN — `object-fit`](https://developer.mozilla.org/en-US/docs/Web/CSS/object-fit)
- [MDN — `setCustomValidity`](https://developer.mozilla.org/en-US/docs/Web/API/HTMLObjectElement/setCustomValidity)
- [Nginx — `client_max_body_size`](https://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size)
