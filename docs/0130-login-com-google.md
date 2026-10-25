# 0130 — Login com o Google

> **Neste capítulo:** quem tem conta Google passa a entrar no Território Inteligente com **um clique**, sem criar senha. Você vai criar o seu próprio projeto no **Google Cloud**, guardar as chaves de acesso com segurança nas **credentials** do Rails, entender como o sistema decide entre **criar uma conta nova** e **reconhecer uma conta existente**, e montar um botão que segue as regras de marca do Google.

**Tag deste capítulo:** `cap-0130`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bundle install
bin/rails db:migrate
```

O código chega, mas o botão do Google **ainda não aparece**. Ele só aparece depois que você criar as **suas** chaves de acesso, nas Partes 2 e 3. Até lá, o login por e-mail e senha continua funcionando normalmente.

---

## Parte 1 — Como funciona o "Entrar com o Google"

Quando você clica em **Continuar com o Google**, o Território Inteligente **nunca vê a sua senha do Google**. O caminho é este:

1. O nosso site manda você para uma página **do Google**.
2. Lá, você entra na sua conta e o Google pergunta: *"o Território Inteligente quer saber seu nome e seu e-mail. Você autoriza?"*.
3. Se você autorizar, o Google devolve você para o nosso site com um **recado assinado**: *"esta pessoa é a Maria, e-mail maria@gmail.com, e o e-mail é verificado"*.
4. O nosso site confere a assinatura do recado, encontra ou cria a sua conta e faz o login.

Esse jeito de entrar se chama **OAuth**. É o mesmo do "Entrar com o Facebook" e de muitos outros. A vantagem é que a senha fica **só** com o Google: se o nosso banco vazar, não há senha nenhuma da sua conta Google lá dentro.

Para o Google aceitar conversar com o nosso site, precisamos **cadastrar** o site no Google e receber duas chaves:

| Chave | O que é | Comparação |
| --- | --- | --- |
| **ID do cliente** (*client_id*) | O "RG" do nosso site perante o Google | Pode ser visto, não é segredo |
| **Chave secreta** (*client_secret*) | A senha do nosso site perante o Google | **Nunca** vai para o GitHub nem para grupos |

---

## Parte 2 — Criando o seu projeto no Google Cloud

Cada pessoa da equipe cria **o seu próprio** projeto, com as **suas próprias** chaves. Assim, ninguém precisa compartilhar segredos, e cada um aprende a fazer a configuração inteira.

> ⚠️ **Qual conta usar:** use a sua conta **pessoal** do Google (Gmail). Contas de escola do Google Workspace for Education, quando são de menores de 18 anos, não têm acesso ao Google Cloud. Se a sua conta não conseguir, trabalhe em dupla com um colega nesta parte: o resto do projeto funciona sem o botão do Google.

### 2.1 Criar o projeto

1. Acesse **https://console.cloud.google.com** e entre com a sua conta Google.
2. No topo, clique no **seletor de projetos** e depois em **Novo projeto**.
3. Nome: `Territorio Inteligente Dev`. Clique em **Criar**.
4. Confira se o projeto novo está **selecionado** no seletor do topo.

### 2.2 Configurar a tela de permissão

É a tela em que o Google pergunta *"você autoriza?"*. No menu, procure **Google Auth Platform**.

> Em tutoriais mais antigos na internet, essa área aparece com o nome **Tela de permissão OAuth** (ou "Tela de consentimento OAuth"), dentro de **APIs e serviços**.

Clique em **Começar** e preencha:

| Campo | O que colocar |
| --- | --- |
| Nome do app | Território Inteligente |
| E-mail de suporte | o seu e-mail |
| Público | **Externo** |
| Dados de contato | o seu e-mail |

> Se aparecer uma mensagem de erro ao concluir, mas a tela mudar para a **Visão geral**, com o menu **Branding**, **Público-alvo** e **Clientes** à esquerda, a configuração foi criada. Confira os dados em **Branding** e **Público-alvo**.

### 2.3 Quem pode entrar: os usuários de teste

Em **Público-alvo**, o app fica em modo **Teste**. Nesse modo, só os e-mails da lista **Usuários de teste** conseguem entrar, até 100 pessoas. É perfeito para o desenvolvimento.

Clique em **Add users** e coloque **o seu e-mail**.

### 2.4 Criar o cliente

Em **Clientes**, clique em **Criar cliente**:

| Campo | O que colocar |
| --- | --- |
| Tipo de aplicativo | **Aplicativo da Web** |
| Nome | `Territorio Inteligente DEV` (só aparece para você) |
| Origens JavaScript autorizadas | deixe em branco |
| URIs de redirecionamento autorizados | `http://localhost:3000/users/auth/google_oauth2/callback` |

