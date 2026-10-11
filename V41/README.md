# Examination slutuppgift

**Samuel Lissbro**

## Syfte

Syftet med uppgiften är att planera och implementera en säker och fungerande hyresgästportal för Nordvik Fastigheter AB i Microsoft Azure. Portalen ska göra det möjligt för hyresgäster att logga in och skicka in felanmälningar med rubrik, beskrivning och bild. Förvaltare ska kunna ta emot och hantera ärenden, medan ekonomi ska ha läsande insyn.

Lösningen ska innehålla säker lagring av ärenden, bilder och dokument, kontrollerad åtkomst utifrån roller samt ett automatiserat arbetsflöde mot Nordviks Microsoft 365. 

---

## Översikt och planering

Jag har valt att bygga Nordviks hyresgästportal i Microsoft Azure med en containerbaserad webbapplikation. Portalen körs i Azure Container Apps. Det gör att applikationen kan köras utan att jag behöver hantera en egen virtuell server.

Bilder och ärendedata lagras i Azure Blob Storage. Portalen använder en hanterad identitet för att få åtkomst till lagringen utan att behöva lagra inloggningsuppgifter i koden.

Power Automate kopplar ihop lösningen med Microsoft 365. När ett ärende skickas in skapas en post i SharePoint och relevanta meddelanden skickas automatiskt.

Jag valde den här lösningen eftersom den passar en webbportal som har varierande trafik. Container Apps kan anpassa antalet instanser efter belastningen.

### Azure-resurser i projektet 

| Resursnamn | Funktion |
|:-----------|:---------|
| `rg-nordvik` | Samlar projektets huvudsakliga Azure-resurser. |
| `ca-nordvik-portal` | Kör Nordviks webbportal. |
| `acrnordviksamlis9501` | Lagrar containeravbildningen som används av portalen. |
| `stnordviksamlis9501` | Lagrar ärenden, bilder och dokument. |
| `id-nordvik-app` | Ger portalen en identitet för säker åtkomst till lagringen. |
| `managedEnvironment-rgnordvik-8918` | Körmiljö för Azure Container Apps. |
| `workspacergnordvik8e03` | Log Analytics-arbetsyta för loggar och felsökning. |


### Containers i `stnordviksamlis9501`

| Containernamn | Åtkomstnivå | Funktion |
|:--------------|:------------|:---------|
| `nordvik-arenden` | Privat | Lagrar ärenden och tillhörande bilder. |
| `nordvik-dokument` | Privat | Lagrar dokument. |

### Namngivning och taggar

Jag har använt tydliga resursnamn som visar vad resurserna används till. Namngivningen följer mönstret typ-nordvik-funktion, med undantag för resurser som har andra namnkrav i Azure.

Jag  har även lagt till taggarna Department, Environment och Project. De används för att koppla resurserna till rätt avdelning, miljö och projekt. Taggarna gör det också enklare att följa upp kostnader i Cost Management.

## IAM och RBAC – identiteter och behörigheter

| Användare/resurs | Behörighet och funktion |
|:-----------------|:------------------------|
| Hyresgäster | Måste autentisera sig mot portalen för att skapa sina ärenden. |
| Förvaltare | Gruppen `grp-nordvik-forvaltare` har *Edit* i SharePoint för att hantera ärenden. Har inga tilldelade Azure-behörigheter. |
| Ekonomi | Gruppen `grp-nordvik-ekonomi` har *Read* i SharePoint och *Cost Management Reader* i Azure för att läsa kostnadsinformation. |
| `id-nordvik-app` | Hanterad identitet som portalen använder för att autentisera sig mot Azure Storage. |
| `nordvik-arenden` | `id-nordvik-app` har rollen *Storage Blob Data Contributor* på containern. |
| `nordvik-dokument` | `id-nordvik-app` har rollen *Storage Blob Data Contributor* på containern. |

<img width="2400" height="1242" alt="nordvik-arkitektur" src="https://github.com/user-attachments/assets/19d83d9c-0941-4342-90ac-c71e670389a5" />

