# Manutenção — Atualizar o Ruby

> **Quando usar este guia:** sempre que o arquivo `.ruby-version` do projeto mudar. Isso acontece quando sai uma versão do Ruby com **correção de segurança**, e o verificador de segurança do projeto (o Brakeman, no CI) passa a recusar a versão antiga.
>
> **Atualização atual:** do Ruby **4.0.7** para o **4.0.10**. A versão 4.0.7 tem falhas graves no motor de expressões regulares do Ruby, que podem permitir que alguém execute código no computador que roda a aplicação.

---

## Por que isso é obrigatório

Pense na fechadura da porta de casa. Se o fabricante descobre que uma chave mestra abre todas as fechaduras daquele modelo, ele lança uma fechadura nova. Não adianta trocar só a da porta da frente: a dos fundos também precisa ser trocada.

Com o Ruby é igual. A versão nova precisa chegar a **todos os lugares** onde o projeto roda: o servidor de produção, o CI do GitHub e **a sua máquina**. Sem a atualização, a sua máquina também deixa de conseguir rodar o projeto, porque o `Gemfile` exige a versão do `.ruby-version`.

---

## Antes de começar

Se você tem trabalho em andamento numa branch, **faça o commit** antes. Confira com:

```bash
cd ~/projetos/territorio-inteligente
git status
```

O resultado precisa ser *"nothing to commit, working tree clean"*. Se não for, faça o commit na sua branch (ou peça ajuda ao educador).

---

## Passo a passo

### 1. Traga o projeto atualizado

```bash
git switch main
git pull
cat .ruby-version
```

O `cat` mostra a versão que o projeto agora exige: **4.0.10**.

### 2. Instale o Ruby novo

```bash
mise install ruby@4.0.10
```

⏳ **Este passo demora alguns minutos.** O mise baixa o código-fonte do Ruby e o **compila** na sua máquina. Aparecem muitas linhas no terminal, e é normal. Não feche o terminal. Espere voltar o *prompt* (`aluno@maquina:~/projetos/territorio-inteligente$`).

### 3. Passe a usar o Ruby novo

```bash
mise use -g ruby@4.0.10
ruby -v
```

O `-g` (de *global*) faz o Ruby novo valer para todos os seus projetos. O `ruby -v` precisa mostrar **4.0.10**. Se ainda mostrar 4.0.7, feche o terminal, abra outro e repita o `ruby -v`.

### 4. Prepare o projeto

```bash
bundle install
bin/rails db:migrate
bin/rails test
```

- O **`bundle install`** confere as gems com o Ruby novo. Como 4.0.7 e 4.0.10 são versões da mesma família, as gems que você já tinha continuam valendo, e ele termina rápido.
- O **`db:migrate`** aplica as migrations que chegaram com o `git pull`.
- Os **testes** precisam passar. Se algum falhar, chame o educador antes de seguir.

### 5. Suba o servidor

```bash
bin/dev
```

Abra `http://localhost:3000`. Se o site abrir, a atualização deu certo. 🎉

---

## Se você trabalha também na VPS dos alunos

As contas de aluno na VPS são uma máquina diferente da do laboratório. Repita os passos 1 a 4 lá também, depois de entrar com:

```bash
ssh seu_usuario@endereco-da-vps
```

---

## Problemas comuns

| O que aparece | O que fazer |
| --- | --- |
| `Your Ruby version is 4.0.7, but your Gemfile specified 4.0.10` | O passo 3 não pegou. Rode `mise use -g ruby@4.0.10` de novo, feche e abra o terminal, e confira com `ruby -v` |
| `mise: command not found` | O terminal não carregou o mise. Feche e abra o terminal. Se continuar, chame o educador |
| A instalação para com um erro de compilação (`BUILD FAILED`) | Copie as **últimas 20 linhas** do erro e mande ao educador. Normalmente falta alguma biblioteca do sistema |
| `error: Your local changes would be overwritten` no `git pull` | Você tem trabalho sem commit. Volte ao "Antes de começar" |

---

## Depois que tudo funcionar (opcional)

A versão antiga continua instalada, ocupando espaço. Para removê-la:

```bash
mise uninstall ruby@4.0.7
```

---

## Para quem cuida do projeto

Quando sair uma correção de segurança do Ruby:

1. Atualize o Ruby na sua máquina (passos 2 e 3), mude o `.ruby-version`, rode `bundle install` e os testes, e faça o commit do `.ruby-version` e do `Gemfile.lock`.
2. O CI do GitHub lê o `.ruby-version` e passa a usar a versão nova sozinho.
3. **Na VPS de produção, instale o Ruby novo antes do `git pull`**:
   ```bash
   sudo -iu territorio_inteligente
   mise install ruby@NOVA
   mise use -g ruby@NOVA
   cd app
   git pull
   RAILS_ENV=production mise exec -- bundle install
   RAILS_ENV=production mise exec -- bin/rails assets:precompile
   exit
   sudo systemctl restart territorio-inteligente
   ```
   Se o código chegar antes do Ruby, o `bundle install` recusa a versão. Enquanto o Ruby compila, o site continua no ar com o Puma antigo: ele só troca de versão no `restart`.
4. Avise a turma, e use este guia na aula seguinte, antes de qualquer outra tarefa.
