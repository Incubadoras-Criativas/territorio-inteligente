# Como contribuir com o Território Inteligente

Obrigado por ajudar! Este guia mostra o caminho para a contribuição mais comum: **escrever o guia de um equipamento** das academias ao ar livre.

Para entender como o projeto foi construído, leia a [documentação](docs/), capítulo por capítulo.

---

## Antes de começar

- O seu ambiente de desenvolvimento precisa estar funcionando (veja os [tutoriais de iniciação](https://github.com/Incubadoras-Criativas/tutoriais)).
- Pegue uma **issue** na aba *Issues* do GitHub. Cada issue é um equipamento. Comente "vou fazer" nela, para ninguém pegar a mesma.

---

## O caminho de uma contribuição

### 1. Atualize o projeto e crie a sua branch

```bash
cd ~/projetos/territorio-inteligente
git switch main
git pull
bin/rails db:migrate
git switch -c guia/<slug-do-equipamento>
```

O **slug** é o fim do endereço da página do equipamento. Para "Leg press", é `leg-press`; a branch fica `guia/leg-press`.

### 2. Crie o arquivo do guia a partir do modelo

```bash
cp conteudo/equipamentos/_MODELO.html conteudo/equipamentos/<slug>.html
```

O nome do arquivo precisa ser **exatamente** o slug, com `.html` no fim.

### 3. Escreva, vendo o resultado no navegador

```bash
bin/dev
```

1. Entre como administrador de desenvolvimento: `admin@territorio.local`, senha `troque-esta-senha`. Só funciona no seu computador.
2. Abra `http://localhost:3000/equipamentos/<slug>`.
3. Escreva no arquivo e **recarregue a página**. Não precisa reiniciar o servidor.

O equipamento aparece com a faixa amarela de **rascunho**. Está certo: ele só fica público depois da revisão do conteúdo.

### 4. Confira antes de enviar

- [ ] O arquivo está em `conteudo/equipamentos/<slug>.html`
- [ ] Usei só HTML simples: títulos, parágrafos, listas, negrito e tabelas
- [ ] **Não** usei `<script>`, `<style>` nem `<iframe>`
- [ ] Preenchi todas as seções do modelo e apaguei os textos entre colchetes
- [ ] O texto foi escrito por mim ou pela minha dupla. Se usei outra fonte, ela está citada no fim
- [ ] A página fica boa no modo celular do navegador (F12, Ctrl+Shift+M, 320 px)

```bash
bin/rails test
```

### 5. Envie o Pull Request

```bash
git add conteudo/equipamentos/<slug>.html
git commit -m "Guia do equipamento: <nome do equipamento>"
git push -u origin guia/<slug>
```

No GitHub, abra o Pull Request. Na descrição, escreva `Closes #<número da issue>`: assim, a issue fecha sozinha quando o PR entrar.

### 6. A revisão

O educador revisa o PR. Se ele pedir mudanças, faça na **mesma branch**, com um commit novo, e envie com `git push`. O PR se atualiza sozinho.

Depois do merge, o guia ainda passa pela **revisão de conteúdo** da fisioterapeuta da equipe, porque é orientação de exercício num projeto de saúde. Só então ele é publicado.

---

## E as fotos?

As fotos **não** vão no Pull Request. Elas são enviadas pelo formulário de administração do site, por um administrador.

- Fotografe o **equipamento vazio**, sem pessoas. Rosto é dado pessoal, protegido pela LGPD.
- Mande as fotos ao educador, com o nome do equipamento.
- Foto de celular serve: o site reduz o tamanho sozinho.

---

## Licença

Ao contribuir, você concorda que:
- o **código** que enviar fica sob a licença [AGPL-3.0](LICENSE);
- os **textos** e as **imagens** ficam sob a licença [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/deed.pt-br): qualquer pessoa pode reutilizar, desde que dê o crédito e compartilhe pela mesma licença.
