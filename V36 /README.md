# v36 – Nätverk och säkerhet

**SAMUEL LISSBRO**

### Syfte och översikt

I denna uppgift byggs ett säkrare nätverk för Novatrix kundtjänst med VNet, subnät och NSG. Webbservern placeras i webbsubnätet och nödvändig trafik tillåts medan övrig trafik blockeras. Ett separat subnät för databas och lagring förbereds för framtida användning.

---

### VNet och Subnät
Jag använder:

- **Resource Group:** `rg-novatrix-v34`
- **VNet:** `vnet-novatrix`
- **Region:** `Sweden Central`
- **Address space:** `172.16.0.0/16`

### IP-planering

| Nätverk | Adressrymd |
|---|---|
| VNet | `172.16.0.0/16` |
| Publikt subnät | `172.16.1.0/24` |
| Privat subnät | `172.16.2.0/24` |



`172.16.0.0/16` ger gott om adressutrymme och gör nätverket skalbart.

---

### Nätverksdesign

<img width="680" height="720" alt="v36-network-diagram" src="https://github.com/user-attachments/assets/5f837962-ffbc-463f-807b-d63c5d3628a4" />

---

### VNet Kommando
Jag använder ett privat adressområde för VNetet eftersom det används för kommunikation mellan Azure-resurserna. Adressrymden /16 ger också utrymme för flera subnät.

```bash
az network vnet create \
  --resource-group rg-novatrix-v34 \
  --name vnet-novatrix \
  --location swedencentral \
  --address-prefix 172.16.0.0/16
```


### Verifiering
När kommandot har kört kontrolleras VNetet med:

```bash
az network vnet show \
  --resource-group rg-novatrix-v34 \
  --name vnet-novatrix \
  --output table
```

### Resultat
VNetet skapades med Azure CLI och verifierades därefter för att säkerställa att rätt resursgrupp, region och adressrymd används.

<img width="2728" height="174" alt="image" src="https://github.com/user-attachments/assets/e6e9ae75-62aa-46e1-a546-3bfe497a124b" />

---

### Skapar subnät

Skapar subnätet snet-web i vnet-novatrix med adressrymden 172.16.1.0/24. Subnätet ska användas för webben och formuläret.
Subnäten används för att hålla webbservern och databasen separerade och göra det enklare att styra trafiken.

### Kommando

```bash
az network vnet subnet create \
  --resource-group rg-novatrix-v34 \
  --vnet-name vnet-novatrix \
  --name snet-web \
  --address-prefixes 172.16.1.0/24
```

Skapar även det privata subnätet snet-db i vnet-novatrix med adressrymden 172.16.2.0/24. Subnätet är förberett för framtida lagring.

```bash
az network vnet subnet create \
  --resource-group rg-novatrix-v34 \
  --vnet-name vnet-novatrix \
  --name snet-db \
  --address-prefixes 172.16.2.0/24
```


### Verifikation

Verifierar att båda subnäten finns i `vnet-novatrix` och att rätt namn och adressrymder har skapats.

```bash
az network vnet subnet list \
  --resource-group rg-novatrix-v34 \
  --vnet-name vnet-novatrix \
  --output table
```

### Resulat

<img width="2938" height="266" alt="Resultat 2" src="https://github.com/user-attachments/assets/7584b094-c723-4683-b711-e916234b675d" />


### Verifiering i Azure Portal

Verifierar även i portalen att subnäten är kopplade till rätt VNet och att webbserverns nätverkskort och använder rätt privata IP-adress.

<img width="2436" height="304" alt="Resultat 3" src="https://github.com/user-attachments/assets/fe8c8d32-1365-49b8-baee-fdc1cff27386" />

---

### Säkrar trafiken


Skapar en Network Security Group med namnet nsg-web i resursgruppen rg-novatrix-v34 och regionen Sweden Central

### Kommandon

