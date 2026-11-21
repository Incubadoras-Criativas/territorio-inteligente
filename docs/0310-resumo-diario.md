# 0310 — O resumo diário e os e-mails na fila

> **Neste capítulo:** os e-mails do projeto deixam de ser enviados no meio do pedido e passam a sair pela **fila de tarefas**, com novas tentativas quando o servidor de e-mail falha. Assim, um problema no e-mail não derruba mais um cadastro. E quem modera passa a receber, todo dia às 8h, um **resumo por e-mail** do que espera decisão, só nos dias em que há algo esperando. No caminho, conhecemos os **jobs**, as **tarefas recorrentes** do Solid Queue, o **cron** e o **preview de e-mails** do Rails.

**Tag deste capítulo:** `cap-0310`

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

Este capítulo não tem migrations: o `db:migrate` não vai fazer nada. Ele fica na lista para manter o costume.

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
> git switch -c estudo-0310 cap-0310
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
> git branch -D estudo-0310
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

## Parte 1 — Dois problemas, uma ferramenta

Este capítulo resolve dois problemas, e os dois se resolvem com a mesma ferramenta: a **fila de tarefas**.

**Problema 1: o e-mail no meio do caminho.** Até aqui, quando alguém se cadastrava, o Devise mandava o e-mail de confirmação **dentro do próprio pedido**: a página só respondia depois que o servidor de e-mail aceitasse a mensagem. Se o servidor de e-mail estivesse fora do ar, ou recusasse a senha, a pessoa via uma **página de erro 500**, mesmo com o cadastro já gravado no banco.

**Problema 2: o moderador precisa lembrar de olhar.** O contador do capítulo 0300 só aparece para quem abre o site. Se ninguém abrir, as fotos dos alunos ficam esperando.

Pense numa padaria. O atendente anota o pedido e entrega uma senha: ninguém espera no balcão o pão sair do forno. E o padeiro tem uma lista do que fazer todo dia às 6h, sem que ninguém precise pedir. A fila de tarefas é isso: o pedido de quem está no site termina na hora, e o trabalho mais demorado ou agendado acontece **depois**, nos fundos.

O projeto já tem essa fila desde o início: o **Solid Queue**, que vem com o Rails 8 e, na produção, roda dentro do próprio Puma. Ele já processava as variantes das fotos e a remoção dos arquivos apagados. Agora ele ganha mais dois trabalhos.

---

## Parte 2 — Os e-mails do Devise na fila

### 2.1 `deliver_later`

No `app/models/user.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  # Os e-mails do Devise saem pela fila (Solid Queue), e não no meio do pedido.
  # Se o servidor de e-mail falhar, o cadastro conclui do mesmo jeito.
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
```

O Devise chama esse método toda vez que vai mandar um e-mail: a confirmação do cadastro, a recuperação de senha, a troca de e-mail. Por padrão, ele usa `deliver_now`, que envia na hora. Ao sobrescrever o método no model, trocamos por **`deliver_later`**: o e-mail vira uma tarefa na fila, e o pedido da pessoa termina imediatamente.

| | `deliver_now` | `deliver_later` |
| --- | --- | --- |
| Quando o e-mail sai | Dentro do pedido | Logo depois, pela fila |
| Se o SMTP falhar | A página dá erro 500 | O cadastro conclui; a tarefa registra a falha |
| Tempo de resposta | Espera o servidor de e-mail | Imediato |

### 2.2 Tentar de novo

Uma falha de e-mail costuma ser passageira: o servidor demorou a responder, ou recusou a conexão por um instante. Em vez de desistir na primeira, a tarefa tenta de novo. Em `config/initializers/mail_delivery_job.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Falhas passageiras do servidor de e-mail: tenta de novo, com intervalos crescentes
Rails.application.config.after_initialize do
  ActionMailer::MailDeliveryJob.retry_on Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED,
                                         Net::SMTPServerBusy, Net::SMTPAuthenticationError,
                                         wait: :polynomially_longer, attempts: 5
end
```

- **`ActionMailer::MailDeliveryJob`** é a tarefa que o Rails usa para todo `deliver_later`, de qualquer mailer.
- **`retry_on`** lista os erros que valem uma nova tentativa. Um erro que não está na lista (um endereço de e-mail inválido, por exemplo) não adianta repetir.
- **`wait: :polynomially_longer`**: a primeira nova tentativa sai em poucos segundos, e as seguintes com intervalos cada vez maiores. É como ligar de novo para um número ocupado: um pouco depois, depois mais um pouco.
- **`attempts: 5`**: depois da quinta falha, a tarefa desiste e vai para a lista de falhas do Solid Queue, onde fica registrada.
- **`after_initialize`**: o bloco roda depois que o Rails carregou tudo, quando a classe `MailDeliveryJob` já existe.

