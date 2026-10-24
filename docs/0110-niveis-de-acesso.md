# 0110 — Níveis de acesso: administrador, moderador e comum

> **Neste capítulo:** cada usuário ganha um **nível de acesso**. Vamos ver como o Rails guarda isso no banco com um **enum**, por que a escolha do valor padrão é uma questão de **segurança**, e conhecer o **console do Rails**, onde dá para conversar com o projeto ao vivo.

**Tag deste capítulo:** `cap-0110`

---

## Para ter o código deste capítulo na sua máquina

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails db:migrate
```

---

## Parte 1 — Quem pode o quê

O Território Inteligente vai receber informações de moradores sobre as academias ao ar livre. Nem todo mundo pode fazer tudo:

| Nível | Número no banco | Pode |
| --- | --- | --- |
| **Administrador** | `0` | Tudo, inclusive mudar o nível de outras pessoas |
| **Moderador** | `1` | Revisar e aprovar o que os moradores enviam |
| **Comum** | `2` | Enviar fichas, fotos e relatos |

Quem se cadastra **sempre** começa como comum. Só um administrador pode promover alguém.

---

## Parte 2 — A migration

```bash
bin/rails generate migration AddRoleToUsers
```

O nome `AddRoleToUsers` segue uma convenção: *"adicione role à tabela users"*. No arquivo gerado em `db/migrate/`, escrevemos:

```ruby
def change
  add_column :users, :role, :integer, null: false, default: 2
