# 0200 — Erros nos formulários

> **Neste capítulo:** todos os formulários do projeto passam a mostrar os erros do mesmo jeito: a mensagem **colada no campo** que precisa ser corrigido, com borda destacada e marcações para o leitor de tela. Em vez de mexer em cada formulário, vamos ensinar a regra uma vez só, criando o nosso próprio **FormBuilder**, e ela passa a valer até nos formulários do Devise.

**Tag deste capítulo:** `cap-0200`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails test
```

Este capítulo não tem migration nem gem nova. Se o servidor estiver rodando, **reinicie**: houve mudança em `config/application.rb`.

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
> git switch -c estudo-0200 cap-0200
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
> git branch -D estudo-0200
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo e os equipamentos.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — O problema

Um aluno da turma, testando o site, encontrou um problema: ao digitar um e-mail inválido, **nenhum erro aparecia na tela**. Investigando, achamos três causas diferentes:

1. **O navegador barra o envio**, e cada navegador avisa de um jeito. Num, aparece um balão pequeno que some sozinho. Noutro, o formulário simplesmente não é enviado. Fácil de não perceber, principalmente no celular.
2. **Os erros do servidor ficam longe do campo.** Os formulários do Devise mostram uma **lista no topo**. Num formulário longo, ou numa tela pequena, a pessoa precisa ler a lista, guardar na cabeça e procurar cada campo.
3. **O erro não é anunciado.** Quem usa leitor de tela não fica sabendo que algo deu errado.

Este capítulo resolve as causas 2 e 3, com os erros que vêm do **servidor**. A causa 1 é assunto do próximo capítulo, com o Stimulus.

### O que queremos

No capítulo 0190, o formulário dos equipamentos já mostrava o erro **embaixo do campo**. Agora isso vira regra do projeto inteiro:

| Onde | O quê |
| --- | --- |
| No **topo** do formulário | Um aviso curto: *"Não foi possível salvar. Confira os campos destacados abaixo."* |
| Em **cada campo** com erro | Borda vermelha e mais grossa, e a mensagem logo abaixo |
| Para o **leitor de tela** | O campo marcado como inválido e ligado à sua mensagem |
| Antes do **botão** | Os erros que não pertencem a nenhum campo visível, para que **nenhum** fique escondido |

---

## Parte 2 — O FormBuilder

### 2.1 O que é um FormBuilder?

Pense no carimbo da secretaria de uma escola. Em vez de cada professor escrever "aprovado" à mão, cada um de um jeito, todos usam o mesmo carimbo. Se a escola mudar o carimbo, todos os documentos novos saem com o modelo novo.

Em termos técnicos, o **FormBuilder** é a classe por trás do `f` em `form_with ... do |f|`. Cada `f.text_field`, `f.email_field` ou `f.select` é um método dessa classe, e é ela que desenha o HTML do campo. O Rails deixa criar uma **subclasse** do FormBuilder, com métodos mudados, e usá-la como padrão. É herança, a mesma do capítulo 0150, agora aplicada a formulários.

### 2.2 O nosso builder

`app/form_builders/formulario_builder.rb`:

```ruby
# O "f" de todos os formulários do projeto.
# Campo com erro ganha: borda vermelha, mensagem logo abaixo e as marcações
# para o leitor de tela (aria-invalid e aria-describedby).
class FormularioBuilder < ActionView::Helpers::FormBuilder
  CAMPOS = %i[
    text_field email_field password_field search_field
    number_field telephone_field url_field date_field textarea
  ]

  CAMPOS.each do |tipo|
    define_method(tipo) do |atributo, opcoes = {}|
      mensagens = mensagens_de_erro(atributo)
      return super(atributo, opcoes) if mensagens.empty?

      super(atributo, opcoes_com_erro(atributo, opcoes)) + mensagem_de_erro(atributo, mensagens)
    end
  end

  def select(atributo, escolhas = nil, opcoes = {}, html = {}, &bloco)
    mensagens = mensagens_de_erro(atributo)
    return super if mensagens.empty?

    super(atributo, escolhas, opcoes, opcoes_com_erro(atributo, html), &bloco) + mensagem_de_erro(atributo, mensagens)
  end

  # No topo do formulário: avisa que algo deu errado
  def aviso_erros
    return if sem_erros?

    @template.tag.p(I18n.t("formularios.aviso_erros"), class: "aviso-erros", role: "alert")
  end

  # Antes do botão: erros que não pertencem a nenhum campo deste formulário.
  # Assim, nenhum erro fica escondido.
  def erros_restantes
    return if sem_erros?

    restantes = object.errors.reject { |erro| mostrados.include?(erro.attribute) }
    return if restantes.empty?

    @template.tag.ul(class: "erros-restantes") do
      @template.safe_join(restantes.map { |erro| @template.tag.li(erro.full_message) })
    end
  end

  private

  def sem_erros?
    !object.respond_to?(:errors) || object.errors.empty?
  end

  def mostrados
    @mostrados ||= Set.new
  end

  def mensagens_de_erro(atributo)
    return [] unless object.respond_to?(:errors)

    object.errors.full_messages_for(atributo)
  end

  def opcoes_com_erro(atributo, opcoes)
    mostrados << atributo
    aria = (opcoes[:aria] || {}).merge(invalid: true, describedby: "#{field_id(atributo)}_erro")

    opcoes.merge(class: [ opcoes[:class], "com-erro" ].compact.join(" "), aria: aria)
  end

  def mensagem_de_erro(atributo, mensagens)
    @template.tag.p(@template.safe_join(mensagens, @template.tag.br),
                    id: "#{field_id(atributo)}_erro", class: "erro-campo")
  end
