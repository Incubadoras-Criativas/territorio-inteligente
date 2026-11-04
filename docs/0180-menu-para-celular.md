# 0180 — Menu para celular

> **Neste capítulo:** o site ganha a cara de um aplicativo de celular. No rodapé, uma **barra de abas** fixa com os destinos principais. Num toque, um **menu completo** sobe da parte de baixo da tela com todas as opções. Vamos usar ícones de uma biblioteca livre, o **Lucide**, ver como o HTML abre e fecha um painel **sem nenhuma linha de JavaScript** e cuidar de quem navega com leitor de tela.

**Tag deste capítulo:** `cap-0180`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails test
```

Este capítulo não tem migration nem gem nova.

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
> git switch -c estudo-0180 cap-0180
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
> git branch -D estudo-0180
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

Até aqui, o menu era uma linha de links no topo da página: Início, Equipamentos, Meu perfil, Usuários, Sair... No computador, cabia. No celular, com 320 pixels de largura, os links se espremiam, quebravam em várias linhas e empurravam o conteúdo para baixo.

E é no celular que o Território Inteligente vai ser usado: na praça, em pé, ao lado do equipamento. O menu precisava ser pensado **para o polegar**.

### As opções

| Opção | Como é | Ponto forte | Ponto fraco |
| --- | --- | --- | --- |
| **A. Barra de abas** | Ícones fixos no rodapé, sempre à vista | Um toque leva a qualquer destino principal. O polegar alcança | Cabem só 4 ou 5 itens |
| **B. Menu "hambúrguer"** | Um botão abre uma lista com tudo | Cabem quantos itens quiser | Esconde as opções: quem não abre, não descobre |
| **C. As duas juntas** | A barra com os principais, e a última aba abre o menu completo | Os destinos frequentes ficam à vista, e nada fica de fora | Um pouco mais de código |

Escolhemos a **C**, que é o padrão de muitos aplicativos de celular. Na barra, os destinos de todo dia: **Início, Equipamentos, Perfil** (ou **Entrar**, para quem não está logado) e **Menu**. No menu completo, **todos** os itens, inclusive os da barra: quem prefere a lista também encontra tudo ali.

---

## Parte 2 — Os ícones do Lucide

### 2.1 Por que uma biblioteca de ícones?

Desenhar ícones bons é um trabalho de designer, e um conjunto precisa ter **o mesmo estilo**: a mesma espessura de traço, o mesmo tamanho, os mesmos cantos. O **Lucide** é uma coleção com mais de mil ícones feitos assim, de código aberto.

### 2.2 A licença

Pense numa receita de família que a avó deixa todo mundo usar, com um único pedido: *"diga que a receita é minha"*.

Em termos técnicos, o Lucide usa a licença **ISC**, uma das mais livres que existem. Ela permite usar, copiar, modificar e até vender, com **uma condição**: o aviso de copyright e o texto da licença precisam acompanhar os ícones. Por isso o projeto tem o arquivo:

```
app/assets/images/icones/LICENSE-lucide.txt
```

> ⚠️ **Licença não é detalhe.** Pegar uma imagem ou um ícone "da internet" sem conferir a licença pode virar um problema legal para o projeto. Antes de usar qualquer coisa feita por outra pessoa, procure o arquivo `LICENSE` e leia o que ele pede.

### 2.3 Os arquivos

Cada ícone foi baixado em **lucide.dev/icons**, com o botão *Download SVG*:

| Arquivo | Desenho | Uso |
| --- | --- | --- |
| `house.svg` | casa | Início |
| `dumbbell.svg` | halter | Equipamentos |
| `user.svg` | pessoa | Perfil, para quem ainda não escolheu avatar |
| `log-in.svg` | seta entrando | Entrar |
| `menu.svg` | três linhas | Menu |
| `x.svg` | xis | Fechar o menu |

Todos ficam em `app/assets/images/icones/`.

---

## Parte 3 — O helper `icone`

### 3.1 O que é SVG?

Uma foto é como um mosaico: milhares de pastilhas coloridas, os pixels. Se você ampliar demais, aparecem as pastilhas. Um **SVG** é como as instruções de um desenho: *"trace uma linha daqui até ali, faça um círculo deste tamanho"*. Ampliou? O desenho é refeito com as mesmas instruções, sempre nítido.

Em termos técnicos, SVG (*Scalable Vector Graphics*) é um formato de imagem **vetorial** escrito em texto, numa linguagem parecida com o HTML. Abra o `house.svg` no Kate e confira:

```xml
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
     fill="none" stroke="currentColor" stroke-width="2" ...>
  <path d="..."/>
