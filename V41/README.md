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
