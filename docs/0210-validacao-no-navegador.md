# 0210 — Validação no navegador com Stimulus

> **Neste capítulo:** os formulários passam a avisar o erro **antes** de enviar, assim que a pessoa sai de um campo preenchido errado, no mesmo formato dos erros do servidor. É o nosso primeiro **controller Stimulus**, a parte do Hotwire que cuida do comportamento no navegador. E é também o primeiro **teste de sistema** do projeto, que abre um navegador de verdade e clica como uma pessoa.

**Tag deste capítulo:** `cap-0210`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bundle install
bin/rails test
bin/rails test:system
```

O `bin/rails test:system` roda os testes de sistema, que precisam do **Chrome ou Chromium** instalado. Na primeira vez, ele pode demorar um pouco, enquanto baixa o programa que controla o navegador.

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
> git switch -c estudo-0210 cap-0210
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
> git branch -D estudo-0210
> ```
>
> - `db:drop db:create` apaga o banco do capítulo antigo e cria um vazio.
> - `pg_restore` devolve para ele a cópia do passo 1, com os seus cadastros. O `--no-owner` evita erro de permissão.
> - `db:migrate` aplica as migrations que tenham chegado depois da cópia. Se não houver nenhuma, ele não faz nada.
>
> Sem a cópia do passo 1, troque as linhas do `db:drop` e do `pg_restore` por `bin/rails db:migrate` e `bin/rails db:seed`: o banco volta ao presente, mas só com o admin, os usuários de exemplo e os equipamentos.
>
> Lembre: **a `main` é para trabalhar, as tags são para consultar.**

> 📖 **Como ler este capítulo.** Os comandos de construção mostrados nas partes seguintes (`bin/rails generate`, `bundle add`, a criação e a edição de arquivos) **já estão no código** que você baixou com o `git pull`. Os blocos com esses comandos começam com a linha `# 📖 JÁ ESTÁ NO PROJETO`. **Não execute esses comandos de novo**: eles estão aqui para você entender como cada parte foi feita e saber repetir num projeto seu. Rodar um `generate` de novo, por exemplo, sobrescreveria o controller.
>
> Execute só os comandos desta seção ("Para ter o código deste capítulo") e os das partes de **testes**, de **exercícios** e de **teste no navegador**.

---

## Parte 1 — O problema que sobrou

No capítulo 0200, descobrimos três causas para "o erro não aparece". Resolvemos duas, com os erros do servidor. Sobrou a primeira: **o balão do navegador**.

Quando um campo tem uma regra no HTML, como `type="email"` ou `required`, o próprio navegador confere antes de enviar. Só que cada navegador avisa de um jeito: um balão pequeno, que some sozinho, num lugar que muda de um navegador para outro. Com a mensagem no idioma do sistema, e não do site. Fácil de não ver, principalmente no celular.

### O que queremos

- O erro aparece **no mesmo lugar e no mesmo formato** do erro do servidor: borda, mensagem embaixo do campo, marcações para o leitor de tela. Quem preenche não vê diferença entre os dois.
- O erro aparece quando a pessoa **sai** de um campo que preencheu, e não a cada tecla. Ninguém quer ver "e-mail inválido" enquanto ainda está digitando.
- O erro **some** assim que a pessoa corrige.
- **Sem JavaScript, tudo continua funcionando**, com o balão do navegador e a validação do servidor.

### A validação do navegador não substitui a do servidor

Tudo o que roda no navegador pode ser desligado ou alterado por quem está usando o computador. O capítulo 0200 mostrou isso no "Tente quebrar": apagando o `type="email"` pelo DevTools, o servidor recebe o pedido e responde com o erro dele.

| Validação | Para quê |
| --- | --- |
| **No navegador** | **Ajudar** quem preenche: avisa na hora, sem esperar a resposta do servidor |
| **No servidor** | **Proteger** o sistema: é a regra de verdade, e nunca pode faltar |

---

## Parte 2 — Stimulus

### 2.1 O que é o Stimulus?