</svg>
```

Repare no `stroke="currentColor"`: o traço do desenho usa **a cor do texto ao redor**. Se o link é branco, o ícone é branco. Se o link fica amarelo, o ícone acompanha.

### 3.2 Por que não usar `image_tag`?

Com `image_tag "icones/house.svg"`, o SVG vira uma **imagem separada**, e a imagem não enxerga a cor do texto da página: o `currentColor` deixa de funcionar. Para o ícone mudar de cor junto com a aba, o SVG precisa estar **dentro** do HTML. É o que o helper faz.

### 3.3 O código

Em `app/helpers/application_helper.rb`:

```ruby
def icone(nome)
  svg = Rails.root.join("app/assets/images/icones/#{nome}.svg").read
  svg.sub("<svg", '<svg class="icone" aria-hidden="true" focusable="false"').html_safe
end
```

Na view, `<%= icone("house") %>` coloca o desenho da casa no meio do HTML.

| Trecho | O que faz |
| --- | --- |
| `.read` | Lê o arquivo SVG como texto |
| `svg.sub("<svg", ...)` | Troca a **primeira** ocorrência de `<svg` por `<svg` com três atributos a mais |
| `class="icone"` | Para o CSS controlar o tamanho |
| `aria-hidden="true"` | O leitor de tela **pula** o desenho e lê o rótulo ao lado. Sem isso, ele poderia anunciar "imagem, imagem, imagem" |
| `focusable="false"` | Impede que alguns navegadores parem no ícone quando a pessoa navega com a tecla Tab |
| `.html_safe` | O Rails não escapa o SVG, e o desenho aparece |

> 💡 **Este `html_safe` é seguro?** Sim, pelo mesmo raciocínio do capítulo 0170. O nome do ícone vem **sempre do nosso código**, como em `icone("house")`, e nunca do que um visitante digita. E o arquivo lido é um SVG que nós colocamos no projeto.

---

## Parte 4 — O layout

### 4.1 A estrutura

O `app/views/layouts/application.html.erb` passou a ter quatro blocos:

```
┌──────────────────────────┐
│ header.topo              │  o nome do site
├──────────────────────────┤
│                          │
│ main                     │  o conteúdo de cada página
│                          │
├──────────────────────────┤
│ nav.barra-abas           │  fixa no rodapé
└──────────────────────────┘
  div#menu-completo           escondido, até alguém tocar em "Menu"
```

### 4.2 O cabeçalho

```erb
<header class="topo">
  <%= link_to "Território Inteligente", root_path, class: "marca" %>
</header>
```

O nome do site sempre leva à página inicial, um costume da web que todo mundo já espera.

### 4.3 A barra de abas

```erb
<nav class="barra-abas" aria-label="Navegação principal">
  <%= link_to root_path, class: "aba", aria: { current: ("page" if current_page?(root_path)) } do %>
    <%= icone("house") %><span>Início</span>
  <% end %>

  <%= link_to equipamentos_path, class: "aba", aria: { current: ("page" if controller_name == "equipamentos") } do %>
    <%= icone("dumbbell") %><span>Equipamentos</span>
  <% end %>

  <% if user_signed_in? %>
    <%= link_to edit_perfil_path, class: "aba", aria: { current: ("page" if controller_name == "perfis") } do %>
      <% if current_user.avatar %>
        <%= image_tag "avatares/#{current_user.avatar}", alt: "", class: "icone" %>
      <% else %>
        <%= icone("user") %>
      <% end %>
      <span>Perfil</span>
    <% end %>
  <% else %>
    <%= link_to new_user_session_path, class: "aba" do %>
      <%= icone("log-in") %><span>Entrar</span>
    <% end %>
  <% end %>

  <button type="button" class="aba" popovertarget="menu-completo">
    <%= icone("menu") %><span>Menu</span>
  </button>
