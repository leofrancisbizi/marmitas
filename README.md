# Marcia Bizi · Marmitas Fit

Sistema de controle de pedidos, dashboard e custos para a marmitaria da Márcia.

Site estático (HTML + CSS + JS puro, **sem build, sem npm, sem framework**) que usa o
**Supabase** como banco de dados e como login, com sincronização em tempo real entre
dispositivos.

```
.
├── index.html            ← o site inteiro (HTML + CSS + JS)
├── config.js             ← as 2 chaves do seu projeto Supabase (você preenche)
├── supabase/schema.sql   ← o SQL do banco (você roda uma vez)
└── README.md             ← este arquivo
```

## Como funciona a segurança

O site é público na internet, mas **os dados não**:

- **Ninguém entra sem login.** A tela inicial pede e-mail e senha. Sem sessão válida o
  app nem chega a montar a tela.
- **Ninguém se cadastra sozinho.** O *Email signup* fica **desligado** no painel
  (Passo 4). Essa é a trava que importa: ela é aplicada pelo servidor do Supabase, então
  vale mesmo para quem chame a API direto, sem passar pelo site. Contas só existem se
  você criar na mão.
- **O banco recusa quem não está logado.** As policies de RLS em `supabase/schema.sql`
  liberam leitura e escrita apenas para a role `authenticated`. Mesmo que alguém copie a
  chave que está no `config.js` (ela é pública por natureza), sem uma sessão válida o
  Postgres devolve vazio. Apagar linhas ninguém pode — não existe policy de DELETE.

Isso é o suficiente para um controle interno. Não é um sistema com perfis, permissões
diferentes por usuário ou auditoria — todo mundo que entra vê e edita tudo.

---

## Passo 1 — Criar o projeto no Supabase

> A sua organização atual (Nitro) está no plano Pro, onde cada projeto novo custa
> US$ 10/mês. Por isso o certo aqui é criar uma **organização nova**, no plano Free,
> só para a marmitaria — assim fica de graça e separado.