Pense nos interruptores de uma casa. A fiação já está na parede (o HTML que o servidor mandou). O interruptor não constrói a casa, só **liga um comportamento** a um ponto dela: acender a luz da sala.

Em termos técnicos, o **Stimulus** é a parte do Hotwire que liga **comportamentos em JavaScript** a elementos do HTML, por meio de atributos `data-`. Ele não desenha a página, que continua vindo do servidor. Ele só acrescenta o que precisa acontecer no navegador, como mostrar um erro antes de enviar.

| Atributo | O que faz |
| --- | --- |
| `data-controller="validacao"` | "Este elemento é controlado pelo `validacao_controller.js`" |
| `data-action="focusout->validacao#sair"` | "Quando acontecer um `focusout`, chame o método `sair` do controller" |

Repare na semelhança com o Rails. No Rails, a **rota** liga um endereço a um método de controller: `get "/perfil" => "perfis#edit"`. No Stimulus, o `data-action` liga um **evento** a um método de controller: `focusout->validacao#sair`.

### 2.2 Criando o controller

```bash
# 📖 JÁ ESTÁ NO PROJETO: não execute. Use estes comandos num projeto novo.
bin/rails generate stimulus validacao
```

O gerador cria `app/javascript/controllers/validacao_controller.js`. O nome do arquivo define o nome do controller: `validacao_controller.js` vira `validacao`. O Rails registra sozinho todo controller dessa pasta, como faz com os controllers Ruby.

---

## Parte 3 — Um controller para todos os formulários

### 3.1 No `<main>`, e não em cada formulário

O controller foi ligado **uma vez**, no layout:

```erb
<main data-controller="validacao"
      data-action="focusout->validacao#sair input->validacao#digitar submit->validacao#enviar">
```

Como ele está no `<main>`, e não num formulário, vale para **todos** os formulários de todas as páginas, inclusive os do Devise. É o mesmo raciocínio do `default_form_builder` do capítulo 0200: uma regra, num lugar só.

Funciona por causa da **propagação de eventos**. Pense numa pedra jogada num lago: as ondas saem de onde ela caiu e se espalham para longe. Em termos técnicos, quando algo acontece num campo (um clique, uma tecla, a saída do campo), o evento acontece **no campo** e depois **sobe** pelos elementos que o contêm: a `div`, o `form`, o `main`, até o documento. Isso se chama *event bubbling*. O controller no `<main>` escuta os eventos de todos os campos que estão dentro dele.

### 3.2 Os três eventos

| Evento | Quando acontece | Método |
| --- | --- | --- |
| `focusout` | A pessoa **sai** de um campo | `sair` |
| `input` | A pessoa **digita** num campo | `digitar` |
| `submit` | A pessoa **envia** o formulário | `enviar` |

> 💡 **Por que `focusout`, e não `blur`?** Os dois acontecem quando a pessoa sai do campo, mas o `blur` **não sobe** pela página. Um controller no `<main>` nunca ficaria sabendo dele. O `focusout` sobe.

### 3.3 O Turbo e o Stimulus trabalhando juntos

O Turbo troca o conteúdo da página a cada navegação, sem recarregar tudo. Quando o `<main>` novo chega, o Stimulus percebe e **conecta** o controller de novo, sozinho. Por isso o `connect` roda em cada página, e os formulários novos também ficam sem o balão do navegador.

---

## Parte 4 — O controller, por partes

O arquivo completo está em `app/javascript/controllers/validacao_controller.js`. Vamos por partes.

### 4.1 Desligando o balão

```js
connect() {
  this.element.querySelectorAll("form").forEach((form) => (form.noValidate = true))
}
```

O `connect` é chamado quando o controller se liga ao elemento. O `this.element` é o próprio `<main>`. Para cada formulário dentro dele, o `noValidate = true` diz ao navegador: *"não mostre o seu balão; a gente cuida disso"*.