</nav>
```

**Cada aba tem ícone e texto.** Ícone sozinho obriga a pessoa a adivinhar: uma casa é "início" ou "meu endereço"? Com o texto embaixo, ninguém precisa adivinhar.

**A aba Perfil mostra o avatar**, quando a pessoa já escolheu um. Ali, o `image_tag` é o certo: o avatar é uma imagem colorida e não precisa mudar de cor.

**`link_to ... do`**: quando o link tem mais do que texto (aqui, ícone + rótulo), o conteúdo vai num bloco `do ... end`, e o endereço vem como primeiro argumento.

### 4.4 Qual aba está ativa? O `aria-current`

Imagine um shopping com uma placa *"você está aqui"* no mapa. Sem ela, o mapa mostra tudo, mas você não sabe onde está.

Em termos técnicos, o atributo **`aria-current="page"`** marca o link da página atual. Ele serve a duas pessoas ao mesmo tempo:

- quem usa **leitor de tela** ouve *"Equipamentos, link, página atual"*;
- o **CSS** usa o mesmo atributo para pintar a aba de amarelo (Parte 5).

Uma marcação, dois benefícios. É melhor do que criar uma classe `.ativa` só para a cor, que o leitor de tela não entenderia.

| Trecho | Pergunta que responde |
| --- | --- |
| `current_page?(root_path)` | "Estamos exatamente na página inicial?" |
| `controller_name == "equipamentos"` | "Estamos em **alguma** página de equipamentos?" A aba fica ativa na lista e também na página do leg press |
| `("page" if ...)` | Devolve `"page"` ou `nil`. Com `nil`, o Rails **não escreve** o atributo |

### 4.5 O menu completo: `popover`

```erb
<div id="menu-completo" class="menu-completo" popover>
  <button type="button" class="fechar-menu" popovertarget="menu-completo" popovertargetaction="hide">
    <%= icone("x") %><span>Fechar</span>
  </button>

  <ul role="list">
    <li><%= link_to "Início", root_path %></li>
    <li><%= link_to "Equipamentos", equipamentos_path %></li>
    <% if user_signed_in? %>
      <li><%= link_to "Meu perfil", edit_perfil_path %></li>
      <% if current_user.admin? %>
        <li><%= link_to "Usuários", admin_users_path %></li>
      <% end %>
      <li><%= link_to "Trocar e-mail ou senha", edit_user_registration_path %></li>
      <li><%= button_to "Sair", destroy_user_session_path, method: :delete %></li>
    <% else %>
      <li><%= link_to "Entrar", new_user_session_path %></li>
      <li><%= link_to "Cadastrar", new_user_registration_path %></li>
    <% end %>
  </ul>
</div>
```

Pense numa gaveta com um puxador. A gaveta (o `div` com `popover`) fica fechada. O puxador (o botão com `popovertarget`) diz **qual** gaveta abrir, pelo `id`.

Em termos técnicos, o **`popover`** é um recurso do **próprio HTML**, que os navegadores modernos entendem desde 2024. Um elemento com o atributo `popover` começa escondido. Um botão com `popovertarget="menu-completo"` abre e fecha o elemento com esse `id`. E o navegador ainda faz, sozinho:

- fecha o painel quando a pessoa toca **fora** dele;
- fecha com a tecla **Esc**;
- coloca o painel **por cima** de tudo, sem precisar brigar com `z-index`.

Tudo isso **sem uma linha de JavaScript**. Antes do `popover`, um menu assim pedia um controller Stimulus só para abrir, fechar, ouvir o Esc e o toque fora.

| Atributo | Onde | O que faz |
| --- | --- | --- |
| `popover` | No `div` | "Eu sou um painel que abre e fecha" |
| `popovertarget="menu-completo"` | No botão | "Eu abro e fecho o painel com este `id`" |
| `popovertargetaction="hide"` | No botão Fechar | "Eu **só** fecho." Sem isso, ele alternaria entre abrir e fechar |

**O "Usuários" só aparece para administradores.** Esconder o link não é a segurança: a segurança é o porteiro do capítulo 0150, que barra quem não é admin mesmo que digite o endereço. Esconder o link é **cortesia**: ninguém precisa ver uma opção que não pode usar.

**O "Sair" é um `button_to`**, como no menu antigo: sair muda o estado do servidor (encerra a sessão), então usa `DELETE`, e não um link comum.

---

## Parte 5 — O CSS

### 5.1 Um arquivo próprio

A navegação ganhou o arquivo `app/assets/stylesheets/20-navegacao.css`, e as regras antigas de `nav` saíram do `10-base.css`. Se as duas ficassem, as regras antigas e as novas brigariam pelo mesmo elemento.

O `main` ficou com uma regra só no `10-base.css`, agora com espaço nas bordas:

```css
main {
  padding: var(--espaco-2);
}
```

Sem esse espaço, o texto e os campos encostavam na borda da tela do celular, e o contorno laranja de foco, que mostra onde está o cursor, era cortado. Repare que o valor vem do token `--espaco-2`, e não de um número solto: se a escala de espaços do projeto mudar, o `main` acompanha.

### 5.2 A barra fixa no rodapé

```css
body {
  padding-bottom: 5rem;
}

