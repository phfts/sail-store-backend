#!/bin/bash

# Script para deploy no Railway
echo "🚀 Iniciando deploy no Railway..."

# Verificar se o Railway CLI está instalado
if ! command -v railway &> /dev/null; then
    echo "📦 Instalando Railway CLI..."
    npm install -g @railway/cli
fi

# Fazer login no Railway
echo "🔐 Fazendo login no Railway..."
railway login

# Inicializar projeto Railway
echo "📦 Inicializando projeto Railway..."
railway init

# Adicionar PostgreSQL
echo "🗄️ Configurando PostgreSQL..."
railway add

# Fazer deploy
echo "📤 Fazendo deploy..."
railway up

echo "✅ Deploy concluído!"
echo "🌐 URL do app será mostrada no Railway Dashboard" 