É aqui que mora o *progressive enhancement*, a **melhoria progressiva**. Pense numa rampa ao lado de uma escada: quem pode subir a escada sobe, e quem não pode ainda tem um caminho. A página funciona sem JavaScript, com o balão do navegador e o erro do servidor. **Se** o JavaScript estiver ligado, ele desliga o balão e assume com uma experiência melhor. Ninguém fica sem validação.

### 4.2 Saindo de um campo

```js
sair(event) {
  const campo = event.target
  if (this.validavel(campo) && campo.dataset.alterado) this.conferir(campo)
}

digitar(event) {
  const campo = event.target
  if (!this.validavel(campo)) return

  campo.dataset.alterado = "sim"
  if (campo.classList.contains("com-erro")) this.conferir(campo)
}
```

O `event.target` é o campo onde o evento **começou**, mesmo que quem o recebeu tenha sido o `<main>`.

O `campo.dataset.alterado` é uma anotação no próprio campo: o `digitar` marca, e o `sair` só confere os campos marcados. Isso evita duas coisas chatas:

- **Quem só atravessa os campos com o Tab** não leva bronca por um campo que ainda nem começou a preencher.
- **O erro do servidor fica até a pessoa corrigir.** Se o servidor disse *"E-mail já está em uso"* e a pessoa só passa pelo campo, a mensagem continua. Ela some quando a pessoa começa a digitar outro e-mail.

E o `if (campo.classList.contains("com-erro"))` no `digitar` faz o erro sumir **enquanto** a pessoa corrige: a cada tecla, o campo que já está com erro é conferido de novo.

### 4.3 Enviando

```js
enviar(event) {
  const campos = [ ...event.target.elements ].filter((campo) => this.validavel(campo))
  const invalidos = campos.filter((campo) => !this.conferir(campo))

  if (invalidos.length > 0) {
    event.preventDefault()
    invalidos[0].focus()
  }
}
```

| Trecho | O que faz |
| --- | --- |
| `event.target.elements` | Todos os campos do formulário que foi enviado |
| `[ ...lista ]` | Transforma a lista do navegador num array de verdade, que tem `filter` |
| `event.preventDefault()` | **Cancela** o envio |
| `invalidos[0].focus()` | Leva o cursor ao primeiro campo com erro. No celular, a tela rola até ele |

O Turbo também escuta o envio dos formulários, mas só depois do nosso controller, porque o evento sobe do `<main>` para o documento. E o Turbo respeita o `preventDefault`: se alguém cancelou o envio, ele não envia.

### 4.4 Conferindo um campo

```js
validavel(campo) {
  return campo.willValidate && campo.id
}

conferir(campo) {
  const valido = campo.checkValidity()
  this.limpar(campo)
  if (!valido) this.mostrar(campo, this.mensagem(campo))
  return valido
}
```

O navegador já sabe conferir as regras do HTML: um campo `required` vazio, um `type="email"` sem `@`, um `minlength` não atingido. Essa capacidade se chama **Constraint Validation API**, e nós só pedimos o resultado:

| Método ou propriedade | O que devolve |
| --- | --- |
| `campo.willValidate` | Se o campo participa da validação. Botões, campos escondidos e desabilitados não participam |
| `campo.checkValidity()` | `true` se o campo respeita todas as suas regras |
| `campo.validity` | **Qual** regra foi quebrada (Parte 4.5) |

Não escrevemos nenhuma regra de e-mail. **As regras ficam no HTML**, e o controller só lê. É o mesmo princípio do Rails, em que a regra fica no model, e o formulário só mostra.

### 4.5 As nossas mensagens

```js
mensagem(campo) {
  const regra = campo.validity

  if (regra.valueMissing) return "Preencha este campo."
  if (regra.typeMismatch && campo.type === "email") return "Digite um e-mail válido, como nome@exemplo.com."
  if (regra.tooShort) return `Use pelo menos ${campo.minLength} caracteres.`
  return campo.validationMessage
}
```

| Regra quebrada | Atributo no HTML | Mensagem |
| --- | --- | --- |
| `valueMissing` | `required` | Preencha este campo. |
| `typeMismatch` | `type="email"` | Digite um e-mail válido, como nome@exemplo.com. |
| `tooShort` | `minlength` | Use pelo menos 6 caracteres. |