O **URI de redirecionamento** é o endereço para onde o Google devolve a pessoa depois que ela autoriza: o passo 3 da Parte 1. O Google só devolve para endereços cadastrados aqui. Assim, ninguém consegue usar as nossas chaves para mandar pessoas a um site falso.

Clique em **Criar**. Vai aparecer uma janela com o **ID do cliente** e a **Chave secreta**.

> ⚠️ **Copie os dois agora**, ou clique em **Baixar JSON**. Depois que você fechar essa janela, a chave secreta **não aparece de novo**.

---

## Parte 3 — Guardando as chaves com segurança: as credentials

As chaves não podem ficar no código, porque o código vai para o GitHub. O Rails tem um cofre para isso: as **credentials**, um arquivo **criptografado**.

### 3.1 Um cofre só para desenvolvimento

```bash
EDITOR="vim" bin/rails credentials:edit --environment development
```

- `EDITOR="vim"` diz qual editor abrir.
- `credentials:edit` abre o cofre para edição.
- `--environment development` cria um cofre **só para o ambiente de desenvolvimento**, separado do de produção.

Na primeira vez, o Rails cria dois arquivos. Antes de vê-los, precisamos conhecer o arquivo que decide o que **não** vai para o GitHub.

### O `.gitignore`: a lista do que o git deve ignorar

Na raiz do projeto existe um arquivo chamado `.gitignore`. O ponto no começo do nome faz dele um **arquivo oculto**: ele não aparece no `ls` comum, só no `ls -a`. Veja o conteúdo:

```bash
cat .gitignore
```

Cada linha é um **padrão** de arquivos ou pastas que o git deve **fingir que não existem**: eles não aparecem no `git status`, não entram no `git add .` e nunca vão para o GitHub. Alguns exemplos do nosso projeto:

| Linha | O que ignora | Por quê |
| --- | --- | --- |
| `/log/*` | Os registros do servidor | Mudam o tempo todo e são diferentes em cada máquina |
| `/tmp/*` | Arquivos temporários | São recriados sozinhos |
| `/config/*.key` | As chaves que abrem os cofres de credentials | São **segredos** |
| `/config/credentials/development.yml.enc` | O cofre de desenvolvimento | Cada pessoa tem o seu (veja abaixo) |

Como ler os padrões:

- a `/` no começo quer dizer *"a partir da raiz do projeto"*;
- o `*` quer dizer *"qualquer coisa"*: `/config/*.key` pega qualquer arquivo terminado em `.key` dentro de `config/`;
- linhas que começam com `#` são comentários.

> ⚠️ **O `.gitignore` não apaga o passado.** Ele só vale para arquivos que **ainda não** entraram em nenhum commit. Se um segredo já foi enviado ao GitHub, colocá-lo no `.gitignore` depois não o tira de lá: ele continua no histórico. Por isso, a regra é conferir o `git status` **antes** de cada `git add .`. E, se um segredo vazar, a única solução real é **trocá-lo**.

O próprio `.gitignore`, ao contrário, **vai** para o GitHub. Assim, todas as pessoas da equipe ignoram os mesmos arquivos.

Agora sim, os dois arquivos do cofre:

| Arquivo | O que é | Vai para o GitHub? |
| --- | --- | --- |
| `config/credentials/development.yml.enc` | O cofre: as chaves, criptografadas | **Não** (está no `.gitignore`) |
| `config/credentials/development.key` | A chave que abre o cofre | **Não** (o Rails põe no `.gitignore` sozinho) |