.barra-abas {
  position: fixed;
  inset-inline: 0;
  bottom: 0;
  z-index: 10;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  padding: 0 0 env(safe-area-inset-bottom);
  background: var(--cor-roxo);
}
```

| Regra | O que faz |
| --- | --- |
| `position: fixed` + `bottom: 0` | A barra fica **presa** ao rodapé da tela, mesmo quando a página rola |
| `inset-inline: 0` | Encosta nas duas laterais: ocupa a largura toda |
| `grid-template-columns: repeat(4, 1fr)` | Quatro colunas **iguais**, uma para cada aba |
| `env(safe-area-inset-bottom)` | Em celulares sem botão físico, deixa espaço para a barrinha do sistema não cobrir as abas |
| `body { padding-bottom: 5rem }` | Um espaço no fim de **toda** página. Sem ele, o último item da lista ficaria escondido atrás da barra |

### 5.3 As abas

```css
.aba {
  display: flex;
  flex-direction: column;
  align-items: center;
  min-height: 3.5rem;
  color: var(--cor-branco);
  /* ... */
}

.aba[aria-current="page"] {
  color: var(--cor-amarelo);
  font-weight: 700;
}
```

- `flex-direction: column`: o ícone fica **em cima** do texto.
- `min-height: 3.5rem` (56 px): uma área de toque confortável. A recomendação de acessibilidade é de pelo menos 44 px para um dedo acertar sem esforço.
- `.aba[aria-current="page"]`: é o **seletor de atributo**. Ele vale só para a aba que tem `aria-current="page"`, ou seja, a da página atual. A cor muda, e o ícone muda junto, graças ao `currentColor`.

### 5.4 O painel que sobe do rodapé

```css
.menu-completo {
  inset: auto 0 0 0;
  width: 100%;
  max-height: 80vh;
  margin: 0;
  border-radius: var(--raio) var(--raio) 0 0;
  background: var(--cor-branco);
}

.menu-completo::backdrop {
  background: rgb(0 0 0 / 0.4);
}
```

- Por padrão, o navegador abre o `popover` **no centro** da tela. O `inset: auto 0 0 0` (em cima automático; direita, embaixo e esquerda zero) cola o painel no rodapé, de uma borda à outra.
- `max-height: 80vh`: no máximo 80% da altura da tela. Sobra uma faixa em cima, e a pessoa vê que ainda está no site.
- `border-radius` só nos dois cantos de cima: o desenho de "folha que sobe", comum nos aplicativos.
- `::backdrop` é o fundo **atrás** do painel. Com preto 40% transparente, a página escurece e o menu ganha destaque. Tocar nesse fundo fecha o menu.

---

## Parte 6 — Os testes

No `test/controllers/paginas_controller_test.rb`:

```ruby
test "visitante vê Entrar na barra e não vê Usuários no menu" do
  get root_url
  assert_select ".barra-abas", text: /Entrar/
  assert_select "#menu-completo a", text: "Usuários", count: 0
end

test "administrador vê Usuários no menu" do
  sign_in users(:admin)
  get root_url
  assert_select "#menu-completo a", text: "Usuários"
end

test "a aba da página atual fica marcada" do
  get root_url
  assert_select ".barra-abas a[aria-current=page]", text: /Início/