end
```

A pasta `app/form_builders/` não existia. Não precisa configurar nada: o Rails carrega sozinho **qualquer** pasta dentro de `app/`.

### 2.3 Linha a linha: os campos

```ruby
CAMPOS.each do |tipo|
  define_method(tipo) do |atributo, opcoes = {}|
```

Os nove tipos de campo têm o mesmo comportamento. Em vez de escrever nove métodos quase iguais, o `define_method` **cria um método a partir de um nome**. Na primeira volta do `each`, ele cria o `text_field`; na segunda, o `email_field`; e assim por diante. Escrever código que escreve código tem nome: **metaprogramação**. O Rails usa isso o tempo todo: é assim que o `has_many :posts` cria o método `posts`.

```ruby
return super(atributo, opcoes) if mensagens.empty?
```

O **`super`** chama o método **original**, o da classe mãe, que desenha o campo. Campo sem erro sai exatamente como sempre saiu: o builder só age quando há erro.

```ruby
super(atributo, opcoes_com_erro(atributo, opcoes)) + mensagem_de_erro(atributo, mensagens)
```

Campo com erro: chama o original com opções a mais (a classe e as marcações) e **cola** a mensagem logo depois. O resultado, para o campo de e-mail:

```html
<input type="email" name="user[email]" id="user_email"
       class="com-erro" aria-invalid="true" aria-describedby="user_email_erro">
<p id="user_email_erro" class="erro-campo">E-mail já está em uso</p>
```

### 2.4 As marcações para o leitor de tela

| Atributo | O que faz |
| --- | --- |
| `aria-invalid="true"` | O leitor de tela anuncia o campo como **inválido** |
| `aria-describedby="user_email_erro"` | Liga o campo ao parágrafo com esse `id`. Ao chegar no campo, o leitor lê o rótulo **e** a mensagem de erro |

O `field_id(atributo)` é um método do próprio FormBuilder que devolve o `id` que o Rails dá ao campo, como `user_email`. Usando ele, o `id` da mensagem sempre combina com o do campo, em qualquer formulário.

### 2.5 O `select` é diferente

O `select` recebe quatro argumentos (o atributo, as escolhas, as opções do Rails e as opções do HTML), e não dois. Por isso tem um método próprio, que coloca a classe e as marcações no quarto argumento, o do HTML.

Repare no `return super if mensagens.empty?` sem parênteses: um `super` **sem argumentos** repassa exatamente os mesmos que o método recebeu.

### 2.6 Nenhum erro fica escondido

Um formulário não mostra todos os campos do model. No cadastro, por exemplo, não existe o campo `login`, porque o identificador é gerado sozinho (capítulo 0120). Se um dia aparecer um erro no `login`, não haveria campo para mostrá-lo, e ele **sumiria**: o formulário voltaria com o aviso no topo e nenhum campo destacado.

Por isso, o builder **anota** cada campo que mostrou o próprio erro (`mostrados`), e o `erros_restantes`, chamado antes do botão, lista o que sobrou. Na maioria das vezes, não sobra nada, e ele não desenha nada.

### 2.7 Por que `safe_join`, e não `html_safe`?

A mensagem de erro pode conter texto que veio do usuário. O `safe_join` junta os pedaços **escapando** cada um, e só o separador (`<br>`) passa como HTML. Já o `html_safe` confiaria no texto inteiro. Para texto que pode vir de fora, a regra é: `safe_join` e `tag`, nunca `html_safe`.

---

## Parte 3 — Ligando o builder ao projeto

### 3.1 O padrão de todos os formulários

No `app/controllers/application_controller.rb`, dentro da classe:

```ruby
default_form_builder FormularioBuilder
```

Com uma linha, **todo** `form_with` do projeto passa a usar o nosso builder. Os controllers do Devise herdam do `ApplicationController`, e por isso os formulários de login, cadastro e senha também ganham a regra nova, sem reescrever nenhum deles.

### 3.2 Adeus, `field_with_errors`

Por padrão, o Rails embrulha todo campo com erro, e o label dele, numa `<div class="field_with_errors">`. Essa div quebra o layout: o que estava numa linha passa a ocupar duas. Agora que o builder cuida dos erros, ela só atrapalha.

No `config/application.rb`, dentro da classe:

```ruby
# O FormularioBuilder cuida dos campos com erro; sem a div que o Rails põe em volta
config.action_view.field_error_proc = proc { |html_tag, _instance| html_tag }
```

O `field_error_proc` é o pedaço de código que o Rails chama para "embrulhar" um campo com erro. O nosso devolve o campo **como veio**, sem embrulho.

> ⚠️ Mudanças em `config/` só valem depois de **reiniciar** o servidor.

### 3.3 O texto do aviso

No `config/locales/pt-BR.yml`:

```yaml
pt-BR:
  formularios:
    aviso_erros: "Não foi possível salvar. Confira os campos destacados abaixo."