> 🔐 **Atenção:** ao criar o cofre, o Rails **mostra a chave no terminal**, numa linha como `Adding config/credentials/development.key to store the encryption key: ...`. Não copie essa saída para grupos, issues ou conversas.

O Vim abre o cofre. Aperte `i` para escrever e cole, trocando pelos valores que o Google te deu:

```yaml
google:
  client_id: COLE-AQUI-O-ID-DO-CLIENTE
  client_secret: COLE-AQUI-A-CHAVE-SECRETA
```

> ⚠️ **YAML é exigente com espaços:** `client_id` e `client_secret` têm **dois espaços** na frente. Espaços, não tab.

Aperte `Esc`, digite `:wq` e Enter. O Rails criptografa e salva.

### 3.2 Conferindo

```bash
bin/rails runner 'puts Rails.application.credentials.dig(:google, :client_id).present?'
```

- `bin/rails runner` executa uma linha de Ruby dentro do projeto, sem abrir o console.
- `credentials.dig(:google, :client_id)` busca o valor de `client_id` dentro de `google`.
- `.present?` responde se há algo ali.

A resposta deve ser `true`. Confira também:

```bash
git status
```

**Nenhum** arquivo de `config/credentials/` pode aparecer. Se aparecer, chame o educador antes de qualquer commit.

> 💡 **Por que cada um tem o seu cofre?** O arquivo `development.yml.enc` está no `.gitignore` do projeto. Se ele fosse para o GitHub, cada pessoa da equipe tentaria enviar o **seu** cofre, com as **suas** chaves, e ninguém conseguiria abrir o cofre dos outros, porque cada `development.key` é diferente.

---

## Parte 4 — As gems e a migration

```bash
bundle add omniauth-google-oauth2 omniauth-rails_csrf_protection
```

| Gem | Para quê |
| --- | --- |
| `omniauth-google-oauth2` | Sabe conversar com o Google pelo OAuth |
| `omniauth-rails_csrf_protection` | Proteção de segurança: só aceita iniciar o login com o Google por um **botão** (`POST`), nunca por um simples link |

A segunda gem tem a ver com o "Sair" do capítulo 0100: ações importantes não podem acontecer por um link, que qualquer site poderia esconder numa página.

Agora, a tabela `users` precisa saber **com qual conta Google** cada usuário entrou:

```bash
bin/rails generate migration AddOmniauthToUsers provider:string uid:string
```

```ruby
def change
  add_column :users, :provider, :string
  add_column :users, :uid, :string
  add_index :users, [ :provider, :uid ], unique: true
end
```

| Coluna | Exemplo | O que guarda |
| --- | --- | --- |
| `provider` | `google_oauth2` | Por qual serviço a pessoa entrou |
| `uid` | `108374652...` | O número que o Google usa para identificar essa conta |

O índice único em `[ :provider, :uid ]` garante que a mesma conta Google nunca fique ligada a dois usuários.

> 💡 Por que guardar o `uid` e não só o e-mail? Porque a pessoa pode **trocar** o e-mail da conta Google. O `uid` nunca muda.

```bash
bin/rails db:migrate
```

---

## Parte 5 — Configurando o Devise

### 5.1 As chaves

Em `config/initializers/devise.rb`:

```ruby
config.omniauth :google_oauth2,
                Rails.application.credentials.dig(:google, :client_id),
                Rails.application.credentials.dig(:google, :client_secret),
                scope: "email,profile"
```

O `scope` diz **o que** pedimos ao Google: `email` e `profile` (nome). Nada mais. É a LGPD na prática: pedir só o necessário.

Lembra da Manha 1 do capítulo 0100? Initializer só vale **depois de reiniciar o servidor**.

### 5.2 O model

Em `app/models/user.rb`, o Devise ganha o módulo `:omniauthable`:

```ruby
devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable, :confirmable,
       :omniauthable, omniauth_providers: [ :google_oauth2 ]
```

### 5.3 A rota

