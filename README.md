# Marcia Bizi · Marmitas Fit

Sistema de controle de pedidos, dashboard e custos para a marmitaria da Márcia.
Site estático (HTML + CSS + JS puro, sem build) que usa o **Supabase** como banco de dados,
com sincronização em tempo real entre dispositivos.

## Como os dados são salvos

Os dados (pedidos, ingredientes, receitas) ficam salvos numa tabela no seu projeto Supabase.
Isso significa:

- **Sincronização em tempo real entre qualquer dispositivo** que abra o link do site —
  computador, celular, quantos navegadores forem, todos veem os mesmos dados, atualizando
  sozinhos.
- Sem login para quem acessa o site — a conexão com o banco usa uma chave pública (anon key)
  embutida no próprio código, então qualquer pessoa com o link já usa o app normalmente.
- **Atenção de segurança**: como não há autenticação de usuário, qualquer pessoa que tiver o
  link do site (e souber olhar o código-fonte da página) técnicamente consegue ler e escrever
  nos dados. Para um controle interno de uma marmitaria pequena isso costuma ser um risco
  aceitável, mas não é um app com "contas de usuário" — é um quadro compartilhado, tipo um
  Google Sheets aberto por link. Se um dia isso virar um problema, dá para adicionar
  autenticação real do Supabase (fora do escopo deste projeto).

## Passo 1 — Criar o projeto no Supabase

1. Crie uma conta gratuita em [supabase.com](https://supabase.com).
2. Clique em **New Project**, escolha um nome e uma senha de banco (guarde essa senha, mas
   ela não é usada neste app), e aguarde o projeto ser criado (leva ~2 minutos).
3. No menu lateral, vá em **SQL Editor** → **New query** e cole o SQL abaixo, depois clique
   em **Run**:

   ```sql
   create table app_data (
     key text primary key,
     value jsonb not null,
     updated_at timestamptz default now()
   );

   alter table app_data enable row level security;

   create policy "permitir tudo (app interno sem login)"
     on app_data for all
     using (true)
     with check (true);

   -- necessário para a sincronização em tempo real funcionar
   alter publication supabase_realtime add table app_data;
   ```

4. Vá em **Project Settings → API**. Você vai precisar de dois valores dessa página:
   - **Project URL** (algo como `https://xxxxxxxxxxxx.supabase.co`)
   - **anon public key** (uma chave longa, começando geralmente com `eyJ...`)

## Passo 2 — Conectar o site ao seu projeto

Abra o arquivo `index.html` deste projeto, procure por estas duas linhas perto do início do
`<script>` (use Ctrl+F / Cmd+F):

```js
const SUPABASE_URL = "SUA_SUPABASE_URL_AQUI";
const SUPABASE_ANON_KEY = "SUA_SUPABASE_ANON_KEY_AQUI";
```

Substitua pelos valores que você copiou no passo anterior:

```js
const SUPABASE_URL = "https://xxxxxxxxxxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJ....................";
```

Salve o arquivo. Se abrir sem preencher essas duas linhas, o site mostra uma tela avisando
que a configuração está pendente, em vez de quebrar.

## Passo 3 — Colocar no ar (GitHub + Vercel)

### Criar o repositório no GitHub

1. Crie uma conta no [github.com](https://github.com) se ainda não tiver.
2. Clique em **New repository**, dê um nome (ex: `marmitas-marcia-bizi`) e clique em
   **Create repository**.
3. No seu computador, dentro desta pasta (já com as chaves do Supabase preenchidas no
   `index.html`), rode:

   ```bash
   git init
   git add .
   git commit -m "Primeira versão do sistema de pedidos"
   git branch -M main
   git remote add origin https://github.com/SEU-USUARIO/marmitas-marcia-bizi.git
   git push -u origin main
   ```

### Publicar na Vercel

1. Crie uma conta em [vercel.com](https://vercel.com) (dá para entrar direto com GitHub).
2. Clique em **Add New… → Project** e selecione o repositório que você acabou de criar.
3. A Vercel detecta automaticamente que é um site estático — não precisa mudar nenhuma
   configuração. Clique em **Deploy**.
4. Em menos de um minuto você recebe um link definitivo, tipo
   `https://marmitas-marcia-bizi.vercel.app`.

Qualquer atualização que você fizer no `index.html` e enviar (`git push`) é publicada
automaticamente pela Vercel em segundos.

## Backup

Mesmo com o Supabase, o site tem dois botões no topo (ícones de download/upload) para
exportar todos os dados num arquivo `.json` e importar de volta — útil como cópia de
segurança extra ou para migrar os dados para outro projeto Supabase no futuro.

## Estrutura do projeto

```
.
├── index.html   ← todo o site (HTML + CSS + JS em um único arquivo)
└── README.md    ← este arquivo
```

## Editando o conteúdo

- **Cardápio e receitas**: procure por `CARDAPIO`, `VARIACOES_MARMITAS` e `RECEITAS_SEED`
  no `index.html` — são os dados iniciais dos pratos e receitas (usados apenas na primeira
  vez, antes de existir nada salvo no Supabase).
- **Preços de ingredientes**: `INGREDIENTES_SEED`, no mesmo arquivo.
- **Cores e fontes**: variáveis CSS no topo do `<style>` (`--bg`, `--primary`, `--accent`,
  `--font-display`, etc.).

