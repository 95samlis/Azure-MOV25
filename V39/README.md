# V39 - Automation och integration


**Samuel Lissbro** 

## Syfte 

Syftet var att koppla samman Azure och Microsoft 365 med hjälp av Power Automate. När ett ärende skickas in via formuläret ska ett automatiskt flöde triggas som hämtar ärendedata och skickar en notifiering via e-post till ansvarig person i Microsoft 365-miljön. Detta skapar en automatiserad kedja från inskickat ärende till hantering av kundtjänst.

---

## Ändringar i backend.py

Backenden hade sedan tidigare stöd för att spara ärenden som JSON-filer i Azure Blob Storage. För att även kunna hantera bilagor utökades lösningen med stöd för filuppladdning.

### Mottagning av bilaga

Backenden uppdaterades för att läsa den uppladdade filen från formuläret:

```python
image = request.files.get("bild")
```

### Uppladdning till Azure Blob Storage

Om en fil finns bifogad skapas ett unikt filnamn baserat på ärendets ID och originalfilens namn.

```python
image_name = f"{entry_id}_{image.filename}"
```

Filen laddas därefter upp som en separat blob i containern `arenden`.

```python
image_blob.upload_blob(
    image.read(),
    overwrite=True
)
```

### Utökad JSON-struktur

JSON-filen kompletterades med information om den uppladdade bilden:

```json
{
  "image": image_url,
  "image_name": image_name
}
```

### Motivering

Power Automate behövde kunna hitta både ärendedata och tillhörande bilaga i Azure Blob Storage. Genom att spara både bildens URL och blobnamn kunde flödet senare hämta rätt fil och bifoga den i e-postmeddelandet som skickas till kundtjänst. Lösningen innebar att ärendedata och bilagor lagras separat men fortfarande kan kopplas samman via informationen som sparas i JSON-filen.

---

## Steg 1 – Trigger från Azure Blob Storage

Flödet startar med triggern **"När en blob läggs till eller ändras (enbart egenskaper) (V2)"**.

Triggern övervakar containern `arenden` i Azure Blob Storage. När backend-applikationen sparar en ny JSON-fil för ett inskickat ärende upptäcker Power Automate förändringen och startar flödet automatiskt.

### Konfiguration

För att Power Automate skulle kunna läsa från Azure Storage skapades en anslutning mot Storage Account `stnovatrixv388`.

```text
Storage Account: stnovatrixv388
Container: arenden
Trigger: När en blob läggs till eller ändras (enbart egenskaper) (V2)
```

Anslutningen autentiserades med Storage Account-nyckeln från Azure.

### Motivering

Genom att använda Azure Blob Storage som triggerpunkt skapas en automatisk koppling mellan webbapplikationen och Microsoft 365. När ett nytt ärende sparas i lagringskontot startas flödet utan manuell hantering.

---