```

---

## Parte 4 — Os formulários

### 4.1 O Devise

Os formulários do Devise vinham com uma lista de erros no topo:

```erb
<%= render "devise/shared/error_messages", resource: resource %>
```

Em cada um deles (`registrations/new`, `registrations/edit`, `passwords/new`, `passwords/edit` e `confirmations/new`), essa linha virou:

```erb
<%= f.aviso_erros %>
```

E, logo antes do botão de enviar:

```erb
<%= f.erros_restantes %>
```

O partial `devise/shared/_error_messages.html.erb` foi apagado, porque nenhuma view o usa mais.

O formulário de **login** é diferente: o Devise não valida os campos ali. Quando o e-mail ou a senha estão errados, ele avisa pelo **flash**, com *"E-mail ou senha inválidos"*. É de propósito: dizer *"este e-mail não tem conta"* ajudaria alguém a descobrir quem está cadastrado no site.

### 4.2 Os nossos formulários

O `_form` dos equipamentos perdeu os blocos `full_messages_for`, que o builder faz agora, e ganhou as duas linhas:

```erb
<%= form_with model: [ :admin, equipamento ] do |f| %>
  <%= f.aviso_erros %>

  <div class="campo">
    <%= f.label :nome %>
    <%= f.text_field :nome %>
  </div>

  <%# ... os outros campos ... %>

  <%= f.erros_restantes %>
  <%= f.submit "Salvar" %>
<% end %>
```

Compare com o capítulo 0190: o formulário ficou **mais curto** e faz **mais** coisas.

O `perfis/edit` e o `admin/users/edit` ganharam as mesmas duas linhas. O formulário de busca da lista de usuários não precisa: ele não tem objeto, nem erros.

### 4.3 O flash anunciado

No layout:

```erb
<p class="notice" role="status"><%= notice %></p>
<p class="alert" role="alert"><%= alert %></p>
```

| Papel | O que o leitor de tela faz |
| --- | --- |
| `role="alert"` | **Interrompe** o que estiver lendo e anuncia. Para erros, como o "E-mail ou senha inválidos" |
| `role="status"` | Anuncia **sem interromper**. Para confirmações, como o "Perfil atualizado" |

O aviso no topo dos formulários também tem `role="alert"`, posto pelo próprio builder.

---

## Parte 5 — O CSS

### 5.1 Um arquivo para os formulários

Os estilos de formulário começaram no `30-admin.css`, no capítulo 0190, mas não são coisa só do admin. Foram para um arquivo próprio, `app/assets/stylesheets/15-formularios.css`, que carrega antes da navegação (20) e da administração (30):

```css
/* 15-formularios.css — Campos, dicas e erros de todos os formulários */

:is(input, textarea, select).com-erro {
  border-color: var(--cor-erro);
  border-width: 3px;
}

.campo:has(.com-erro) label {
  color: var(--cor-erro);
  font-weight: 700;
}

.erro-campo {
  margin-top: 4px;
  color: var(--cor-erro);
  font-weight: 700;
  font-size: 0.875rem;
}

