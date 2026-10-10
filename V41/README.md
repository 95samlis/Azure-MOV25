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