O `Net::SMTPAuthenticationError` está na lista por um motivo prático: uma senha errada ou ainda não salva no painel do provedor de e-mail. Com as novas tentativas, o e-mail sai sozinho assim que o problema for corrigido.

---

## Parte 3 — O resumo diário

### 3.1 A conta por tipo

O resumo diz **quanto há de cada coisa**, e não só o total. No `app/models/moderacao/pendencias.rb`, do capítulo 0300:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
module Moderacao
  class Pendencias
    def self.por_tipo
      {
        fotos: Foto.pendente.count,
        academias: Academia.rascunhos.count,
        observacoes: Observacao.rascunhos.count
      }
    end

    def self.total = por_tipo.values.sum
  end
end
```

O `total` passou a ser a soma do `por_tipo`. A regra das três filas continua num lugar só: o contador do menu e o resumo por e-mail usam a mesma conta.

### 3.2 Quem recebe

No `app/models/user.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
  scope :que_moderam, -> { where(role: %i[admin moderador]) }
```

Um *scope* com nome em português, que se lê como uma frase: `User.que_moderam`.

### 3.3 O e-mail

`app/mailers/moderacao_mailer.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
class ModeracaoMailer < ApplicationMailer
  # O resumo diário para quem modera. A contagem vem pronta do job, igual para todos.
  def resumo_diario(user, contagem)
    @user = user
    @contagem = contagem
    @total = contagem.values.sum

    mail to: user.email,
         subject: "Território Inteligente: #{@total} #{@total == 1 ? 'item aguarda' : 'itens aguardam'} moderação"
  end
end
```

Um mailer é como um controller, só que a "página" que ele monta é um e-mail. As variáveis com `@` chegam à view do e-mail, como num controller.

A view em HTML, `app/views/moderacao_mailer/resumo_diario.html.erb`:

```erb
<%# 📖 JÁ ESTÁ NO PROJETO %>
<p>Olá, <%= @user.nome %>.</p>

<p>Há <strong><%= pluralize(@total, "item", plural: "itens") %></strong> aguardando moderação no Território Inteligente:</p>

<ul>
  <% if @contagem[:fotos].positive? %>
    <li><%= pluralize(@contagem[:fotos], "foto", plural: "fotos") %></li>
  <% end %>
  <% if @contagem[:academias].positive? %>
    <li><%= pluralize(@contagem[:academias], "academia em rascunho", plural: "academias em rascunho") %></li>
  <% end %>
  <% if @contagem[:observacoes].positive? %>
    <li><%= pluralize(@contagem[:observacoes], "observação em rascunho", plural: "observações em rascunho") %></li>
  <% end %>
</ul>

<p><%= link_to "Abrir a moderação", moderacao_url %></p>
```

E a mesma mensagem em **texto puro**, em `resumo_diario.text.erb`.

- **Duas versões do mesmo e-mail.** Alguns programas de e-mail só mostram texto, e filtros de spam desconfiam de e-mails só em HTML. Com os dois arquivos, o Rails monta um e-mail com as duas partes, e cada programa mostra a que sabe mostrar.
- **`plural:` explícito.** O `pluralize` usa as regras do inglês. Com "observação", ele erraria. Dizendo o plural, não há surpresa.
- **Só as filas com itens aparecem.** Com zero fotos, a linha das fotos nem é escrita.
- **`moderacao_url`, e não `moderacao_path`.** Num e-mail, o link precisa do **endereço completo**, com o domínio: quem lê o e-mail não está "dentro" do site. Em produção, o domínio vem da variável `APP_HOST`, pelo `default_url_options` configurado no deploy.

### 3.4 A tarefa

`app/jobs/resumo_moderacao_job.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
# Todo dia de manhã: se houver algo esperando decisão, avisa quem modera
class ResumoModeracaoJob < ApplicationJob
  queue_as :default

  def perform
    contagem = Moderacao::Pendencias.por_tipo
    return if contagem.values.sum.zero?

    User.que_moderam.find_each do |user|
      ModeracaoMailer.resumo_diario(user, contagem).deliver_later
    end
  end