.aviso-erros,
.erros-restantes {
  padding: var(--espaco-1) var(--espaco-2);
  border-left: 4px solid var(--cor-erro);
  border-radius: var(--raio);
  background: var(--cor-branco);
  color: var(--cor-erro);
  font-weight: 700;
}
```

| Regra | O que faz |
| --- | --- |
| `:is(input, textarea, select).com-erro` | "Um input, textarea ou select com a classe `com-erro`". O `:is()` evita repetir a regra três vezes |
| `border-width: 3px` | A borda fica **mais grossa**, e não só vermelha |
| `.campo:has(.com-erro) label` | "O label do bloco `.campo` que **contém** um campo com erro". O `:has()` olha para dentro do elemento |

### 5.2 Não depender só da cor

Cerca de 1 em cada 12 homens tem algum tipo de daltonismo, e muitos deles não distinguem bem o vermelho do roxo da nossa borda normal. Por isso, o erro aparece de **três** jeitos ao mesmo tempo: a cor, a borda mais grossa e a mensagem em texto. Quem não enxerga um deles percebe pelos outros. É uma regra de acessibilidade que vale para qualquer interface: **cor nunca é a única pista**.

### 5.3 Botão que não cabe na tela

Testando em 320 px, a tela de "Esqueceu sua senha?" **estourou para o lado**: dava para arrastar a página inteira, e o cabeçalho e o texto ficavam cortados.

O motivo era o botão. O `f.submit` gera um `<input type="submit">`, e o texto de um `input` **não quebra linha**. "Enviar instruções para redefinição da senha" é mais largo que a tela, e o botão empurra a página.

Foram duas correções. Uma **regra geral**, para nenhum botão estourar, mesmo com um texto escrito no futuro:

```css
input[type="submit"],
button {
  max-width: 100%;
  white-space: normal;
  height: auto;
}
```

E **textos mais curtos**: botão bom tem duas ou três palavras, porque o título da página já explica o resto.

| Tela | Antes | Depois |
| --- | --- | --- |
| Esqueceu sua senha? | Enviar instruções para redefinição da senha | Enviar instruções |
| Reenviar confirmação | Reenviar instruções de confirmação | Reenviar confirmação |

Esses textos vêm da gem `devise-i18n`. Há dois jeitos de trocar:

1. **Direto na view**, com o texto no lugar do `t(...)`: `f.submit "Enviar instruções"`.
2. **Sobrescrevendo a chave** no nosso `config/locales/pt-BR.yml`. Os arquivos do projeto são carregados **depois** dos da gem, então ganham dela:

   ```yaml
   pt-BR:
     devise:
       passwords:
         new:
           send_me_reset_password_instructions: "Enviar instruções"
   ```

O segundo jeito mantém todos os textos num lugar só; o primeiro é mais direto. Os dois funcionam.

> 💡 **Como saber se uma tela estoura?** No modo celular do DevTools, em 320 px, tente **arrastar a página para o lado**. Se ela se mexer, alguma coisa está mais larga que a tela.

---

## Parte 6 — Os testes

### 6.1 O formulário dos equipamentos

No teste `"cadastro sem nome mostra o erro embaixo do campo"`, do capítulo 0190, entraram quatro conferências:

```ruby
assert_select "input#equipamento_nome.com-erro[aria-invalid=true][aria-describedby=equipamento_nome_erro]"
assert_select "p#equipamento_nome_erro.erro-campo"
assert_select ".aviso-erros[role=alert]"
assert_select ".field_with_errors", count: 0
```

A primeira linha é comprida, mas se lê da esquerda para a direita: *"um input, com o id `equipamento_nome`, a classe `com-erro`, o `aria-invalid` verdadeiro e ligado à mensagem `equipamento_nome_erro`"*. A última confere que a div antiga do Rails sumiu de verdade.

### 6.2 O cadastro do Devise

`test/controllers/cadastro_test.rb`:

```ruby
require "test_helper"

class CadastroTest < ActionDispatch::IntegrationTest
  test "senhas diferentes mostram o erro embaixo da confirmação" do
    post user_registration_url, params: { user: {
      nome: "Teste", email: "novo@exemplo.com",
      password: "senha-segura-123", password_confirmation: "outra-senha"
    } }

    assert_response :unprocessable_content
    assert_select "input#user_password_confirmation[aria-invalid=true]"
    assert_select "#user_password_confirmation_erro"
  end

  test "e-mail repetido mostra o erro embaixo do e-mail" do
    post user_registration_url, params: { user: {
      nome: "Teste", email: users(:ana).email,
      password: "senha-segura-123", password_confirmation: "senha-segura-123"
    } }

    assert_select "#user_email_erro", text: /já está em uso/
  end
