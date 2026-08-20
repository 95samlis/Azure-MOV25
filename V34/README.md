## v34 – Compute: Driftsättning av Novatrix kundtjänst

**SAMUEL LISSBRO**

### Syfte

Att skapa den grundläggande infrastrukturen för Novatrix kundtjänst genom att sätta upp en virtuell server i Azure, ansluta till den via SSH och driftsätta en enkel webbplats.

---

## Azure-miljö

Jag skapade resursgruppen `rg-novatrix-v34` i regionen `Sweden Central`.

Därefter skapade jag den virtuella servern `vm-novatrix-web` med:

- Ubuntu Server 24.04 LTS Gen2
- Standard_B2ats_v2
- Port 80 öppnades för inkommande HTTP-trafik

### Verifiering

Den virtuella servern skapades utan fel och fick en publik IP-adress.

---

## SSH-anslutning

För att ansluta till servern laddade jag ner den privata SSH-nyckeln från Azure och konfigurerade filrättigheterna lokalt i PowerShell.

### Kommandon

```powershell
cd "C:\Azure\Vecka34\Nyckel_Ubuntu"
```

Navigerade till katalogen där SSH-nyckeln sparades.

```powershell
icacls "C:\Azure\Vecka34\Nyckel_Ubuntu\vm-novatrix-web_key.pem" /inheritance:r
```

Tog bort ärvda rättigheter från nyckelfilen.

```powershell
icacls .\vm-novatrix-web_key.pem /grant:r "${env:USERNAME}:R"
```

Gav endast mitt användarkonto läsbehörighet till nyckelfilen.

```powershell
ssh -i "C:\Azure\Vecka34\Nyckel_Ubuntu\vm-novatrix-web_key.pem" azureuser@135.225.105.195
```

Anslöt till den virtuella servern via SSH.

### Verifiering

SSH-anslutningen lyckades och jag fick tillgång till serverns Linux-terminal.

---

## Installation av Nginx

Efter anslutning till servern installerades webbservern Nginx.

### Kommandon

```bash
sudo apt update
```

Uppdaterade paketlistan från Ubuntus repos.

```bash
sudo apt install nginx -y
```

Installerade webbservern Nginx.

### Verifiering

För att verifiera installationen öppnades serverns publika IP-adress i en webbläsare.

Nginx standardsida visades, vilket bekräftade att webbservern var installerad och tillgänglig över nätverket.

---

## Driftsättning av webbplats

Efter att Nginx installerats skapades en egen startsida för Novatrix kundtjänst.

### Kommandon

```bash
sudo nano /var/www/html/index.html
```

Öppnade webbplatsens startsida för redigering.

HTML-koden klistrades därefter in och sparades.

```bash
sudo systemctl reload nginx
```

Laddade om Nginx för att läsa in den uppdaterade webbplatsen.

### Verifiering

Serverns publika IP-adress öppnades i en webbläsare.

Den nya webbplatsen för Novatrix visades med:

- Rubrik för kundtjänsten
- Information om företaget
- Formulär med fälten namn, e-post och meddelande

## Resultat
<img width="1502" height="1504" alt="novatirx kundtjänst html01" src="https://github.com/user-attachments/assets/21e2ff7d-d7e7-4bfa-aaa0-03a829fce83a" />