Em `config/routes.rb`, a linha do Devise passa a dizer **qual controller** recebe a volta do Google:

```ruby
devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }
```

---

## Parte 6 — Conta nova ou conta conhecida? `from_omniauth`

Quando o Google devolve a pessoa, o sistema precisa decidir: *"quem é esta pessoa?"*. Essa decisão mora no model, em `app/models/user.rb`:

```ruby
def self.from_omniauth(auth)
  # 1. Já entrou com o Google antes?
  user = find_by(provider: auth.provider, uid: auth.uid)
  return user if user

  verificado = auth.info.email_verified

  # 2. Já tem conta com este e-mail? Só junta se o Google garantir o e-mail
  user = find_by(email: auth.info.email) if verificado
  if user
    user.update!(provider: auth.provider, uid: auth.uid)
    user.confirm unless user.confirmed?
    return user
  end

  # 3. Conta nova
  create(provider: auth.provider,
         uid: auth.uid,
         email: auth.info.email,
         nome: auth.info.name,
         password: Devise.friendly_token[0, 20]) do |novo|
    novo.skip_confirmation! if verificado
  end
end
```

O `auth` é o **recado** que o Google mandou (passo 3 da Parte 1). Dentro dele: `auth.provider`, `auth.uid`, `auth.info.email`, `auth.info.name` e `auth.info.email_verified`.

O método testa três situações, em ordem:

| Situação | O que acontece |
| --- | --- |
| **1.** Esta conta Google já entrou antes | Encontra pelo `provider` + `uid` e devolve. É a pessoa voltando |
| **2.** Existe uma conta com este e-mail, criada por e-mail e senha | **Junta** a conta Google à conta existente, mas **só** se o Google garantir que o e-mail é da pessoa |
| **3.** Ninguém conhecido | Cria uma conta nova |

### Por que conferir se o e-mail é verificado?

Imagine que a Ana tem conta no Território Inteligente com `ana@exemplo.com`. Se alguém conseguisse uma conta Google com esse e-mail **sem comprovar que é o dono**, e o nosso sistema juntasse as contas sem conferir, essa pessoa entraria na conta da Ana. O `email_verified` é a garantia do Google de que o e-mail pertence a quem está entrando.

### Detalhes da conta nova

| Trecho | Por quê |
| --- | --- |
| `nome: auth.info.name` | O nome vem do Google, e o `login` é gerado a partir dele (capítulo 0120) |
| `password: Devise.friendly_token[0, 20]` | O Devise exige uma senha. Geramos uma aleatória, que ninguém conhece. A pessoa entra pelo Google. Se um dia quiser, pode criar uma senha pelo "Esqueceu sua senha?" |
| `novo.skip_confirmation!` | O Google já garantiu o e-mail. Mandar e-mail de confirmação seria pedir duas vezes a mesma coisa |
| (nada sobre foto) | O Google oferece a foto da pessoa (`auth.info.image`), mas **não guardamos**. Combinamos não guardar fotos de rosto |

O `role` não aparece em lugar nenhum: a conta nasce **comum**, pelo `default` do capítulo 0110.

---

## Parte 7 — O controller da volta

Crie `app/controllers/users/omniauth_callbacks_controller.rb`:

```ruby
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      flash[:notice] = I18n.t("devise.omniauth_callbacks.success", kind: "Google")
      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.to_sentence
    end
  end

  def failure
    redirect_to root_path, alert: "Não foi possível entrar com o Google."
  end
end
```

| Trecho | O que faz |
| --- | --- |
| `Users::OmniauthCallbacksController` | O `Users::` indica que o arquivo está na pasta `app/controllers/users/` |
| `request.env["omniauth.auth"]` | O recado do Google, entregue pela gem |
| `@user.persisted?` | A conta está salva no banco? Se a criação falhou, a resposta é não |
| `sign_in_and_redirect` | Faz o login e leva para a página inicial |
| `failure` | Chamado quando a pessoa cancela no Google ou algo dá errado |

É o garçom do MVC: recebe o pedido (a volta do Google), pede ao model (`from_omniauth`) e decide para onde mandar a pessoa.