end
```

Estes testes provam que o builder chegou **até o Devise**, que é a parte que não escrevemos.

### 6.3 O login

```ruby
test "login errado mostra o alerta" do
  post user_session_url, params: { user: { email: "ninguem@exemplo.com", password: "errada" } }
  assert_select ".alert[role=alert]", text: /inválid/
end
```

O `/inválid/` é uma expressão regular que aceita "inválido" e "inválidos". Assim, o teste não quebra se a gem mudar o plural da mensagem.

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 7 — Testando no navegador

No modo celular do DevTools, em 320 px, provoque os erros:

1. **Cadastro** com senhas diferentes: o erro aparece embaixo da confirmação.
2. **Cadastro** com um e-mail que já existe: o erro aparece embaixo do e-mail.
3. **Login** com a senha errada: o alerta vermelho aparece no topo.
4. **Esqueceu sua senha?** com um e-mail que não existe: o erro aparece embaixo do e-mail.
5. **Trocar e-mail ou senha** sem a senha atual: o erro aparece embaixo da senha atual.
6. **Cadastrar equipamento** sem nome: o label também fica vermelho.

Em cada caso, confira: o aviso no topo, a borda e a mensagem **no campo certo**, nenhuma lista repetindo os erros e nenhuma tela estourando para o lado.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Errar **dois** campos de uma vez | Mostrar cada erro embaixo do seu campo, e um único aviso no topo |
| Um campo com **duas** regras quebradas, como uma senha curta e diferente da confirmação | Mostrar as duas mensagens, uma por linha, embaixo dos campos certos |
| No DevTools, apagar o atributo `type="email"` do campo e enviar um e-mail sem `@` | O servidor recebe o pedido e responde com o erro dele. A validação do navegador é cortesia; a do servidor é a regra |
| Navegar com o **Tab** até um campo com erro, com o leitor de tela ligado | Ouvir o nome do campo, "inválido" e a mensagem de erro |
| Ver o **código-fonte** de um formulário com erro (Ctrl+U) | Nenhuma `field_with_errors` |

A terceira linha merece atenção. Tudo o que roda no navegador pode ser desligado ou mudado por quem está usando o computador. Por isso, a validação no navegador serve para **ajudar** quem preenche, e a do servidor, para **proteger** o sistema. As duas são necessárias, e a do servidor nunca pode faltar.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **FormBuilder** | Como o carimbo da secretaria: a classe por trás do `f`, que desenha cada campo do formulário do mesmo jeito. |
| **`default_form_builder`** | Escolhe o FormBuilder de todos os formulários de um controller e dos que herdam dele. |
| **`define_method`** | Cria um método a partir de um nome, durante a execução do programa. |
| **Metaprogramação** | Código que escreve código, como o `define_method` criando nove métodos num laço. |
| **`super`** | Chama o método de mesmo nome da classe mãe. |
| **`field_error_proc`** | O código que o Rails usa para embrulhar campos com erro. |
| **`aria-invalid`** | Marca um campo como inválido para o leitor de tela. |
| **`aria-describedby`** | Liga um campo a um texto que o descreve, como a mensagem de erro. |
| **`role="alert"` e `role="status"`** | Avisos que o leitor de tela anuncia: o primeiro interrompendo, o segundo esperando a vez. |
| **`:has()`** | No CSS, seleciona um elemento pelo que ele **contém**. |

---

## O que aprendemos

- Um problema relatado ("o erro não aparece") pode ter várias causas. Investigue antes de corrigir.
- Uma regra que vale para todos os formulários fica **num lugar só**: o FormBuilder.
- Com herança e `super`, dá para mudar um comportamento do Rails sem reescrever o original.
- Erro bom aparece colado no campo, é anunciado ao leitor de tela e não depende só da cor.
- Nenhum erro pode ficar escondido: o que não tem campo aparece antes do botão.
- Botão tem texto curto, e nenhum elemento pode ser mais largo que a tela.
- A validação do navegador ajuda; a do servidor protege.

**Próximo capítulo:** [0210 — Validação no navegador com Stimulus](0210-validacao-no-navegador.md)

---

## Fontes

- [Rails API — `ActionView::Helpers::FormBuilder`](https://api.rubyonrails.org/classes/ActionView/Helpers/FormBuilder.html)
- [Rails API — `ActionController::FormBuilder#default_form_builder`](https://api.rubyonrails.org/classes/ActionController/FormBuilder/ClassMethods.html)
- [Rails Guides — Configuring Rails: `field_error_proc`](https://guides.rubyonrails.org/configuring.html#config-action-view-field-error-proc)
- [MDN — `aria-invalid`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-invalid)
- [MDN — `aria-describedby`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-describedby)
- [MDN — ARIA `alert` role](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Roles/alert_role)