end
```

O **`assert_select`** procura elementos no HTML da resposta, com os **mesmos seletores do CSS**:

| Trecho | O que confere |
| --- | --- |
| `".barra-abas", text: /Entrar/` | Dentro da barra, existe o texto "Entrar" |
| `"#menu-completo a", text: "Usuários", count: 0` | No menu, **nenhum** link "Usuários" (`count: 0`) |
| `".barra-abas a[aria-current=page]"` | Na barra, um link marcado como página atual... |
| `text: /Início/` | ...e esse link é o Início |

O primeiro teste confere uma regra de **cortesia** (o visitante não vê o que não pode usar). O terceiro confere uma regra de **acessibilidade**. Ambas são fáceis de quebrar sem perceber numa mudança futura do layout, e é para isso que o teste existe.

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 7 — Testando no navegador

Abra o DevTools (F12), ligue o **modo celular** (Ctrl+Shift+M) e escolha uma largura de **320 px**, a de um celular pequeno.

1. A barra aparece no rodapé, com 4 abas, e **Início** está em amarelo.
2. Toque em **Equipamentos**: o destaque muda de aba. Abra um equipamento: a aba **continua** ativa.
3. Toque em **Menu**: o painel sobe com todos os itens, e a página escurece atrás.
4. Feche de três jeitos: pelo **Fechar**, tocando **fora** do painel e com **Esc**.
5. Entre como admin: o menu ganha **Usuários**, e a aba Perfil mostra o seu avatar.
6. Abra a lista de usuários e role até o fim: o último cartão **não** fica escondido atrás da barra.

### Tente quebrar

| Tente | O que o sistema deve fazer |
| --- | --- |
| Navegar só com o **teclado** (Tab, Enter, Esc) | Passar por todas as abas, abrir o menu com Enter e fechar com Esc. O contorno de foco aparece inteiro em cada item |
| Ligar um **leitor de tela** (no Kubuntu, o Orca, pelo menu de aplicativos) | Ler "Navegação principal" na barra e "página atual" na aba ativa. Os ícones não são anunciados |
| Diminuir a largura para **280 px** | As quatro abas continuam cabendo, sem o texto encavalar |
| Abrir o menu e **girar** o celular (no DevTools, o botão de girar) | O painel continua colado no rodapé |
| Como visitante, digitar `/admin/users` na barra de endereço | Ser barrado pelo porteiro do capítulo 0150: esconder o link nunca foi a proteção |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Barra de abas** (*tab bar*) | Os ícones fixos no rodapé de um aplicativo, com os destinos principais sempre à vista. |
| **SVG** | Uma imagem feita de instruções de desenho, e não de pixels: fica nítida em qualquer tamanho. |
| **`currentColor`** | No CSS e no SVG, "a cor do texto ao redor". |
| **Licença ISC** | Uma licença livre: use à vontade, mas mantenha o aviso de copyright junto. |
| **`popover`** | Um recurso do HTML para painéis que abrem e fecham sem JavaScript. |
| **`::backdrop`** | O fundo atrás de um `popover` aberto. |
| **ARIA** | Atributos (`aria-label`, `aria-current`, `aria-hidden`) que explicam a página para o leitor de tela. |
| **`aria-current="page"`** | Como o "você está aqui" do mapa do shopping: marca o link da página atual. |
| **Área de toque** | O tamanho do espaço que o dedo precisa acertar. Pelo menos 44 px. |

---

## O que aprendemos

- Um site usado na rua precisa ser pensado **para o polegar**.
- A barra de abas mostra o que é frequente; o menu completo garante que nada fique de fora.
- Antes de usar trabalho alheio, **confira a licença** e cumpra o que ela pede.
- Um SVG dentro do HTML acompanha a cor do texto.
- O `popover` do HTML faz, sem JavaScript, o que antes pedia um controller inteiro.
- Uma marcação de acessibilidade, como o `aria-current`, pode servir também ao CSS.
- Esconder um link é cortesia; a segurança fica no controller.

**Próximo capítulo:** [0190 — Administração dos equipamentos](0190-administracao-dos-equipamentos.md)

---

## Fontes

- [Lucide — ícones](https://lucide.dev/icons)
- [Lucide — licença](https://lucide.dev/license)
- [MDN — atributo global `popover`](https://developer.mozilla.org/en-US/docs/Web/HTML/Global_attributes/popover)
- [MDN — `aria-current`](https://developer.mozilla.org/en-US/docs/Web/Accessibility/ARIA/Attributes/aria-current)
- [MDN — `env()` e `safe-area-inset`](https://developer.mozilla.org/en-US/docs/Web/CSS/env)
