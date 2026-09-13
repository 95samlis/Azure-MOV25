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

<img width="2478" height="524" alt="lllgffd" src="https://github.com/user-attachments/assets/fe10207a-173e-42ab-95dd-f0f9e1cbba64" />


Jag skapade den privata Blob-containern arenden i Storage Account stnovatrixv34. Containern används som lagringsplats för ärenden och bifogade filer.
Testade att ladda upp en fil till Blob Storage för att säkerhetsställa att lagringen fungerade.


```bash
az storage container create \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login
```
### Resultat


<img width="2712" height="506" alt="STRS02" src="https://github.com/user-attachments/assets/11e5fe14-6032-4b93-b5f3-ff52c4c4568a" />