end
```

| Trecho | O que faz |
| --- | --- |
| `add_column :users, :role` | Cria a coluna `role` na tabela `users` |
| `:integer` | Guarda um número inteiro |
| `null: false` | A coluna **nunca** pode ficar vazia |
| `default: 2` | Se ninguém disser nada, o valor é `2`: **comum** |

```bash
bin/rails db:migrate
```

### Por que o valor padrão é uma questão de segurança?

Repare: o número `0` é o **administrador**. Imagine que alguém esquecesse o `default: 2`. Muita gente, por reflexo, coloca `default: 0` em colunas de número. Resultado: **todo mundo que se cadastrasse viraria administrador**.

Por isso, nesta migration, as duas proteções andam juntas:

- `default: 2` garante que o valor padrão é o **nível mais fraco**;
- `null: false` impede que o campo fique vazio, o que deixaria o sistema sem saber o que a pessoa pode fazer.

> 💡 **Manha: o padrão deve ser sempre o menor poder.**
> Em segurança, isso se chama **privilégio mínimo**: se algo der errado ou alguém esquecer um detalhe, o sistema deve errar **para o lado mais seguro**. Um usuário comum que deveria ser moderador é um incômodo. Um usuário comum que virou administrador é um desastre.

Os usuários que já existiam no banco ganharam o valor `2` automaticamente, por causa do `default`. Confira no pgAdmin:

```sql
SELECT email, role FROM users;
```

---

## Parte 3 — O enum: dando nome aos números

Para o banco, `role` é só um número. Para nós, programando, ler `if user.role == 0` não diz nada. O **enum** dá nome a cada número. Em `app/models/user.rb`, abaixo da linha do `devise`:

```ruby
enum :role, { admin: 0, moderador: 1, comum: 2 }, default: :comum, validate: true
```

| Trecho | O que faz |
| --- | --- |
| `enum :role` | A coluna `role` vai ter nomes em vez de números |
| `{ admin: 0, moderador: 1, comum: 2 }` | A tabela de tradução: nome → número |
| `default: :comum` | O model também sabe que o padrão é comum (a migration já dizia isso ao banco) |
| `validate: true` | Se alguém tentar guardar um nível que não existe, o Rails recusa com uma mensagem de erro, em vez de quebrar |

### O que o enum dá de presente

Com uma única linha, o Rails cria vários métodos:

| Método | O que faz | Exemplo |
| --- | --- | --- |
| `user.admin?` | Pergunta: é administrador? | `true` ou `false` |
| `user.comum?` | Pergunta: é comum? | `true` ou `false` |
| `user.moderador!` | Muda para moderador **e salva** | |
| `user.role` | O nome do nível | `"comum"` |
| `User.admin` | Todos os administradores | uma lista |
| `User.moderador.count` | Quantos moderadores existem | um número |

Repare nos `?` do capítulo 0100: métodos que respondem sim ou não. E no `!`: em Ruby, ele avisa que o método **faz algo forte**. Aqui, salva no banco na hora.

Na Parte 4 você vai testar esses métodos com as próprias mãos, no exercício do final.

---

## Parte 4 — Conversando com o projeto: o console

O **console do Rails** é um terminal onde você escreve Ruby e conversa ao vivo com o projeto e com o banco.

### Antes de abrir o console: tenha uma conta

O seu banco de desenvolvimento é **só seu**. Pode fazer nele os testes que quiser: cadastrar contas, apagar, promover, rebaixar. A única regra é **não alterar nada pelo pgAdmin**. Lá, use só consultas `SELECT`, para olhar. Mudar tabelas ou dados por fora do Rails pode deixar o seu banco diferente do que o projeto espera, e aí o sistema para de funcionar na sua máquina.

Se você ainda não tem uma conta no seu `localhost`, crie agora:

1. Ligue o servidor com `bin/dev` e acesse **http://localhost:3000**.
2. Clique em **Cadastrar** e preencha com o seu e-mail.
3. Abra **http://localhost:3000/letter_opener** e clique no link de confirmação.
4. Desligue o servidor (Ctrl+C) ou abra **outro terminal** na pasta do projeto.

### Abrindo o console

```bash
bin/rails console
```

Ou o atalho, que faz a mesma coisa:

```bash
bin/rails c
```

O terminal muda para algo como `territorio-inteligente(dev)>`. Experimente, uma linha de cada vez:

```ruby
User.count
```

Quantos usuários existem no banco.

```ruby
u = User.first
u.role
u.comum?
u.admin?
```

O primeiro usuário, o nível dele e as duas perguntas.

```ruby
User.comum.count
User.admin.count
```

Quantos de cada nível. Deve dar zero administradores: ninguém foi promovido ainda.

```ruby
u.role = "chefe"
u.valid?
u.errors.full_messages
```

Tentamos um nível que não existe. O `validate: true` faz o Rails recusar: `valid?` responde `false`, e `errors.full_messages` mostra o motivo. Nada foi salvo.

```ruby
u.reload
u.role
```

O `reload` busca de novo no banco: o nível voltou a ser `"comum"`.

Para sair do console:

```ruby
exit
```

> ⚠️ **Cuidado:** o console mexe no banco de verdade. Um `u.admin!` ali **promove** o usuário de fato. No seu banco de desenvolvimento, tudo bem. Num servidor de produção, o console exige o mesmo cuidado que o `sudo`.

### 🏋️ Exercício: suba e desça de nível

Deixe o **pgAdmin** aberto ao lado do terminal (capítulo 035). Você vai mudar o seu próprio nível pelo console e ver o número mudar no banco.

**1.** No console, encontre a **sua** conta (troque pelo seu e-mail):

```ruby
eu = User.find_by(email: "seu-email@exemplo.com")
```

**2.** Faça as perguntas:

```ruby
eu.role
eu.comum?
eu.admin?
```

**3.** Vire moderador:

```ruby
eu.moderador!
eu.role
eu.moderador?
```

**4.** No pgAdmin, rode esta consulta e anote o número que aparece na coluna `role`:

```sql
SELECT email, role FROM users;
```

**5.** Agora vire administrador e consulte de novo no pgAdmin:

```ruby
eu.admin!
User.admin.count
```

**6.** Volte a ser comum (aqui não tem favoritismo!) e confira mais uma vez:

```ruby
eu.comum!
User.admin.count
```

**Complete a tabela** com o que você viu:

| Depois do comando | `eu.role` no console | `role` no pgAdmin |
| --- | --- | --- |
| `eu.moderador!` | | |
| `eu.admin!` | | |
| `eu.comum!` | | |

**Para pensar:**

1. Por que o console mostra uma **palavra** e o pgAdmin mostra um **número**, se os dois estão olhando para a mesma coluna?
2. O que aconteceria se a migration tivesse `default: 0` em vez de `default: 2`? Quem se cadastrasse amanhã viraria o quê?
3. Você acabou de virar administrador sozinho. Por que isso não é uma falha de segurança? (Dica: **onde** você estava quando fez isso?)

---

## Parte 5 — Quem muda o nível de alguém?

Este é o ponto mais importante do capítulo: **ninguém escolhe o próprio nível.**

O formulário de cadastro manda para o servidor os campos `email`, `password` e `password_confirmation`. Mas um formulário é só HTML, e qualquer pessoa com um pouco de conhecimento consegue enviar campos extras, por exemplo:

```
user[role]=admin
```

Se o Rails aceitasse qualquer campo que chega, essa pessoa viraria administradora. Esse ataque se chama **atribuição em massa** (*mass assignment*).

O Rails se protege com os **strong parameters**: cada formulário tem uma **lista de campos permitidos**, e tudo que não está na lista é descartado. No capítulo 0120, vamos liberar os campos `nome` e `login` no Devise. O `role` **nunca** vai entrar nessa lista.

> 🕵️ **Pensamento hacker:** nunca confie no que vem do navegador. Tudo que chega numa requisição pode ter sido alterado por quem enviou. A segurança mora no **servidor**, não no formulário.

Então como alguém vira administrador? O **primeiro** administrador nasce pelo arquivo `db/seeds.rb`, no capítulo 0120. Depois, uma tela só para administradores vai permitir promover moderadores. Essa tela fica para um capítulo futuro.

---

## Parte 6 — Os nomes em português

No banco, os níveis estão em número; no código, em nomes curtos (`admin`, `moderador`, `comum`). Para mostrar na tela, temos a tradução em `config/locales/pt-BR.yml`:

```yaml
pt-BR:
  user:
    roles:
      admin: "Administrador"
      moderador: "Moderador"
      comum: "Comum"
