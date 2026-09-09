#!/usr/bin/env bash
# Testa o projeto Supabase de fora, como um visitante NÃO logado.
# Uso: ./verificar-seguranca.sh
set -u

cd "$(dirname "$0")"
U=$(grep -o 'SUPABASE_URL: *"[^"]*"' config.js | sed 's/.*"\(.*\)"/\1/')
K=$(grep -o 'SUPABASE_KEY: *"[^"]*"' config.js | sed 's/.*"\(.*\)"/\1/')

if [[ "$U" != http* || ${#K} -lt 20 ]]; then
  echo "config.js ainda não está preenchido."; exit 1
fi
echo "Projeto: $U"; echo

falhas=0
ok(){   printf '  \033[32mOK\033[0m   %s\n' "$1"; }
erro(){ printf '  \033[31mFALHA\033[0m %s\n' "$1"; falhas=$((falhas+1)); }

# 1) a tabela existe?
r=$(curl -s "$U/rest/v1/app_data?select=key&limit=1" -H "apikey: $K" --max-time 20)
echo "1. Tabela app_data"
if [[ "$r" == *"PGRST205"* || "$r" == *"does not exist"* ]]; then
  erro "não existe — rode supabase/schema.sql no SQL Editor"
else
  ok "existe"
fi

# 2) leitura sem login (deve vir vazio)
echo "2. Leitura sem login"
if [[ "$r" == "[]" ]]; then
  ok "bloqueada (nada retornado)"
  echo "         obs: só é prova definitiva depois que houver dados salvos —"
  echo "         com a tabela vazia o resultado seria [] de qualquer jeito."
elif [[ "$r" == \[* ]]; then
  erro "VAZOU DADOS -> $r"
fi

# 3) escrita sem login (deve ser recusada)
echo "3. Escrita sem login"
w=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$U/rest/v1/app_data" \
     -H "apikey: $K" -H "Content-Type: application/json" \
     -d '{"key":"__teste_seguranca","value":{}}' --max-time 20)
if [[ "$w" == "401" || "$w" == "403" ]]; then ok "recusada (HTTP $w)"
else erro "PERMITIDA (HTTP $w) — confira as policies do schema.sql"; fi

# 4) cadastro público (a trava principal)
echo "4. Cadastro público de contas"
s=$(curl -s "$U/auth/v1/settings" -H "apikey: $K" --max-time 20)
if [[ "$s" == *'"disable_signup":true'* ]]; then
  ok "desligado"
else
  erro "LIGADO — qualquer um cria conta pela API e passa pelo RLS."
  echo "         Painel: Authentication -> Sign In / Providers -> Email"
  echo "         -> desligue 'Enable email signup' (Passo 5 do README)"
fi

# 5) login anônimo (também recebe o papel authenticated -> passaria pelo RLS)
echo "5. Login anônimo"
if [[ "$s" == *'"anonymous_users":false'* ]]; then
  ok "desligado"
else
  erro "LIGADO — sessão anônima também vira 'authenticated' e passa pelo RLS."
  echo "         Painel: Authentication -> Sign In / Providers"
  echo "         -> desligue 'Allow anonymous sign-ins'"
fi

echo
if [[ $falhas -eq 0 ]]; then
  printf '\033[32mTudo certo.\033[0m\n'
else
  printf '\033[31m%d problema(s).\033[0m\n' "$falhas"; exit 1
fi
