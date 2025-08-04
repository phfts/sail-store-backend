#!/bin/bash

# Script para deploy no Heroku
echo "🚀 Iniciando deploy no Heroku..."

# Verificar se o app já existe
if ! heroku apps:info --app sail-store-backend 2>/dev/null; then
    echo "📦 Criando novo app no Heroku..."
    heroku create sail-store-backend
else
    echo "✅ App já existe no Heroku"
fi

# Adicionar PostgreSQL
echo "🗄️ Configurando PostgreSQL..."
heroku addons:create heroku-postgresql:mini --app sail-store-backend

# Configurar variáveis de ambiente
echo "🔧 Configurando variáveis de ambiente..."
heroku config:set RAILS_ENV=production --app sail-store-backend
heroku config:set RAILS_SERVE_STATIC_FILES=true --app sail-store-backend
heroku config:set RAILS_LOG_TO_STDOUT=true --app sail-store-backend

# Fazer commit das mudanças se necessário
if ! git diff --quiet; then
    echo "💾 Fazendo commit das mudanças..."
    git add .
    git commit -m "Configuração para deploy no Heroku"
fi

# Fazer push para o Heroku
echo "📤 Fazendo push para o Heroku..."
git push heroku main

# Executar migrations
echo "🔄 Executando migrations..."
heroku run rails db:migrate --app sail-store-backend

# Verificar se o app está funcionando
echo "🔍 Verificando status do app..."
heroku ps --app sail-store-backend

echo "✅ Deploy concluído!"
echo "🌐 URL do app: https://sail-store-backend.herokuapp.com" 