---

## Virtualiseringsnivåer och val av lösning

VM:s ger större kontroll över OS, men kräver mer administration. För att hantera högre belastning hade jag kunnat använda VM Scale Sets med flera virtuella maskiner. Det hade dock inneburit fler maskiner att hantera och potentiellt högre kostnader.

Containers kör applikationen i en isolerad miljö utan att jag behöver hantera ett eget operativsystem för varje instans. Jag körde på Container Apps eftersom jag enkelt kan justera resurserna och antalet repliker. Varje replik har `1vCPU` och `2GB` minne. Jag har satt minst 2 och högst 10 repliker. Vid högre belastning kan Azure automatiskt skapa fler repliker och när belastningen minskar kan antalet anpassas igen. De två minsta replikerna ger redundans om en instans slutar fungera.

Jag tyckte att detta passade Nordviks behov bättre än flera virtuella maskiner, eftersom jag kan anpassa kapaciteten efter trafiken och slipper administrera VM-infrastrukturen. Det kan också ge lägre kostnader, även om den faktiska kostnaden beror på belastningen och konfigurationen.

Serverless valde jag bort eftersom jag ville ha en webbportal som är ständigt tillgänglig och har minst två repliker igång. Serverless passar bra för enskilda funktioner som körs vid anrop eller händelser, men jag bedömde att Container Apps passade bättre för att driva själva portalen. 

---
### Infrastruktur skapad med ARM-template

Jag använde ARM-template för att automatisera skapandet av delar av infrastrukturen. 

Templaten skapar följande resurser:

- **Storage Account** med två privata blob-containrar: `nordvik-arenden` och `nordvik-dokument`.
- **Azure Container Registry (ACR)** för lagring av portalens containeravbildning.
- **User Assigned Managed Identity** som portalen använder för åtkomst till lagringen.
- **RBAC-rolltilldelningar** som ger den hanterade identiteten rollen *Storage Blob Data Contributor* på båda containrarna.

Parameterfilen innehåller namn och region för lagringskontot, containern, ACR och den hanterade identiteten. Det gör det enklare att ange rätt värden när infrastrukturen skapas.
*Container Apps-miljön och appen skapades manuellt på grund av problem med ARM-distributionen i vald region.*

---

## Skapandet av Container Apps Environment och Container App

### Container Apps Environment

Miljön samlar Container Apps på ett ställe och gör det enklare att hantera nätverk och loggning gemensamt. Den gör det också möjligt att lägga till fler appar i framtiden utan att behöva skapa en ny miljö för varje app.

### Container App – konfiguration

Jag skapade Container Appen `ca-nordvik-portal` i Azure-portalen och kopplade den till den skapade miljön. Jag valde `ACR` (`acrnordviksamlis9501`) som källa för Docker-imagen `nordvik-portal`.

| Inställning | Värde |
|:------------|:------|
| **Image** | `nordvik-portal:v3` |
| **Autentisering mot registret** | System assigned Identity (environment)|
| **Resurser** | 1 vCPU och 2 GiB minne |
| **Ingress** | Aktiverad med trafik från internet |
| **Protokoll och port** | HTTP, port 80 |
| **Osäkra anslutningar** | Inte tillåtna via ingressen |

Inställningarna gör webbappen tillgänglig via en offentlig HTTPS-adress, medan appen tar emot trafik på port 80 via ingressen.

### Resultat

<img width="700" height="450" alt="Skärmbild 2026-10-11 180359" src="https://github.com/user-attachments/assets/3bbbe85e-9735-424b-881c-b5bae06b14ff" />

<img width="700" height="450" alt="Skärmbild 2026-10-11 180612" src="https://github.com/user-attachments/assets/4353f738-8e5e-4a56-b8e1-e6007af40ab0" />




## Uppdatering av Docker-image