O navegador tem a própria mensagem, o `validationMessage`, mas ela muda com o navegador e com o idioma do sistema. As nossas são iguais em qualquer lugar e mostram um **exemplo**, o que ajuda mais do que dizer só "inválido". A mensagem do navegador fica como último recurso, para alguma regra que não previmos.

### 4.6 Mostrando e limpando o erro

```js
mostrar(campo, texto) {
  const id = `${campo.id}_erro`
  const paragrafo = document.createElement("p")
  paragrafo.id = id
  paragrafo.className = "erro-campo"
  paragrafo.textContent = texto

  campo.classList.add("com-erro")
  campo.setAttribute("aria-invalid", "true")
  campo.setAttribute("aria-describedby", id)
  campo.insertAdjacentElement("afterend", paragrafo)
}

limpar(campo) {
  document.getElementById(`${campo.id}_erro`)?.remove()
  campo.classList.remove("com-erro")
  campo.removeAttribute("aria-invalid")
  campo.removeAttribute("aria-describedby")
}
```

Compare com o FormularioBuilder do capítulo 0200: é **o mesmo HTML**, agora montado em JavaScript. A mesma classe, as mesmas marcações e até o mesmo `id` da mensagem (`user_email_erro`). Por isso, quando o servidor já mostrou um erro num campo, o `limpar` encontra a mensagem dele e a remove antes de pôr a nova. Nunca aparecem duas.

> ⚠️ **`textContent`, nunca `innerHTML`.** O `textContent` coloca o texto **como texto**: se houver um `<script>` nele, aparece na tela como letras, e não roda. O `innerHTML` interpretaria o texto como HTML. É o equivalente, no JavaScript, ao escape automático do ERB.

O `?.` em `getElementById(...)?.remove()` é o mesmo operador de navegação segura do Ruby (`&.`, capítulo 0190): se não existe mensagem, não faz nada.

---

## Parte 5 — Regras nos campos

O controller usa as regras que estão **no HTML**. Os formulários do Devise quase não tinham regras, então elas foram acrescentadas:

| View | Campo | Regra |
| --- | --- | --- |
| `sessions/new` | e-mail e senha | `required: true` |
| `registrations/new` | nome, e-mail, senha e confirmação | `required: true` |
| `registrations/new` | senha | `minlength: @minimum_password_length` |
| `passwords/new` | e-mail | `required: true` |
| `passwords/edit` | senha nova e confirmação | `required: true`, e `minlength` na senha |
| `confirmations/new` | e-mail | `required: true` |
| `admin/equipamentos/_form` | nome | `required: true` |

Por exemplo:

```erb
<%= f.password_field :password, autocomplete: "new-password", required: true, minlength: @minimum_password_length %>
```

O `@minimum_password_length` vem do Devise: é o número configurado no `config/initializers/devise.rb`, o mesmo da dica "mínimo de 6 caracteres". Se a regra mudar lá, muda no formulário também.

A senha do **`registrations/edit`** ficou **sem** `required`. Ali, ela só é preenchida por quem quer trocá-la.

### 5.1 `<div class="campo">` em vez de `<p>`

As views do Devise embrulhavam cada campo num `<p>`. Só que a mensagem de erro também é um `<p>`, logo depois do campo, e em HTML um parágrafo **não pode** ficar dentro de outro. O navegador "conserta" o HTML do jeito dele, e o resultado fica diferente do que escrevemos.

Os `<p>` viraram `<div class="campo">`, com o label e o campo juntos, como no formulário dos equipamentos:

```erb
<div class="campo">
  <%= f.label :email %>
  <%= f.email_field :email, autofocus: true, autocomplete: "email", required: true %>
</div>
```

De quebra, o label fica vermelho quando o campo tem erro (a regra `.campo:has(.com-erro) label` do capítulo 0200), e o espaçamento fica igual em todos os formulários.

---

## Parte 6 — O primeiro teste de sistema

### 6.1 O que é um teste de sistema?

