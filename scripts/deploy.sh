#!/bin/bash
set -e

echo "╔══════════════════════════════════════════════════╗"
echo "║   Secure Azure Foundation Lab - Deploy          ║"
echo "╚══════════════════════════════════════════════════╝"

if [ ! -f "terraform.tfvars" ]; then
  echo "❌ ERRORE: terraform.tfvars non trovato."
  echo "   Copia terraform.tfvars.example in terraform.tfvars."
  exit 1
fi

echo "📦 Inizializzazione Terraform..."
terraform init

echo "🔍 Validazione..."
terraform validate

echo "📋 Piano di deploy:"
terraform plan -out=tfplan

read -p "⚠️  Procedere con il deploy? (y/n): " confirm
if [ "$confirm" != "y" ]; then
  echo "❌ Annullato."
  exit 0
fi

echo "🚀 Deploy in corso..."
terraform apply -auto-approve tfplan

echo "✅ Deploy completato!"
terraform output

rm -f tfplan
echo "💡 Per eliminare tutto: terraform destroy"