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

## Blob Storage och livscykelhantering

Jag har delat upp lagringen i två privata containrar:

- `nordvik-arenden` – felanmälningar och bilder.
- `nordvik-dokument` – kontrakt och besiktningsprotokoll.

För att minska lagringskostnaderna har jag satt upp tre livscykelregler:

- **Ärenden:** Flyttas från *Hot* till *Cool* efter 90 dagar och raderas efter 365 dagar.
- **Dokument:** Flyttas från *Hot* till *Cool* efter 90 dagar.

<img width="2062" height="368" alt="Skärmbild 2026-10-11 220410" src="https://github.com/user-attachments/assets/90655cae-7575-4322-baab-89845334f0c0" />



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
<img width="2190" height="94" alt="externuser" src="https://github.com/user-attachments/assets/1f4f824e-436d-4249-a43e-a9e48bc330fb" />


<img width="600" height="500" alt="lyckadinlogg" src="https://github.com/user-attachments/assets/23f96c3a-6846-4f11-b0eb-791ace62a05a" /><img width="600" height="500" alt="inloggruta" src="https://github.com/user-attachments/assets/dcfde3b1-f3ae-4c6f-aefd-2267c94afde1" />


<img width="800" height="400" alt="Behörighettest inloggportal" src="https://github.com/user-attachments/assets/895f825b-a3aa-45fd-bf66-130e7e72df54" />

Testet visar att portalen kräver autentisering och att en användare som inte är inbjuden inte kan logga in.

---

### Defense in Depth 

Jag har använt flera säkerhetslager för att skydda portalen och dess data. Användare måste logga in för att komma åt portalen. En obehörig användare nekas åtkomst. Portalen använder Managed Identity för att komma åt Azure Storage utan att lagringsnyckeln finns i koden. Lagringscontainrarna är privata och behörigheter styr vem som får komma åt dem. Anslutningen till portalen använder HTTPS.


---

## Flödets funktion Power Automate

Flödets funktion bygger främst på fyra villkor som styr hur en felanmälan ska hanteras.

Det första villkoret **Is Json** kontrollerar vilken filtyp som har kommit in. Eftersom både JSON-filer och PNG-bilder triggar flödet går endast JSON-filer vidare, medan PNG-filer stoppas i den falska grenen.

Det andra villkoret **Is category critical** kontrollerar vilken kategori ärendet tillhör. Kategorierna **Värme**, **Vatten** och **Lås** räknas som kritiska och hanteras därför genom en separat väg i flödet.

Beroende på om ärendet är kritiskt eller inte används sedan ett separat villkor för att kontrollera om ärendet innehåller en bild.

- **Kritiskt ärende → Condition image**  
  Kontrollerar om en bild finns. Om en bild finns läggs den till i SharePoint-ärendet och ett kritiskt e-postmeddelande skickas. Om ingen bild finns skapas ärendet utan bild och e-post skickas utan bilaga.

- **Icke-kritiskt ärende → Image condition**  
  Kontrollerar på samma sätt om en bild finns. Om en bild finns läggs den till i SharePoint-ärendet och en Teams-notis skickas. Om ingen bild finns skapas ärendet utan bild och Teams-notisen skickas utan bild.

På detta sätt kan samma flöde hantera både kritiska och icke-kritiska ärenden, samt ärenden med eller utan bifogad bild.

## Flödets struktur för hantering av felanmälningar

<img width="1316" height="1450" alt="Skärmbild 2026-10-11 204025" src="https://github.com/user-attachments/assets/aa11a53c-2376-4d7f-8f20-8aa5f7568c56" />

## Testning och verifiering

Flödet testas med olika typer av felanmälningar för att kontrollera att rätt väg och åtgärder används beroende på kategori och om en bild finns bifogad.

### Test 1 – Icke-kritiskt ärende utan bild

<img width="1000" height="500" alt="Test1 1" src="https://github.com/user-attachments/assets/af930322-71c9-4921-ab0f-67d5959d9964" />

<img width="970" height="200" alt="test 1 2" src="https://github.com/user-attachments/assets/90457a55-b0f6-491c-8d73-82fc91d7e4c0" />

---

### Test 2 – Icke-kritiskt ärende med bild