Os testes que escrevemos até aqui pedem uma página e conferem o HTML que voltou. Eles não rodam JavaScript, e por isso não veriam o nosso controller.

Pense na diferença entre conferir a receita de um bolo e **provar** o bolo. O teste de controller confere a receita. O **teste de sistema** prova o bolo: abre um navegador de verdade, sem janela, visita as páginas, digita nos campos e clica nos botões, como uma pessoa. Quem comanda o navegador é o **Capybara**, com a ajuda do **Selenium**.

### 6.2 A configuração

`test/application_system_test_case.rb`:

```ruby
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 320, 712 ]
end
```

- `headless_chrome`: o Chrome **sem janela**. Ele roda, mas não aparece na tela.
- `screen_size: [ 320, 712 ]`: os testes rodam **do tamanho de um celular**, que é como o projeto vai ser usado.

### 6.3 Os testes

`test/system/validacao_test.rb`:

```ruby
require "application_system_test_case"

class ValidacaoTest < ApplicationSystemTestCase
  test "e-mail inválido mostra o erro ao sair do campo" do
    visit new_user_registration_path

    fill_in "E-mail", with: "luiz.mail.com"
    find_field("E-mail").send_keys(:tab)

    assert_selector "#user_email.com-erro[aria-invalid=true]"
    assert_selector "#user_email_erro", text: "Digite um e-mail válido"
  end

  test "o erro some quando a pessoa corrige" do
    visit new_user_registration_path

    fill_in "E-mail", with: "luiz.mail.com"
    find_field("E-mail").send_keys(:tab)
    fill_in "E-mail", with: "luiz@mail.com"

    assert_no_selector "#user_email_erro"
  end

  test "não envia com campo obrigatório vazio e leva o cursor até ele" do
    visit new_user_session_path
    click_on "Login"

    assert_selector "#user_email_erro", text: "Preencha este campo"
    assert_current_path new_user_session_path
  end
end
```

| Comando | O que faz |
| --- | --- |
| `visit` | Abre o endereço no navegador |
| `fill_in "E-mail", with: "..."` | Acha o campo pelo **texto do label**, como uma pessoa acharia, e digita |
| `send_keys(:tab)` | Aperta o Tab: o cursor sai do campo, e acontece o `focusout` |
| `click_on "Login"` | Clica no botão ou no link com esse texto |
| `assert_selector` | Espera o elemento aparecer na página. Aceita os mesmos seletores do CSS |
| `assert_no_selector` | Espera o elemento **sumir** |

Repare que os testes procuram os campos pelo **texto do label**, e não pelo `id`. Se um label sumir ou estiver errado, o teste quebra. Ou seja, ele também confere a acessibilidade do formulário.

```bash
bin/rails test:system
```

### 6.4 Quando um teste de sistema falha

O teste de sistema guarda uma **foto da tela** no momento da falha, em `tmp/screenshots/`. O caminho aparece na mensagem de erro.

Durante a construção deste capítulo, o terceiro teste falhou: *"expected to find css `#user_email_erro` but there were no matches"*. A foto mostrava o alerta "E-mail ou senha inválidos" no topo da página de login: o formulário **tinha sido enviado** ao servidor. A causa: o formulário de login ainda não tinha o `required`. Sem a regra, o campo vazio era válido para o navegador, e o controller deixava o envio seguir.

É um bom exemplo do valor desse teste: um campo sem regra parece normal na tela, e só um teste que tenta enviar o formulário vazio percebe.

> 💡 **"css" na mensagem de erro** não fala da folha de estilos. O Capybara procura elementos com a mesma sintaxe dos seletores do CSS, e `#user_email_erro` quer dizer "o elemento com esse `id`".

---

## Parte 7 — Testando no navegador

No modo celular do DevTools, em 320 px:

1. **Cadastro:** digite `luiz.mail.com` no e-mail e saia do campo. O erro aparece embaixo, com a borda e o label vermelhos, sem balão.
2. **Corrija o e-mail:** o erro some enquanto você digita.
3. **Atravesse os campos só com o Tab**, sem digitar: nenhum erro aparece.
4. **Senha com 3 caracteres** no cadastro, e saia do campo: *"Use pelo menos 6 caracteres."*
5. **Login** com tudo vazio, clique em "Login": os erros aparecem, e o cursor vai para o e-mail.
6. **Repita no Firefox.** Os erros devem aparecer iguais.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Desligar o JavaScript (DevTools → Ctrl+Shift+P → *Disable JavaScript*) e enviar o login vazio | Voltar o balão do navegador: a validação continua, só que sem o nosso estilo |
| Com o JavaScript desligado, apagar o `required` pelo DevTools e enviar | O servidor responder com o erro dele |
| Cadastrar com um e-mail que já existe, depois só passar pelo campo com o Tab | A mensagem do servidor *"já está em uso"* continuar lá |
| No mesmo caso, começar a digitar outro e-mail | A mensagem do servidor sumir |
| Digitar `nome@exemplo` (sem ponto depois do `@`) | Ser **aceito** pelo navegador: para o HTML, `nome@exemplo` é um e-mail possível. O Devise também aceita |

A última linha surpreende muita gente. Validar e-mail de verdade é bem mais difícil do que parece, e o único jeito de saber se um e-mail existe é **mandar uma mensagem para ele**. É exatamente o que a confirmação de cadastro do capítulo 0100 faz.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Stimulus** | Como um interruptor numa casa já construída: liga um comportamento em JavaScript a um elemento do HTML, por atributos `data-`. |
| **Controller Stimulus** | A classe JavaScript com os métodos que os eventos chamam. |
| **`data-action`** | Liga um evento a um método do controller, como uma rota liga um endereço a uma ação. |
| **Evento** | Algo que acontece na página: um clique, uma tecla, a saída de um campo, o envio de um formulário. |
| **Propagação de eventos** (*event bubbling*) | Como as ondas de uma pedra no lago: o evento acontece no campo e sobe pelos elementos que o contêm. |
| **Melhoria progressiva** (*progressive enhancement*) | Como a rampa ao lado da escada: a página funciona sem JavaScript, e o JavaScript só melhora a experiência. |
| **Constraint Validation API** | A capacidade do navegador de conferir as regras do HTML (`required`, `type`, `minlength`). |
| **Teste de sistema** | Um teste que abre um navegador de verdade e usa a página como uma pessoa. |
| **Capybara** | A gem que comanda o navegador nos testes de sistema. |
| **Headless** | Um navegador sem janela, que roda sem aparecer na tela. |

---

## O que aprendemos

- A validação do navegador **ajuda** quem preenche; a do servidor **protege** o sistema.
- O Stimulus liga comportamento ao HTML que o servidor já mandou, sem substituir o servidor.
- Um controller no `<main>`, com eventos que sobem, vale para todos os formulários.
- As regras ficam no HTML, e o JavaScript só as lê.
- O erro do navegador e o do servidor têm o mesmo formato, e quem preenche não percebe a diferença.
- Sem JavaScript, tudo continua funcionando.
- Texto em JavaScript entra com `textContent`, nunca com `innerHTML`.
- Teste de sistema prova o bolo: é o único jeito de testar o que roda no navegador.

**Próximo capítulo:** [0220 — Fotos dos equipamentos](0220-fotos-dos-equipamentos.md)

---

## Fontes

- [Stimulus — manual oficial](https://stimulus.hotwired.dev/handbook/introduction)
- [Stimulus — Actions](https://stimulus.hotwired.dev/reference/actions)
- [MDN — Constraint Validation API](https://developer.mozilla.org/en-US/docs/Web/HTML/Constraint_validation)
- [MDN — `ValidityState`](https://developer.mozilla.org/en-US/docs/Web/API/ValidityState)
- [MDN — `focusout`](https://developer.mozilla.org/en-US/docs/Web/API/Element/focusout_event)
- [Rails Guides — Testing: system testing](https://guides.rubyonrails.org/testing.html#system-testing)