---

## Parte 8 — O botão

### 8.1 Só aparece quando há chaves

Em `app/helpers/application_helper.rb`:

```ruby
module ApplicationHelper
  def login_com_google?
    Rails.application.credentials.dig(:google, :client_id).present?
  end
end
```

**Helpers** são métodos que as views podem usar. Este responde: *"esta máquina tem as chaves do Google?"*. Se não tiver, o botão não aparece, e o sistema continua funcionando por e-mail e senha.

### 8.2 O partial do botão

Crie `app/views/devise/shared/_google.html.erb`:

```erb
<% if devise_mapping.omniauthable? && login_com_google? %>
  <%= button_to omniauth_authorize_path(resource_name, :google_oauth2),
                data: { turbo: false }, class: "botao-google" do %>
    <%= image_tag "google-g.svg", alt: "", width: 20, height: 20 %>
    <span>Continuar com o Google</span>
  <% end %>

  <p class="divisor">ou</p>
<% end %>
```

| Trecho | O que faz |
| --- | --- |
| `button_to` | Um botão (`POST`), como exige a gem de proteção |
| `data: { turbo: false }` | O Turbo não pode interceptar este botão: a página precisa sair do nosso site e ir **de verdade** para o Google |
| `image_tag "google-g.svg", alt: ""` | O logo. O `alt` fica vazio porque o texto do lado já diz tudo, e o leitor de tela não precisa ouvir duas vezes |
| `<p class="divisor">ou</p>` | A linha "ou" que separa o Google do formulário |

Um **partial** é um pedaço de view reaproveitável: o nome do arquivo começa com `_`. Usamos o mesmo botão em duas páginas, no topo do login (`sessions/new.html.erb`) e do cadastro (`registrations/new.html.erb`):

```erb
<%= render "devise/shared/google" %>
```

O botão antigo, que o Devise colocava no fim da página (no `_links.html.erb`), foi removido.

### 8.3 As regras de marca do Google

O Google define como esse botão pode ser:

- o logo "G" tem de ser o **oficial**, sem redesenhar e sem mudar as cores;
- o texto pode ser "Entrar com o Google" ou "Continuar com o Google". Escolhemos **"Continuar com o Google"** porque o mesmo botão aparece no login e no cadastro, e "continuar" serve para quem já tem conta e para quem ainda não tem;
- as cores do botão seguem a paleta definida pelo Google.

Por isso, o arquivo `app/assets/images/google-g.svg` foi baixado da página oficial: **https://developers.google.com/identity/branding-guidelines**.

> 💡 **Manha: respeite as marcas dos outros.** Logos e nomes de empresas têm dono. Quando um serviço publica regras de uso da marca, seguir essas regras é o que nos permite usar o logo. Para o nosso projeto, vale o contrário também: os avatares e imagens que o time de design criar devem ser **originais**.

### 8.4 O CSS do botão

No `10-base.css`:

```css
.botao-google {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--espaco-1);
  justify-self: stretch;
  width: 100%;
  min-height: 3rem;
  background: #ffffff;
  color: #1f1f1f;
  border: 1px solid #747775;
  font-size: var(--texto-m);
  font-weight: 600;
}
```

Repare: aqui as cores estão escritas direto, **sem** os tokens do `01-tokens.css`. De propósito: essas cores são **do Google**, não do projeto. Se o time de design mudar a paleta do Território Inteligente, o botão do Google não pode mudar junto.

O `min-height: 3rem` (48 px) é a área de toque confortável para um dedo no celular, que é o foco do projeto.

---

## Parte 9 — A mensagem de boas-vindas

A tradução do `devise-i18n` mostrava *"Autorizado com sucesso de uma conta de Google."*. Ajustamos no nosso `config/locales/pt-BR.yml`, dentro do `pt-BR:`:

```yaml
  devise:
    omniauth_callbacks:
      success: "Você entrou com a sua conta %{kind}."
```

O `%{kind}` é trocado por "Google", que o controller manda na Parte 7.