```

E, numa view:

```erb
<%= t("user.roles.#{current_user.role}") %>
```

O `t` é a função de tradução do Rails. Se `current_user.role` for `"comum"`, ela busca `user.roles.comum` e mostra **"Comum"**.

---

## Palavras novas deste capítulo

| Palavra | O que significa |
| --- | --- |
| **Enum** | Uma coluna que guarda números, mas que no código usamos por nomes. |
| **Valor padrão** (*default*) | O valor que a coluna recebe quando ninguém diz qual é. |
| **Privilégio mínimo** | Regra de segurança: dar a cada um só o poder de que precisa, e errar sempre para o lado mais seguro. |
| **Console do Rails** | Um terminal para conversar ao vivo com o projeto em Ruby. |
| **Atribuição em massa** | Ataque em que alguém envia campos extras num formulário para mudar o que não devia. |
| **Strong parameters** | A lista de campos que cada formulário pode alterar. O resto é descartado. |

---

## O que aprendemos

- Um **enum** dá nomes aos números guardados no banco e cria métodos como `admin?` e `User.comum`.
- O valor padrão de um nível de acesso deve ser **o menor poder**.
- `null: false` impede que um campo importante fique vazio.
- O **console** permite testar o projeto ao vivo, mas mexe no banco de verdade.
- Nunca confie no que vem do navegador: o `role` nunca entra na lista de campos permitidos.

**Próximo capítulo:** [0120 — Perfil: nome e identificador](0120-perfil-nome-e-login.md)