<img width="800" height="600" alt="Test2 1" src="https://github.com/user-attachments/assets/f1f53ac4-6a16-48db-bfe2-8c962f79d800" />

<img width="1386" height="442" alt="Test2 2" src="https://github.com/user-attachments/assets/f5aa3f49-39e0-4a06-8917-6b05d7e95efc" />

<img width="1078" height="1000" alt="Test2 3" src="https://github.com/user-attachments/assets/022bcc33-3cca-4042-9808-a790ded3eb8d" />

Förvaltaren är inloggad och har behörighet att ändra poster i SharePoint-listan. 
Öppnad länk till bifogad bild

<img width="800" height="852" alt="Skärmbild 2026-10-11 211348" src="https://github.com/user-attachments/assets/6bd71c03-7505-4fea-9345-d8ab7cf0ab92" />

---

### Test 3 – Kritiskt ärende utan bild

<img width="1316" height="986" alt="test3" src="https://github.com/user-attachments/assets/106ece7f-a8c0-407f-82d9-74cca52f974a" />

Flödet hamnar i rätt gren samt mail kom fram direkt till ansvarig.

<img width="654" height="1002" alt="Test3 1" src="https://github.com/user-attachments/assets/db24a4a7-bb52-45d2-a7cb-401885dd8958" />

<img width="1130" height="592" alt="Skärmbild 2026-10-11 212721" src="https://github.com/user-attachments/assets/5e877b36-d9c5-4bc2-b6e8-842c7713fb05" />

### Test 4 – Kritiskt ärende med bild

<img width="1396" height="1246" alt="Skärmbild 2026-10-11 213018" src="https://github.com/user-attachments/assets/ee60e83f-17a2-4b5e-99b1-4320a391c444" />

Testet visar att ett kritiskt ärende med kategorin Vatten fungerar. Namn, e-post, kategori och beskrivning visas, och bilden finns med som bilaga.

<img width="1134" height="698" alt="image" src="https://github.com/user-attachments/assets/30455722-7ba0-463d-9454-b722736f3b93" />

<img width="1134" height="698" alt="Skärmbild 2026-10-11 213853" src="https://github.com/user-attachments/assets/ba7a1a1e-4939-46bb-a7ea-da5a03c83e1c" />

---

### Test – Behörigheter i SharePoint-listan

Behörigheten testades med två olika användare. Förvaltare har behörighet att redigera ärenden, medan ekonomi endast har läsbehörighet.

Förvaltaren kunde öppna och redigera ärenden i listan. Ekonomianvändaren kunde inte redigera.

Testet visar att rätt behörigheter är tilldelade till respektive grupp.

<img width="1490" height="974" alt="erik konomi skrivskydd" src="https://github.com/user-attachments/assets/26f9dfce-9188-4670-9952-78cfc12da2b3" />

<img width="1262" height="1002" alt="fredrik forvaltare edit" src="https://github.com/user-attachments/assets/fa7a408b-aac5-49f8-a433-17c1477ddc91" />


---

## Budget och kostnadsuppföljning

Nordvik har en månadsbudget på 2500:- för Azure. Jag har ställt in varningar vid:

- 50, 75 och 90 % av kostnaden
- 70 % av den beräknade kostnaden

Taggarna `Department`, `Environment` och `Project` används för att följa upp kostnaderna för olika delar av verksamheten.

<img width="1392" height="266" alt="budget2" src="https://github.com/user-attachments/assets/e1ac753e-3c2e-4e01-8c08-6fc73516381f" />

---

### Test av ekonomigruppens behörigheter

Ekonomigruppen kan läsa kostnadsinformation i Cost Management. När jag testade med ekonomianvändaren visades inga Azure-resursgrupper. Behörigheten är avgränsad till kostnadsområdet och ger inte gruppen åtkomst till projektets resursgrupper.

<img width="1704" height="1108" alt="ekonomi behörigheter" src="https://github.com/user-attachments/assets/d45b9fd7-1591-400e-8d7d-51fe695c3bc5" />
<img width="2050" height="952" alt="bh ek" src="https://github.com/user-attachments/assets/906c05bb-0516-4a85-81ac-5aa6099d02b9" />
<img width="2408" height="1054" alt="erikekonomicost" src="https://github.com/user-attachments/assets/99dfde46-81f5-4498-a8f6-c81d665db35b" />