Lembra do capítulo 0100? A gem traz as traduções do Devise **dentro dela**. O nosso `pt-BR.yml` só **sobrescreve** o que queremos mudar.

---

## Parte 10 — Os testes

Testar o login com o Google **de verdade** exigiria abrir o site do Google durante o teste. Em vez disso, testamos a **decisão** do `from_omniauth` com um recado falso, montado com `OmniAuth::AuthHash`. No fim de `test/models/user_test.rb`:

```ruby
  def auth_google(email:, verificado: true, nome: "Bia Santos", uid: "123")
    OmniAuth::AuthHash.new(provider: "google_oauth2", uid: uid,
                           info: { email: email, name: nome, email_verified: verificado })
  end

  test "cria conta nova com o Google, já confirmada" do
    user = User.from_omniauth(auth_google(email: "bia@gmail.com"))
    assert user.persisted?
    assert user.confirmed?
    assert_equal "bia", user.login
    assert user.comum?
  end

  test "junta o Google a uma conta existente quando o e-mail é verificado" do
    user = User.from_omniauth(auth_google(email: "ana@exemplo.com", nome: "Ana"))
    assert_equal users(:ana), user
    assert_equal "google_oauth2", user.provider
  end

  test "não junta contas quando o Google não garante o e-mail" do
    user = User.from_omniauth(auth_google(email: "ana@exemplo.com", verificado: false))
    assert_not user.persisted?
  end
```

| Teste | O que garante |
| --- | --- |
| "cria conta nova..." | A situação 3: conta nova, confirmada, com login gerado do nome e nível comum |
| "junta o Google..." | A situação 2: a fixture `ana` ganha o Google, sem conta duplicada |
| "não junta contas..." | A proteção de segurança: e-mail não verificado **não** entra na conta da Ana |

O terceiro teste é o mais importante: ele protege a regra de segurança da Parte 6. Se alguém, no futuro, apagar a conferência do `email_verified`, este teste falha e avisa.

```bash
bin/rails test
```

Devem passar **7 testes**.

---

## Parte 11 — Testando no navegador

1. Reinicie o servidor (`bin/dev`), por causa do initializer.
2. Abra **Entrar**: o botão **Continuar com o Google** aparece no topo. Ele aparece também em **Cadastrar**.
3. Clique, escolha a sua conta Google e autorize.
4. Você volta para a página inicial, logado, com a mensagem *"Você entrou com a sua conta Google."*.
5. Saia e entre de novo com o Google.

No pgAdmin:

```sql
SELECT email, nome, login, role, provider, uid, confirmed_at FROM users;
```

A sua conta aparece **uma vez só**, com `provider` igual a `google_oauth2`, `role` igual a `2` e `confirmed_at` preenchido. Entrar duas vezes **não** duplica a conta: na segunda vez, o sistema caiu na situação 1.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **OAuth** | O jeito de entrar num site usando a conta de outro serviço, sem passar a senha. |
| **Client ID e client secret** | O "RG" e a senha do nosso site perante o Google. |
| **URI de redirecionamento** | O endereço para onde o Google devolve a pessoa depois que ela autoriza. |
| **Escopo** (*scope*) | O que pedimos ao Google: no nosso caso, só nome e e-mail. |
| **Credentials** | O cofre criptografado do Rails para guardar senhas e chaves. |
| **uid** | O número que identifica uma conta Google e nunca muda. |
| **Helper** | Um método que as views podem usar. |
| **Partial** | Um pedaço de view reaproveitável, com nome começando por `_`. |

---

## O que aprendemos

- Com o OAuth, a senha fica com o Google: o nosso site recebe só um recado assinado.
- Chaves secretas ficam nas **credentials**, nunca no código. E nunca colamos a chave do cofre em lugar público.
- Cada pessoa da equipe tem o **seu** cofre de desenvolvimento.
- Pedimos ao Google **só** o necessário: nome e e-mail.
- Só juntamos contas quando o e-mail é **verificado**, e um teste protege essa regra.
- Marcas têm regras de uso: o botão segue as do Google.
- Ações importantes usam **botão** (`POST`), e não link.

**Próximo capítulo:** em breve.
