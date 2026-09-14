# V37 - Storage

**Samuel Lissbro**

## Syfte
 



## Skapa lagring

Jag skapade den privata `Blob-containern` `arenden` i `Storage Account` `stnovatrixv34`. För att verifiera lagringen laddade jag upp en testfil. Filen syntes i containern, men kunde inte nås direkt via URL eftersom publik åtkomst är avstängd `(PublicAccessNotPermitted). `


### Kommando

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

---


Jag skapade den privata `Blob-containern` arenden i `Storage Account` `stnovatrixv34`. Containern används som lagringsplats för ärenden och bifogade filer.
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


För att appen ska kunna använda Blob Storage behöver den få åtkomst till lagringskontot. Istället för att använda lagringsnycklar används den hanterade identiteten `id-novatrix-app` tillsammans med Azure RBAC.

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



Därefter tilldelas rollen `Storage Blob Data Reader` till identiteten.


### Kommando

```bash
az role assignment create \
  --assignee 1e9073bb-485c-409b-a049-71e5fee3ba36 \
  --role "Storage Blob Data Reader" \
  --scope $az storage account show \
      --resource-group rg-novatrix-v34 \
      --name stnovatrixv34 \
      --query id \
      --output tsv
```

### Verifikation

Verifierade att rollen `Storage Blob Data Reader` tilldelades till identiteten `id-novatrix-app`.


### Kommando 

```bash
az role assignment list \
  --assignee 1e9073bb-485c-409b-a049-71e5fee3ba36 \
  --all \
  --output table
```

### Resultat

<img width="704" height="95" alt="image" src="https://github.com/user-attachments/assets/a71904ca-8f8e-4e33-ab8c-ea5744fd4ca9" />




<img width="2424" height="124" alt="Skärmbild 2026-09-14 174446" src="https://github.com/user-attachments/assets/ab20b59e-2423-460d-9909-4a78c67841af" />





















---
## Koppla formuläret till lagringen

