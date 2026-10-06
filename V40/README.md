# V40 – Virtualiseringsnivåer

**Samuel Lissbro** 

## Syfte

Syftet med uppgiften är att köra en del av Novatrix kundtjänst på en annan virtualiseringsnivå än den tidigare VM-baserade lösningen samt att jämföra virtuella maskiner, containers och serverless-tjänster.


## Motivering av vald lösning

Jag valde att köra kundtjänstens webbapplikation som en `Docker`-container i `Azure Container Instance (ACI)`. Eftersom applikationen ska vara tillgänglig för användarna behövs en lösning som kan köras hela tiden och nås via en publik adress.

Applikationen är relativt liten och passar därför bra för en containerbaserad lösning. Genom att använda en container kunde applikationen paketeras som en container-image med samma körmiljö från utveckling till drift. Lösningen blev samtidigt enkel att distribuera i Azure utan att en egen `VM` behövde administreras.

---

### Skapa ACR
För att kunna lagra applikationens `Docker`-image skapade jag ett `Azure Container Registry (ACR)`. Här lagras imagen innan den används för att skapa en container i `Azure Container Instances (ACI)`, där applikationen senare körs. ACR fungerar som ett privat containerregister som gör det möjligt för ACI att hämta rätt image vid deployment.

### Registrera resursleverantör


```bash
az provider register --namespace Microsoft.ContainerRegistry
```

Registrerar resursleverantören `Microsoft.ContainerRegistry` i prenumerationen. 


### Skapa ACR


```bash
az acr create --resource-group rg-novatrix --name novatrixacr388 --sku Basic
```
Skapar ett ACR med namnet `novatrixacr388` i resursgruppen `rg-novatrix`.

Nivån `Basic` valdes eftersom den räcker för lösningens omfattning.


## Aktivera administratörskonto i ACR

För att `Azure Container Instances (ACI)` skulle kunna hämta container-imagen från registret aktiverades administratörskontot i `ACR`. Detta gör det möjligt att använda användarnamn och lösenord för autentisering mot registret.

### Aktivera administratörskontot

```bash
az acr update --name novatrixacr388 --admin-enabled true
```

Aktiverar administratörskontot i `ACR`.

### Hämta inloggningsuppgifter

```bash
az acr credential show --name novatrixacr388
```

Visar användarnamn och lösenord för registret. Uppgifterna används senare när containern skapas och behöver åtkomst till den lagrade imagen.

### Sammanfattning

Administratörskontot aktiverades för att `ACI` skulle kunna autentisera sig mot `ACR` och hämta den container-image som används för att köra applikationen.
