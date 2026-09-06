



## Steg 1 – Skapa VNet

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


<img width="680" height="720" alt="v36-network-diagram" src="https://github.com/user-attachments/assets/5f837962-ffbc-463f-807b-d63c5d3628a4" />
<svg width="680" height="720" viewBox="0 0 680 720" xmlns="http://www.w3.org/2000/svg" role="img" xmlns:c2pa="http://c2pa.org/manifest"><metadata>

### NSG-regler

| Prioritet | NSG-regel | Port | Källa | Resultat |
|---:|---|---|---|---|
| 100 | `Allow-Web` | 80, 443 | Internet | Tillåts |
| 200 | `Allow-SSH-Admin` | 22 | `81.226.253.57` | Tillåts |
| – | `DenyAllInBound`* | Övrig inbound | Alla | Blockeras |

\* `DenyAllInBound` är en Azure-standardregel som blockerar övrig inkommande trafik.