end
```

- **Um job** é uma tarefa para a fila. O método `perform` é o que ela faz quando chega a vez dela.
- **`return if ... zero?`**: sem pendências, **nenhum e-mail sai**. Um e-mail diário dizendo "nada a fazer" ensina as pessoas a ignorar o remetente, e no dia em que houver algo importante, ninguém lê.
- **A conta é feita uma vez**, antes do laço, e vale para todos. Todos os e-mails do dia mostram o mesmo número.
- **Cada e-mail é uma tarefa própria** (`deliver_later` de novo). Se o envio para uma pessoa falhar, os outros não são afetados, e só aquele é tentado de novo.
- **`find_each`** busca os usuários em lotes. Com poucos moderadores não faz diferença, mas é o costume certo para percorrer uma tabela.

### 3.5 Todo dia, às 8h: `config/recurring.yml`

O Rails 8 já cria esse arquivo, com uma tarefa de limpeza do próprio Solid Queue. A nossa entrou no mesmo bloco:

```yaml
# 📖 JÁ ESTÁ NO PROJETO
production:
  clear_solid_queue_finished_jobs:
    # ...a tarefa de limpeza que já existia...
  resumo_moderacao:
    class: ResumoModeracaoJob
    schedule: "0 8 * * * America/Sao_Paulo"
```

O `schedule` é uma linha de **cron**, o formato clássico de agendamento do Linux. Os cinco campos, da esquerda para a direita:

| Campo | Valor | Quer dizer |
| --- | --- | --- |
| Minuto | `0` | No minuto zero |
| Hora | `8` | Das 8h |
| Dia do mês | `*` | Todo dia |
| Mês | `*` | Todo mês |
| Dia da semana | `*` | Qualquer dia da semana |

O **fuso horário** no fim (`America/Sao_Paulo`) é indispensável aqui: o servidor de produção está configurado no horário da Europa Central. Sem o fuso, o resumo sairia às 8h de lá, 4h da manhã no Brasil.

As tarefas recorrentes ficam no bloco **`production`**, e só rodam lá, onde o Solid Queue roda dentro do Puma (a variável `SOLID_QUEUE_IN_PUMA` do serviço, do deploy). No desenvolvimento, a tarefa é disparada à mão (Parte 5).

---

## Parte 4 — Os testes

### 4.1 O e-mail: `test/mailers/moderacao_mailer_test.rb`

```ruby
# 📖 JÁ ESTÁ NO PROJETO
require "test_helper"

class ModeracaoMailerTest < ActionMailer::TestCase
  test "resumo diário" do
    email = ModeracaoMailer.resumo_diario(users(:bia), { fotos: 2, academias: 1, observacoes: 0 })

    assert_equal [ users(:bia).email ], email.to
    assert_match "3 itens aguardam", email.subject
    assert_match "2 fotos", email.text_part.body.to_s
    assert_no_match "observaç", email.text_part.body.to_s
    assert_match "/moderacao", email.html_part.body.to_s
  end
end
```

- O teste monta o e-mail **sem enviar**, e confere o destinatário, o assunto e o conteúdo das duas partes.
- **`assert_no_match "observaç"`**: com zero observações, a linha delas não pode aparecer.

### 4.2 A tarefa: `test/jobs/resumo_moderacao_job_test.rb`

```ruby
# 📖 JÁ ESTÁ NO PROJETO
require "test_helper"

class ResumoModeracaoJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  test "avisa quem modera quando há pendências" do
    assert_enqueued_emails User.que_moderam.count do
      ResumoModeracaoJob.perform_now
    end
  end

  test "não manda nada quando não há pendências" do
    Academia.rascunhos.update_all(visivel: true)
    Observacao.rascunhos.update_all(visivel: true)
    Foto.pendente.update_all(situacao: :aprovada)

    assert_no_enqueued_emails do
      ResumoModeracaoJob.perform_now
    end
  end
end
```

- **`perform_now`** executa a tarefa na hora, dentro do teste, sem passar pela fila.
- **`assert_enqueued_emails`** confere quantos e-mails **foram para a fila**, sem enviar nada de verdade.
- O segundo teste **esvazia as três filas** com `update_all`, que grava direto no banco, e prova que a tarefa fica em silêncio.

> 💡 Cada tipo de teste mora na sua pasta: `test/models/`, `test/controllers/`, `test/mailers/`, `test/jobs/`. É a mesma organização do `app/`. Um teste de job na pasta dos mailers funciona, mas confunde quem procura por ele. E se o mesmo teste estiver nas duas pastas, ele roda duas vezes.

```bash
bin/rails test
bin/rails test:system
bin/rubocop
bin/brakeman --no-pager
```

---

## Parte 5 — Vendo o e-mail sem enviar: o preview

O Rails tem uma vitrine para os e-mails do projeto. Em `test/mailers/previews/moderacao_mailer_preview.rb`:

```ruby
# 📖 JÁ ESTÁ NO PROJETO
class ModeracaoMailerPreview < ActionMailer::Preview
  def resumo_diario
    ModeracaoMailer.resumo_diario(User.que_moderam.first, { fotos: 3, academias: 1, observacoes: 2 })
  end