```bash
az network nsg create \
  --resource-group rg-novatrix-v34 \
  --name nsg-web \
  --location swedencentral
```

Verifiering 

```bash
az network nsg show \
  --resource-group rg-novatrix-v34 \
  --name nsg-web \
  --output table
```

NSG:n används för att styra vilken nätverkstrafik som får komma till och från webbsubnätet. Detta gör det möjligt att endast tillåta nödvändig trafik och blockera övrig trafik.

### Resultat 

<img width="1616" height="158" alt="Resultat 5" src="https://github.com/user-attachments/assets/94d2e7b8-fed6-4892-a59d-a0d8708c2243" />

---

### Tillåtna portar och trafik

Skapar en inbound-regel som tillåter inkommande HTTP- och HTTPS-trafik på port 80 och 443 till webbsubnätet.

```bash
az network nsg rule create \
  --resource-group rg-novatrix-v34 \
  --nsg-name nsg-web \
  --name Allow-Web \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes Internet \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 80 443
```

### Motivering

Port 80 och 443 behövs för att användare ska kunna nå kundtjänstens webbformulär via HTTP och HTTPS. Endast nödvändig webbtrafik tillåts för att minska onödig exponering. Regeln har prioritet 100, vilket ger den hög prioritet och samtidigt utrymme för framtida regler.

### Allow SSH Admin

Tillåter inkommande SSH-trafik från min publika IP-adress på port 22.

```bash
az network nsg rule create \
  --resource-group rg-novatrix-v34 \
  --nsg-name nsg-web \
  --name Allow-SSH-Admin \
  --priority 200 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefixes 81.226.253.57 \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 22
```



### Motivering

SSH används för administrativ åtkomst. Genom att endast tillåta min egen IP-adress begränsas åtkomsten och risken för obehöriga anslutningar minskar. Regeln har prio 200 för att skapa utrymme för framtida regler mellan webb- och adminåtkomst.

### Verifiering

```bash
az network nsg rule list \
  --resource-group rg-novatrix-v34 \
  --nsg-name nsg-web \
  --output table
```
<img width="3162" height="308" alt="Resultat 6" src="https://github.com/user-attachments/assets/7e86e242-659d-4e31-ac76-9a0c8033e148" />

En extra verifiering genomfördes via Azure Portal för att bekräfta att regeln fungerar som förväntat.

<img width="2588" height="268" alt="Resultat 7" src="https://github.com/user-attachments/assets/d5c47747-0d12-4b68-a6dc-e092c0c76509" />


### NSG-regler

| Prioritet | NSG-regel | Port | Källa | Resultat |
|---:|---|---|---|---|
| 100 | `Allow-Web` | 80, 443 | Internet | Tillåts |
| 200 | `Allow-SSH-Admin` | 22 | `81.226.253.57` | Tillåts |
| – | `DenyAllInBound`* | Övrig inbound | Alla | Blockeras |

\* `DenyAllInBound` är en Azure-standardregel som blockerar övrig inkommande trafik.

---

## Koppla NSG till subnätet

nsg-web ska kopplas till snet-web så reglerna faktiskt börjar gälla för resurser i webbsubnätet. Genom att koppla NSG:n till subnätet kan samma trafikregler gälla för flera resurser som placeras där, utan att varje maskin behöver egna regler.

### Kommando

Kopplar nsg-web till subnätet snet-web i vnet-novatrix.

```bash
az network vnet subnet update \
  --resource-group rg-novatrix-v34 \
  --vnet-name vnet-novatrix \
  --name snet-web \
  --network-security-group nsg-web
```
### Motivering

När NSG:n kopplas till snet-web börjar dess trafikregler gälla för resurser i subnätet.

### Verifiering

```bash
az network vnet subnet show \
  --resource-group rg-novatrix-v34 \
  --vnet-name vnet-novatrix \
  --name snet-web \
  --query networkSecurityGroup.id \
  -o tsv
```


