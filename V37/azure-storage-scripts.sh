# ==========================================
# AZURE STORAGE - NOVATRIX
# ==========================================

# Skapa Storage Account
az storage account create \
  --resource-group rg-novatrix-v34 \
  --name stnovatrixv34 \
  --location swedencentral \
  --sku Standard_LRS \
  --kind StorageV2

# Skapa privat Blob-container
az storage container create \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login

# Visa information om containern
az storage container show \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login

# ==========================================
# MANAGED IDENTITY
# ==========================================

# Hämta Principal ID för User Assigned Identity
az identity show \
  --resource-group rg-novatrix-v34 \
  --name id-novatrix-app \
  --query principalId \
  --output tsv

# Hämta VM:ns System Assigned Identity
az vm identity show \
  --resource-group rg-novatrix-v34 \
  --name vm-novatrix-web

# ==========================================
# RBAC - CONTAINER
# ==========================================

# Ge User Assigned Identity åtkomst till containern
az role assignment create \
  --assignee 1e9073bb-485c-409b-a049-71e5fee3ba36 \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34/providers/Microsoft.Storage/storageAccounts/stnovatrixv34/blobServices/default/containers/arenden"

# Ge VM:n åtkomst till containern
az role assignment create \
  --assignee <VM_PRINCIPAL_ID> \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34/providers/Microsoft.Storage/storageAccounts/stnovatrixv34/blobServices/default/containers/arenden"

# Lista roller för en identitet
az role assignment list \
  --assignee <PRINCIPAL_ID> \
  --all \
  --output table

# Ta bort en roll
az role assignment delete \
  --assignee <PRINCIPAL_ID> \
  --role "Storage Blob Data Contributor" \
  --scope "<SCOPE>"

# ==========================================
# VERIFIERING
# ==========================================

# Visa Storage Account ID
az storage account show \
  --resource-group rg-novatrix-v34 \
  --name stnovatrixv34 \
  --query id \
  --output tsv

# Kontrollera att containern finns
az storage container show \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login