end
```

Com o servidor de desenvolvimento rodando, abra:

```
http://localhost:3000/rails/mailers
```

O e-mail aparece **exatamente como vai chegar**, com um seletor para ver a versão em HTML e a versão em texto, sem enviar nada para ninguém. É o lugar certo para ajustar o texto e o visual de um e-mail.

E para disparar a tarefa de verdade, à mão:

```bash
bin/rails runner 'ResumoModeracaoJob.perform_now'
```

O log mostra cada e-mail indo para a fila. Os dados de exemplo têm uma academia em rascunho, então há pelo menos uma pendência.

---

## Parte 6 — Para quem administra o servidor

### 6.1 O agendamento foi carregado?

Quando o Puma sobe, o agendador do Solid Queue registra no log as tarefas recorrentes que encontrou:

```bash
sudo journalctl -u territorio-inteligente --since "5 min ago" --no-pager | grep -i scheduler
```

```
SolidQueue-1.7.0 Started Scheduler ... recurring_schedule: ["clear_solid_queue_finished_jobs", "resumo_moderacao"]
```

Se o `resumo_moderacao` não aparecer, a indentação do `recurring.yml` está errada, e a tarefa ficou fora do bloco `production`.

### 6.2 Testar sem esperar até as 8h

```bash
sudo -iu territorio_inteligente
cd app
RAILS_ENV=production mise exec -- bin/rails runner 'ResumoModeracaoJob.perform_now'
exit
```

Se houver pendências, cada moderador e admin recebe o resumo em alguns segundos. É um envio real: avise antes.

---

## Parte 7 — Testando

| Tente | O que deve acontecer |
| --- | --- |
| Abrir `/rails/mailers` e o resumo diário | O e-mail aparece, em HTML e em texto |
| Rodar o `ResumoModeracaoJob.perform_now` com uma academia em rascunho | Um e-mail para cada moderador e admin vai para a fila |
| Publicar tudo na moderação e rodar de novo | Nenhum e-mail |
| Cadastrar uma conta nova pelo formulário | A página responde na hora, e o e-mail de confirmação sai logo depois |

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Fila de tarefas** | Como a senha da padaria: o pedido termina na hora, e o trabalho demorado acontece depois, nos fundos. |
| **Job** | Uma tarefa para a fila. O método `perform` é o que ela faz. |
| **`deliver_later`** | Manda o e-mail pela fila, em vez de no meio do pedido. |
| **`retry_on`** | Lista os erros que fazem a tarefa tentar de novo. |
| **Tarefa recorrente** | Uma tarefa que a fila dispara sozinha, num horário marcado. |
| **Cron** | O formato de agendamento com cinco campos: minuto, hora, dia, mês e dia da semana. |
| **Fuso horário** | O relógio de um lugar. O servidor e as pessoas podem estar em fusos diferentes. |
| **Mailer** | O "controller" dos e-mails. |
| **E-mail em duas partes** | A mesma mensagem em HTML e em texto puro, no mesmo e-mail. |
| **`_url` e `_path`** | O endereço completo, com o domínio, e o endereço só com o caminho. Num e-mail, sempre `_url`. |
| **Preview de e-mail** | A vitrine em `/rails/mailers`, que mostra o e-mail sem enviar. |

---

## O que aprendemos

- O que é demorado ou pode falhar não fica no meio do pedido de quem está no site: vai para a fila.
- Uma falha passageira merece uma nova tentativa, com paciência crescente.
- Um aviso que só chega quando há algo a fazer continua sendo lido.
- Uma conta usada em vários lugares mora num lugar só: o contador e o e-mail mostram o mesmo número.
- O horário de uma tarefa agendada precisa dizer de qual fuso ele é.
- Um e-mail se testa como uma página: monta, confere o conteúdo, sem enviar.

**Próximo capítulo:** em breve.

---

## Fontes

- [Rails Guides — Active Job Basics](https://guides.rubyonrails.org/active_job_basics.html)
- [Rails Guides — Action Mailer Basics](https://guides.rubyonrails.org/action_mailer_basics.html)
- [Rails Guides — Action Mailer: Previewing Emails](https://guides.rubyonrails.org/action_mailer_basics.html#previewing-emails)
- [Rails API — `ActiveJob::Exceptions#retry_on`](https://api.rubyonrails.org/classes/ActiveJob/Exceptions/ClassMethods.html#method-i-retry_on)
- [Solid Queue — Recurring tasks](https://github.com/rails/solid_queue#recurring-tasks)
- [Devise — Activejob integration](https://github.com/heartcombo/devise#activejob-integration)
- [Fugit — cron com fuso horário](https://github.com/floraison/fugit)
