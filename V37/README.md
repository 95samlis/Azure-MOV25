# V37 - Storage

**Samuel Lissbro**

## Syfte
 



## Skapa lagring


Jag skapade ett Storage Account som ska användas för att lagra ärenden och bifogade filer. Jag valde StorageV2 eftersom det fungerar med Blob Storage. Standard_LRS valdes eftersom det är ett kostnadseffektivt alternativ och samtidigt ger lokal redundans inom samma Azure-region.

### Kommandon

```bash
az storage account create \
  --resource-group rg-novatrix-v34 \
  --name stnovatrixv34 \
  --location swedencentral \
  --sku Standard_LRS \
  --kind StorageV2
```

Skapar den privata Blob-containern arenden i Storage Account stnovatrix34. Den används som lagringsplats för ärenden och filer.

```bash
az storage container create \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login
```

