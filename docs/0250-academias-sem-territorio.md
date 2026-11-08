# 0250 — Academias sem território

> **Neste capítulo:** testando o cadastro com a turma, descobrimos que um campo não servia: o **território**. Ele pedia ao usuário uma informação que as coordenadas já contêm, e cada um escolhia de um jeito. Vamos **remover** o território do projeto, com uma migration que apaga uma tabela e ainda pode ser desfeita. E o mapa do cadastro passa a abrir no **Marco Zero do DF**, localizando a pessoa sozinho quando ela já deu permissão antes.

**Tag deste capítulo:** `cap-0250`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails db:migrate
bin/rails test
```

O `db:migrate` remove a coluna `territorio_id` das academias e apaga a tabela `territorios`.

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
> git switch -c estudo-0250 cap-0250
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
> git branch -D estudo-0250
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

## Parte 1 — O que o teste com a turma mostrou

No capítulo 0230, o cadastro de academias tinha um campo **Território**, escolhido numa lista. No teste com a turma, ficou claro que ele causava mais problema do que resolvia:

- **A informação já estava lá.** Depois do capítulo 0240, toda academia tem latitude e longitude. Saber em que região ela fica é uma conta a partir dessas coordenadas, e não uma pergunta para o usuário.
- **Cada um escolhia de um jeito.** Uma academia no limite entre duas regiões podia ser cadastrada em qualquer uma delas, dependendo de quem estivesse com o celular na mão.
- **A tabela não tinha uso.** Ela tinha uma linha só, "Ceilândia", e nenhuma tela consultava o território.

> 💡 **Dado que pode ser calculado não deve ser digitado.** Cada campo de formulário é uma chance de erro. Se o sistema consegue descobrir uma informação sozinho, perguntar ao usuário só abre espaço para respostas diferentes sobre a mesma coisa.

O documento do hackathon pede um **painel por território**. Quando chegarmos nele, o território volta, mas **calculado** a partir das coordenadas, consultando os limites das regiões. Remover agora não fecha essa porta: com as migrations, acrescentar uma coluna depois é simples. E remover agora, enquanto não há dados de campo, custa uma migration; depois, custaria mais.

---

## Parte 2 — Uma migration que apaga, mas pode ser desfeita

### 2.1 A migration

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate migration RemoverTerritorios
```

```ruby
class RemoverTerritorios < ActiveRecord::Migration[8.1]
  def change
    remove_reference :academias, :territorio, foreign_key: true, index: true

    drop_table :territorios do |t|
      t.string :nome
      t.string :slug
      t.timestamps
      t.index :slug, unique: true
    end
  end
end
```

### 2.2 Por que descrever a tabela que estamos apagando?

Pense numa obra em que se derruba uma parede. Se o mestre de obras anotar antes **como a parede era**, dá para reconstruí-la depois, se o dono mudar de ideia. Sem a anotação, a parede some para sempre.

Em termos técnicos, o método **`change`** de uma migration sabe ser **desfeito** com o `bin/rails db:rollback`: o Rails inverte cada comando sozinho. Um `create_table` vira `drop_table`; um `add_column` vira `remove_column`. Mas o caminho contrário precisa de informação: para transformar um `drop_table` num `create_table`, o Rails precisa saber **quais colunas** a tabela tinha. O bloco depois do `drop_table` é essa anotação. Sem ele, o `db:migrate` funciona, mas o `db:rollback` dá erro.

O mesmo vale para o `remove_reference`: o `foreign_key: true` e o `index: true` dizem como recriar a coluna, a chave estrangeira e o índice.

> ⚠️ **Desfazer recria a estrutura, não os dados.** Depois de um rollback, a tabela `territorios` volta vazia, e nenhuma academia aponta para território algum. Quando uma migration apaga dados, o rollback devolve as gavetas, mas não o que estava dentro delas.

### 2.3 A ordem importa

Primeiro sai a chave estrangeira das academias; depois, a tabela para a qual ela apontava. O PostgreSQL não deixa apagar uma tabela que outra ainda referencia, por causa da garantia de chave estrangeira do capítulo 0230. No rollback, o Rails faz tudo na ordem inversa: primeiro recria a tabela, depois a coluna que aponta para ela. A coerência se mantém nos dois sentidos.

---

## Parte 3 — Remover tudo o que dependia dele

Uma tabela não vive sozinha: em volta dela há um model, fixtures, seed, traduções, campos de formulário e trechos de view. Tudo isso saiu:

| Onde | O que saiu |
| --- | --- |
| `app/models/territorio.rb` | O model inteiro (`git rm`) |
| `app/models/academia.rb` | O `belongs_to :territorio` |
| `app/controllers/academias_controller.rb` | O `:territorio_id` dos parâmetros permitidos e o `includes(:territorio)` |
| `app/views/academias/_form.html.erb` | O select do território |
| `app/views/academias/index.html.erb` e `show.html.erb` | O nome do território na lista e na ficha |
| `db/seeds.rb` | A criação do território "Ceilândia" |
| `config/locales/pt-BR.yml` | As traduções do atributo |
| `test/fixtures/territorios.yml` | O arquivo inteiro (`git rm`) |
| `test/fixtures/academias.yml` | As linhas `territorio: ceilandia` |

O **`git rm`** apaga o arquivo e já avisa o Git, que registra a remoção no próximo commit.

### 3.1 Procurando o que ficou para trás

Depois de remover, uma busca confere se nada ficou esquecido:

```bash
grep -rn "territorio\b\|Territorio\b\|territorios\|territorio_id" app test db/seeds.rb config/locales
```

O **`\b`** marca um limite de palavra. Sem ele, o `grep` pegaria também o `TerritorioInteligente`, o nome do módulo da aplicação, e a lista ficaria cheia de falsos alarmes. Mesmo assim, ainda aparecem alguns: o espaço e o hífen também contam como limite de palavra, então o nome do projeto, "Território Inteligente" e "territorio-inteligente", também aparece. A busca não decide sozinha: ela mostra os candidatos, e alguém olha cada um.

Essa conferência revelou um detalhe antigo: o título do site, na aba do navegador, estava escrito **"Territorio Inteligente"**, sem acento. Foi corrigido no mesmo PR.

### 3.2 O teste que mudou

O teste *"sem território, o erro aparece embaixo do campo"* perdeu o sentido. No lugar dele, um teste do que agora é essencial, o ponto no mapa:

```ruby
test "sem coordenadas, o erro aparece embaixo da latitude" do
  sign_in users(:ana)
  post academias_url, params: dados_validos(latitude: "", longitude: "")
  assert_response :unprocessable_content
  assert_select "#academia_latitude_erro"
end
```

Repare que o FormularioBuilder continuou com o `collection_select` e o tratamento dos erros de associação, criados para o território no capítulo 0230. Eles são gerais, e vão servir para outros formulários.

---

## Parte 4 — O mapa abre no Marco Zero

### 4.1 O centro padrão

No capítulo 0240, o mapa abria no centro de Ceilândia. Sem o território, o projeto não está mais preso a uma região, e o centro padrão passou a ser o **Marco Zero do DF**, na Rodoviária do Plano Piloto, com um zoom que mostra o DF inteiro:

```js
// Marco Zero do DF, na Rodoviária do Plano Piloto, para quando ainda não há ponto
static values = { centro: { type: Array, default: [ -15.7942, -47.8825 ] } }
```

```js
this.mapa = L.map(this.mapaTarget).setView(ponto || this.centroValue, ponto ? 17 : 11)
```

### 4.2 Mostrar não é preencher

O mapa **mostra** o Marco Zero, mas **não coloca o pino** nem preenche os campos. Os campos de latitude e longitude continuam vazios até a pessoa marcar o ponto.

Isso é de propósito. Se o mapa já preenchesse os campos com o Marco Zero, o `required` estaria satisfeito, e quem esquecesse de marcar o ponto salvaria a academia em cima da Rodoviária, sem erro nenhum. Os campos vazios são a garantia de que **alguém escolheu o ponto de verdade**.

### 4.3 Localizar sozinho, mas só com permissão

```js
if (ponto) {
  this.colocarPino(ponto)
} else {
  this.localizarSeJaPermitido()
}
```

```js
// Se a pessoa já permitiu a localização antes, localiza sozinho, sem perguntar.
// Se não, espera o toque no botão: pedir a localização sem ação da pessoa é má prática.
async localizarSeJaPermitido() {
  if (!navigator.permissions || !window.isSecureContext) return

  try {
    const permissao = await navigator.permissions.query({ name: "geolocation" })
    if (permissao.state === "granted") this.localizar()
  } catch {
    // Navegador sem suporte a essa consulta: segue com o botão
  }
}
```

Pense na diferença entre um vizinho que já tem a chave da sua casa e um desconhecido batendo à porta. Quem já tem a chave entra sem tocar a campainha; o desconhecido espera você abrir.

Em termos técnicos, o **`navigator.permissions.query`** pergunta ao navegador o **estado** de uma permissão, sem pedir nada à pessoa:

| Estado | Quer dizer | O que o controller faz |
| --- | --- | --- |
| `granted` | A pessoa já permitiu antes | Localiza sozinho |
| `prompt` | Ainda não decidiu | Espera o toque no botão |
| `denied` | Já recusou | Espera o toque no mapa |

**Por que não pedir a localização assim que o formulário abre?** Porque a pergunta apareceria do nada, sem a pessoa ter feito coisa alguma. Muita gente recusa por susto, e os navegadores passam a esconder os pedidos de sites que fazem isso. A pergunta tem que vir **depois** de um gesto da pessoa, como o toque em "Usar minha localização".

### 4.4 `async` e `await`

A consulta de permissão é **assíncrona**, como o GPS do capítulo 0240: a resposta chega depois. O **`async`** marca um método que espera respostas desse tipo, e o **`await`** espera a resposta **sem travar a página**: enquanto ela não chega, o resto do formulário continua funcionando.

O **`try` / `catch`** é a rede de proteção: alguns navegadores não sabem responder a essa consulta e dão erro. Nesse caso, o controller não faz nada, e o botão continua lá.

---

## Parte 5 — Um bug encontrado pela turma

Durante os testes, um aluno percebeu que, ao rolar o formulário no celular, **o mapa passava por cima da barra de abas**. A causa: o Leaflet organiza o mapa em camadas com `z-index` de até 1000, e a nossa barra usa um número bem menor.

A correção mais óbvia, aumentar o `z-index` da barra, só adia o problema: a próxima biblioteca que usar um número maior passa por cima de novo. A correção certa é fechar o mapa num **contexto de empilhamento** próprio, com a propriedade CSS **`isolation`**, para os números do Leaflet só valerem lá dentro.

Em vez de corrigir aqui, o bug virou uma **issue** para o aluno que o encontrou: com a pista do `isolation`, ele mesmo localiza o arquivo de CSS, faz a correção e abre o Pull Request. É assim que funciona num projeto de código aberto: quem encontra um problema pode também resolvê-lo.

---

## Parte 6 — Testando no navegador

1. **Cadastrar academia:** o mapa abre no Plano Piloto, mostrando o DF, sem pino e com os campos vazios.
2. **Salve sem marcar o ponto:** o erro aparece embaixo da latitude.
3. **"Usar minha localização"**, e permita. Saia e abra o cadastro de novo: desta vez, ele localiza sozinho, sem perguntar.
4. **Edite uma academia que já existe:** o mapa abre no ponto dela.
5. **A lista e a ficha** não mostram mais o território.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| `bin/rails db:rollback` e depois `bin/rails db:migrate` | Desfazer e refazer a remoção sem erro (é o bloco do `drop_table` funcionando) |
| Recusar a localização e abrir o cadastro de novo | Não perguntar de novo, e esperar o toque no mapa |
| Enviar `academia[territorio_id]=1` pelo DevTools | Ignorar: o campo não está mais entre os permitidos |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Rollback** | Como a anotação do mestre de obras antes de derrubar a parede: desfazer uma migration, voltando o banco à estrutura anterior. |
| **Migration reversível** | Uma migration que o Rails sabe desfazer, porque tem toda a informação para o caminho de volta. |
| **`git rm`** | Apaga um arquivo e já registra a remoção para o próximo commit. |
| **Limite de palavra** (`\b`) | Numa busca, o ponto onde uma palavra começa ou termina. |
| **Estado de permissão** | Como a chave do vizinho: o que o navegador sabe sobre a decisão da pessoa, sem precisar perguntar de novo. |
| **`async` / `await`** | Um jeito de esperar uma resposta que demora, sem travar a página. |

---

## O que aprendemos

- Testar com usuários de verdade revela campos que não servem.
- Dado que pode ser calculado não deve ser digitado.
- Remover código é tão importante quanto escrever.
- Uma migration que apaga também pode ser desfeita, se descrever o que apagou.
- Antes de apagar uma tabela, apague o que aponta para ela.
- Mostrar um ponto no mapa não é o mesmo que escolher um ponto.
- Pedir permissão só depois de um gesto da pessoa.

**Próximo capítulo:** [0260 — Observações das academias](0260-observacoes-das-academias.md)

---

## Fontes

- [Rails Guides — Active Record Migrations: reversible migrations](https://guides.rubyonrails.org/active_record_migrations.html#using-the-change-method)
- [Rails API — `drop_table`](https://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-drop_table)
- [MDN — Permissions API](https://developer.mozilla.org/en-US/docs/Web/API/Permissions_API)
- [MDN — `async function`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Statements/async_function)
- [MDN — `isolation`](https://developer.mozilla.org/en-US/docs/Web/CSS/isolation)