Efter ändringar i applikationskoden byggde jag nya Docker-images och uppdaterade Container Appen vid flera tillfällen för att få den uppdaterade applikationen att fungera i Azure.

Ändringarna omfattade:

- **Kategorisering av felanmälningar:** Hyresgästen kan välja mellan *Värme*, *Vatten*, *Lås*, *El*, *Ventilation* och *Annat*. Kategorin sparas tillsammans med ärendedatan.
- **Autentisering mot Azure Storage:** Backendkoden använder Managed Identity i stället för en lagringsnyckel för att autentisera sig mot lagringen.
- **Lagring i Nordviks Azure-miljö:** Ärenden och bilder sparas i Nordviks lagringskonto, i containern `nordvik-arenden`.

### Verifiering av Managed Identity

För att kontrollera att backendkoden använder Managed Identity körde jag följande kommando i terminalen:

```powershell
Select-String -Path .\nord-app.py -Pattern "ManagedIdentityCredential|AZURE_CLIENT_ID|ACCOUNT_KEY"
```

Resultatet visade att koden använder `ManagedIdentityCredential` och hämtar klient-ID från `AZURE_CLIENT_ID`.

<img width="1162" height="154" alt="Skärmbild 2026-10-11 181732" src="https://github.com/user-attachments/assets/c9826bdc-3bc5-4da8-a143-152822470114" />


## Uppdatering av Container App

Efter ytterligare ändringar behövde jag uppdatera Docker-imagen igen. Jag uppdaterade därför den befintliga Container Appen så att den använde imagen `v2`:

```powershell
az containerapp update `
  --name ca-nordvik-portal `
  --resource-group rg-nordvik `
  --image acrnordviksamlis9501.azurecr.io/nordvik-portal:v2
```

Kommandot uppdaterar den befintliga Container Appen för att skapa en ny.

### Kontroll av revision

Efter uppdateringen kontrollerade jag appens revisioner och status med följande kommando:

```powershell
az containerapp revision list `
  --name ca-nordvik-portal `
  --resource-group rg-nordvik `
  --output table
```

### Resultat

Bilden visar att revisionen `ca-nordvik-portal--0000009` var aktiv, hade två repliker och rapporterades som *Healthy*.

<img width="1982" height="144" alt="image" src="https://github.com/user-attachments/assets/2b2e66f4-663b-4568-bd2c-a04fe1ef68c2" />

### Slutresultat

Container Appen är driftsatt och redo att ta emot trafik. Den kör två repliker och använder imagen nordvik-portal:v3.

<img width="2532" height="662" alt="Skärmbild 2026-10-11 182919" src="https://github.com/user-attachments/assets/72df7dd9-ab1a-45d6-b9d8-ae0b2d6d4c30" />

---

## Test av autentisering och åtkomst

Jag testade portalen med en inbjuden extern användare och en användare som inte var inbjuden.

- **Inbjuden användare:** Kunde logga in och kom till formuläret för att skicka in en felanmälan.
- **Ej inbjuden användare:** Nekades åtkomst eftersom kontot inte fanns som extern användare i min tenant.


<img width="1810" height="224" alt="au 01" src="https://github.com/user-attachments/assets/eb8be5fc-f63d-42b5-914f-a2d081b76a1e" />
<img width="1000" height="90" alt="externuser" src="https://github.com/user-attachments/assets/e83591ba-6847-403b-a1dc-e1ff2606a3b7" />
<img width="600" height="500" alt="lyckadinlogg" src="https://github.com/user-attachments/assets/23f96c3a-6846-4f11-b0eb-791ace62a05a" />
<img width="600" height="600" alt="inloggruta" src="https://github.com/user-attachments/assets/dcfde3b1-f3ae-4c6f-aefd-2267c94afde1" />

<img width="800" height="400" alt="Behörighettest inloggportal" src="https://github.com/user-attachments/assets/895f825b-a3aa-45fd-bf66-130e7e72df54" />


Testet visar att portalen kräver autentisering och att en användare som inte är inbjuden inte kan logga in.

---
