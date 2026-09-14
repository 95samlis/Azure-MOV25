# V37 - Storage

**Samuel Lissbro**

## Syfte
 



## Skapa lagring

Jag skapade ett Storage Account med namnet `stnovatrixv34`. För att verifiera lagringen laddade jag upp en testfil. Filen syntes i lagringen men kunde inte nås direkt via URL eftersom publik åtkomst är avstängd.



### Kommando

```bash
az storage account create \
  --resource-group rg-novatrix-v34 \
  --name stnovatrixv34 \
  --location swedencentral \
  --sku Standard_LRS \
  --kind StorageV2
```

### Test

<img width="1840" height="120" alt="image" src="https://github.com/user-attachments/assets/333c4f75-da39-4e53-8a1b-338dc3aa0327" />

### Resultat

<img width="2478" height="524" alt="lllgffd" src="https://github.com/user-attachments/assets/fe10207a-173e-42ab-95dd-f0f9e1cbba64" />

---


Jag skapade den privata `Blob-containern` `arenden` i `Storage Account` `stnovatrixv34`. Containern används som lagringsplats för ärenden och bifogade filer.
Testade även att ladda upp en fil till `Blob Storage` för att säkerhetsställa att lagringen fungerade.

### Kommando

```bash
az storage container create \
  --account-name stnovatrixv34 \
  --name arenden \
  --auth-mode login
```

Jag använde standardinställningen Hot Tier eftersom ärenden och bifogade filer förväntas användas regelbundet och därför behöver vara lättillgängliga. Verifierade även i portalen att `Secure transfer required` var aktiverat samt att den anonyma åtkomsten var avstängd.

### Resultat


<img width="2712" height="506" alt="STRS02" src="https://github.com/user-attachments/assets/11e5fe14-6032-4b93-b5f3-ff52c4c4568a" />


---
## Säkra åtkomsten


För att appen ska kunna använda Blob Storage behöver den få åtkomst till `containern` `arenden`. Istället för att använda lagringsnycklar används den hanterade identiteten `id-novatrix-app` tillsammans med Azure RBAC.

### Kommando

För att ge applikationen åtkomst till Blob Storage utan att använda lagringsnycklar används Azure RBAC med den hanterade identiteten `id-novatrix-app`.

Först hämtas identitetens `Principal ID`, vilket behövs när en roll ska tilldelas.

```bash
az identity show \
  --resource-group rg-novatrix-v34 \
  --name id-novatrix-app \
  --query principalId \
  --output tsv
```


### Kommando

Rollen `Storage Blob Data Contributor` tilldelades den hanterade identiteten `id-novatrix-app` så att webbapplikationen kan lagra inkomna ärenden och bifogade filer i containern `arenden`.
Behörigheten begränsas till containern `arenden` enligt RBAC.


```bash
az role assignment create \
  --assignee 1e9073bb-485c-409b-a049-71e5fee3ba36 \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/6b33d5e0-e2c3-49f5-b867-93aa80cdffcd/resourceGroups/rg-novatrix-v34/providers/Microsoft.Storage/storageAccounts/stnovatrixv34/blobServices/default/containers/arenden"
```

### Verifikation

Verifierade att rollen `Storage Blob Data Contributor` tilldelades till identiteten `id-novatrix-app` och att behörigheten begränsades till containern `arenden`.


### Kommando 

```bash
az role assignment list \
  --assignee 1e9073bb-485c-409b-a049-71e5fee3ba36 \
  --all \
  --output table
```

### Resultat

<img width="980" height="90" alt="image" src="https://github.com/user-attachments/assets/a816c6a8-1e4f-4781-9338-c5f40dd47f3f" />





<img width="1908" height="134" alt="image" src="https://github.com/user-attachments/assets/5f398970-8391-436f-b3af-21d81aad74d0" />




---
## Koppla formuläret till lagringen

För att kunna ta emot ärenden från webbplatsen skapades en Flask-backend som tar emot formulärdata från hemsidan.
När användaren skickar in ett ärende sparas informationen i Blob-containern `arenden`. Om en bild bifogas sparas även den i samma container.

För att webbservern skulle kunna lagra ärenden i Blob Storage tilldelades rollen `Storage Blob Data Contributor` till `vm-novatrix-web`. Behörigheten begränsades till containern `arenden` för att undvika onödigt bred åtkomst.