1. Acesse [supabase.com/dashboard](https://supabase.com/dashboard).
2. No seletor de organização (canto superior esquerdo) → **New organization**.
   - Nome: `Marmitas` · Plano: **Free**.
3. Dentro dela, clique em **New project**.
   - Nome: `marmitas` · Region: **South America (São Paulo)** · gere uma senha de banco
     e guarde (o app não usa, mas o Supabase pede).
4. Espere uns 2 minutos até o projeto ficar verde (*Healthy*).

## Passo 2 — Criar as tabelas

No projeto novo: **SQL Editor → New query** → cole o conteúdo inteiro de
`supabase/schema.sql` → **Run**.

Pode rodar de novo quantas vezes quiser, não quebra nada.

## Passo 3 — Preencher o `config.js`

No painel: **Project Settings → API Keys**. Copie dois valores:

| No painel | No `config.js` |
| --- | --- |
| **Project URL** (`https://xxxx.supabase.co`) | `SUPABASE_URL` |
| **Publishable key** (`sb_publishable_...`) — ou a **anon** legada (`eyJ...`) | `SUPABASE_KEY` |

```js
window.MARMITAS_CONFIG = {
  SUPABASE_URL: "https://xxxxxxxxxxxx.supabase.co",
  SUPABASE_KEY: "sb_publishable_...",
};
```

⚠️ **Nunca** cole aqui a chave `service_role` / `secret`. Essa sim daria acesso total ao
banco ignorando o RLS. As duas de cima são feitas para ficar no navegador.

Se abrir o site sem preencher, ele mostra uma tela avisando em vez de quebrar.

## Passo 4 — Travar o cadastro e criar o acesso da Márcia

1. **Authentication → Sign In / Providers → Email**: deixe **Enable email provider**
   ligado e **desligue** *Allow new users to sign up*.

   Na mesma tela, deixe **Allow anonymous sign-ins** desligado. Sessão anônima também
   recebe o papel `authenticated` — ligar isso reabriria tudo, mesmo com o cadastro
   fechado.

   > ⚠️ **Este é o passo mais importante do README.** Enquanto ele estiver ligado,
   > qualquer pessoa que conheça a URL do projeto consegue criar uma conta chamando a
   > API do Supabase direto — e uma conta criada assim passa pelo RLS e vê todos os
   > dados. O bloqueio que está no código do site protege só a tela, não a API.
   > Para conferir se está fechado, rode `./verificar-seguranca.sh`.
2. **Authentication → Users → Add user → Create new user**: preencha o e-mail e uma
   senha, e **marque a caixa `Auto Confirm User`**. Repita para o seu próprio e-mail.

   > A caixa de confirmação automática é obrigatória. Sem ela o Supabase espera uma
   > confirmação por e-mail que nunca vai chegar — este projeto não tem servidor de
   > e-mail configurado — e o login falha com "Email not confirmed".

3. Passe a senha para a Márcia por um canal privado (WhatsApp, pessoalmente) e peça para
   ela trocar com você depois, se quiser. Não existe "esqueci minha senha" no app: para
   redefinir, você entra em **Authentication → Users**, clica nos três pontinhos do
   usuário e escolhe **Reset password** (ou apaga e recria com senha nova).

Pronto: só esses dois e-mails entram.

## Passo 5 — Colocar no ar (GitHub + Vercel)

O repositório já existe (`github.com/leofrancisbizi/marmitas`). Com o `config.js`
preenchido:

```bash
git add .
git commit -m "Login por e-mail e RLS no Supabase"
git push
```

Na [vercel.com](https://vercel.com), entrando com o GitHub: **Add New… → Project** →
selecione o repositório → **Deploy**. A Vercel reconhece que é site estático sozinha, não
precisa configurar nada. Em menos de um minuto sai o link
(`https://marmitas.vercel.app` ou parecido).

Daí em diante, todo `git push` publica sozinho em segundos.

---

## Uso no dia a dia

- **Cardápio** — os combos e preços vigentes.
- **Pedidos** — cadastrar, editar e excluir pedidos; exportar CSV.
- **Dashboard** — faturamento, lucro, clientes recorrentes e pratos mais pedidos por
  semana/mês/ano.
- **Custos** — preço dos ingredientes e receita (gramas por marmita) de cada variação,
  com o custo e a margem calculados.

Os botões no topo, da esquerda para a direita: sincronizar agora, baixar backup `.json`,
restaurar backup, **sair**.

Vários dispositivos podem ficar abertos ao mesmo tempo — o que um salva aparece no outro
sozinho, sem recarregar a página.

## Backup

Os dois botões de download/upload no topo exportam e importam **todos** os dados num
arquivo `.json`. Vale como cópia de segurança e como forma de migrar para outro projeto
Supabase no futuro. Importar **substitui** tudo o que está no banco.

## Editando o conteúdo

Tudo no `index.html`:

- **Cardápio e receitas**: `CARDAPIO`, `VARIACOES_MARMITAS`, `RECEITAS_SEED`.
- **Preços de ingredientes**: `INGREDIENTES_SEED`.
- **Preços dos combos / frete**: `DEFAULT_CONFIG`.
- **Cores e fontes**: as variáveis CSS no topo do `<style>` (`--bg`, `--primary`, …).

Atenção: os `*_SEED` só valem na **primeira** abertura, quando o banco ainda está vazio.
Depois disso, quem manda são os dados salvos no Supabase — ingredientes e receitas se
editam pela própria aba **Custos** do site.

## Problemas comuns

| Sintoma | Causa provável |
| --- | --- |
| "E-mail ou senha incorretos" | Senha errada, ou o usuário não existe em Authentication → Users. |
| "Este e-mail ainda não foi confirmado" | O usuário foi criado sem marcar `Auto Confirm User` (Passo 4). Confirme na mão pelo painel. |
| "Muitas tentativas seguidas" | Proteção do Supabase contra força bruta. Espere um minuto. |
| Tela "Configuração do Supabase pendente" | `config.js` em branco ou com valor errado. |
| Entra, mas não aparece nenhum pedido | O `schema.sql` não foi rodado nesse projeto. |

## Conferindo a segurança

```bash
./verificar-seguranca.sh
```

Lê as chaves do `config.js` e testa o projeto de fora, como um visitante não logado:
se a tabela existe, se dá para ler dados sem login, se dá para escrever, e se o cadastro
público está fechado. Vale rodar depois de qualquer mudança no painel do Supabase.
