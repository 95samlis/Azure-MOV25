# V37 - Storage

**Samuel Lissbro**

## Syfte
 



## Skapa lagring





Jag skapade ett Storage Account som ska användas för lagringen i lösningen. Jag valde StorageV2 eftersom det fungerar med Blob Storage. Standard_LRS valdes eftersom det är tillräckligt för den här labben samtidigt som kostnaden hålls nere.


### Kommandon

```bash
az storage account create \
  --resource-group rg-novatrix-v34 \
  --name stnovatrixv34 \
  --location swedencentral \
  --sku Standard_LRS \
  --kind StorageV2
```

### Resultat



Jag skapade den privata Blob-containern arenden i Storage Account stnovatrixv34. Containern används som lagringsplats för ärenden och bifogade filer.


```bash
az storage container create \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login
```

