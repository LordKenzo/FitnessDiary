# Implementazione Sistema di Periodizzazione - FittyPal

**Data implementazione:** 20 Novembre 2025
**Branch:** `claude/model-training-periodization-01FRssc9ZsUoTurFjNbfG8Ju`

---

## 📋 Panoramica

Implementazione completa del sistema di periodizzazione dell'allenamento per FittyPal, che permette di organizzare i piani di allenamento su diversi orizzonti temporali (macrociclo, mesociclo, microciclo).

### Requisiti Funzionali Implementati

- ✅ **RF1** - Creazione piano di periodizzazione con parametri configurabili
- ✅ **RF2** - Generazione automatica dei periodi (mesocicli, microcicli, giorni)
- ✅ **RF3** - Settimana di scarico obbligatoria in ogni mesociclo
- ✅ **RF4** - Determinazione del contesto di allenamento corrente
- ✅ **RF5** - Integrazione con le schede (base - da completare)

---

## 🗂 Struttura Files Creati

### Modelli SwiftData (`FittyPal/Models/`)

| File | Descrizione |
|------|-------------|
| `PeriodizationModel.swift` | Enum per modelli (Linear, Block, Undulating), tipi fase, livelli carico, split type |
| `PeriodizationPlan.swift` | Piano principale (macrociclo) con date, modello, profili forza, frequenza |
| `Mesocycle.swift` | Mesociclo (3-6 settimane) con tipo fase, profilo focus, pattern carico/scarico |
| `Microcycle.swift` | Microciclo (settimana) con livello carico, fattori intensità/volume, progressione |
| `TrainingDay.swift` | Giornata singola con scheda associabile, tracking completamento |
| `PeriodizationTemplate.swift` | Template riutilizzabili per creare piani rapidamente |

**Modifica:** `WorkoutCard.swift` - aggiunto campo `splitType: SplitType?` per taggare le schede

### Servizi (`FittyPal/Services/`)

| File | Descrizione |
|------|-------------|
| `PeriodizationGenerator.swift` | Generazione automatica struttura vuota (mesocicli, microcicli, giorni) |
| `LoadProgressionCalculator.swift` | Calcolo progressione carichi, modulazione intensità/volume |
| `PeriodizationService.swift` | Logica business: contesto corrente (RF4), integrazione schede (RF5) |

### UI Views (`FittyPal/Views/Periodization/`)

| File | Descrizione |
|------|-------------|
| `PeriodizationPlanListView.swift` | Lista piani attivi/passati, entry point principale |
| `CreatePeriodizationPlanView.swift` | Form creazione piano (RF1) con tutti i parametri |
| `PeriodizationTimelineView.swift` | Timeline con istogrammi mesocicli navigabili |
| `MesocycleDetailView.swift` | Dettaglio mesociclo con istogrammi microcicli |
| `MicrocycleDetailView.swift` | Dettaglio settimana con lista giorni e schede associate |

---

## 🏗 Architettura Modello Dati

### Gerarchia
```
PeriodizationPlan (Macrociclo)
    ├── Mesocycle[] (3-6 settimane)
    │   └── Microcycle[] (settimane)
    │       └── TrainingDay[] (giorni)
    │           └── WorkoutCard? (scheda associata)
```

### Relazioni SwiftData
- **PeriodizationPlan → Mesocycle**: `@Relationship(deleteRule: .cascade)`
- **Mesocycle → Microcycle**: `@Relationship(deleteRule: .cascade)`
- **Microcycle → TrainingDay**: `@Relationship(deleteRule: .cascade)`
- **TrainingDay → WorkoutCard**: Opzionale, nullify
- **UserProfile/Client → PeriodizationPlan**: Opzionale per assignment

---

## 🔧 Funzionalità Principali

### 1. Modelli di Periodizzazione

#### Lineare
- Progressione: Accumulo → Intensificazione → Trasformazione (ciclica)
- Profilo forza: primario per tutti i mesocicli
- Ideale per: progressione graduale forza/ipertrofia

#### A Blocchi
- Ogni mesociclo focus su un profilo diverso
- Alterna profilo primario e secondario
- Ideale per: sviluppo qualità specifiche (es. blocco ipertrofia → blocco forza)

#### Ondulata
- Alterna fasi accumulo/intensificazione
- Variazione continua volume/intensità
- Ideale per: atleti avanzati, prevenzione plateau

### 2. Generazione Automatica (PeriodizationGenerator)

```swift
let generator = PeriodizationGenerator()
let plan = PeriodizationPlan(...)
let completePlan = generator.generateCompletePlan(plan)

// Genera:
// - Mesocicli (4 settimane default, configurabile)
// - Microcicli con pattern carico (3 load + 1 deload)
// - TrainingDays basati su frequenza settimanale
```

**Pattern giorni allenamento:**
- 1x/settimana: Lunedì
- 2x: Lun, Gio
- 3x: Lun, Mer, Ven
- 4x: Lun, Mar, Gio, Ven
- 5x: Lun-Ven
- 6x: Lun-Sab
- 7x: Tutti i giorni

### 3. Progressione Automatica Carichi (LoadProgressionCalculator)

**Fattori di modulazione:**
- **intensityFactor**: modula % 1RM (es. 0.7 scarico, 1.0 normale, 1.15 intensificazione)
- **volumeFactor**: modula serie/ripetizioni (es. 0.6 scarico, 1.0 normale, 1.2 accumulo)
- **loadProgressionPercentage**: incremento progressivo settimanale (default +2.5%)

**Esempio calcolo:**
```swift
Base: 80% 1RM, 4 serie x 6 reps
Settimana 1 (HIGH): 80% × 1.15 × (1 + 0.025×0) = 92% 1RM, 4 serie
Settimana 2 (HIGH): 80% × 1.15 × (1 + 0.025×1) = 94.3% 1RM, 4 serie
Settimana 3 (MEDIUM): 80% × 1.0 × (1 + 0.025×2) = 84% 1RM, 4 serie
Settimana 4 (LOW - scarico): 80% × 0.7 × (1 + 0.025×3) = 59.4% 1RM, 2 serie
```

### 4. Contesto Corrente (PeriodizationService - RF4)

```swift
let service = PeriodizationService(modelContext: modelContext)
let context = service.getCurrentTrainingContext(userId: userId, date: Date())

// Restituisce:
// - Piano attivo
// - Mesociclo corrente
// - Microciclo corrente
// - Giorno corrente (opzionale)
// - Focus strength profile
// - LoadLevel, intensityFactor, volumeFactor
```

### 5. Template Riutilizzabili

```swift
// Salvare piano come template
let template = service.savePlanAsTemplate(plan, name: "Forza 12 settimane")

// Creare piano da template
let newPlan = service.createPlanFromTemplate(template, startDate: Date())
```

---

## 🎨 UI/UX - Navigazione Timeline

### Flusso Utente
```
PeriodizationPlanListView (lista piani)
    │
    ├─ Tap su piano → PeriodizationTimelineView
    │                     │
    │                     ├─ Istogrammi mesocicli (colorati per tipo fase)
    │                     │
    │                     └─ Tap su mesociclo → MesocycleDetailView
    │                                              │
    │                                              ├─ Istogrammi microcicli (colorati per load level)
    │                                              │
    │                                              └─ Tap su microciclo → MicrocycleDetailView
    │                                                                         │
    │                                                                         └─ Lista giorni settimana
    │                                                                             └─ Associa WorkoutCard
    │
    └─ "+" → CreatePeriodizationPlanView (RF1)
             └─ Genera piano completo automaticamente
```

### Design Istogrammi

**Mesocicli:**
- Barra colorata per PhaseType (blu accumulo, arancio intensificazione, viola trasformazione, verde scarico)
- Progress overlay (quanto completato)
- Info: durata, profilo focus, settimane carico/scarico
- Indicatore "In corso" se attivo

**Microcicli:**
- Barra colorata per LoadLevel (rosso HIGH, arancio MEDIUM, verde LOW)
- Fattori I (intensità) e V (volume) visibili
- Completamento allenamenti (es. 2/3)
- Date range settimana

**Giorni:**
- Card giornaliera con nome giorno e data
- Stato: completato ✓, riposo, da fare, perso
- Scheda associata (nome, split type, statistiche)
- Button "Associa scheda" se vuoto

---

## 🔌 Integrazione con App Esistente

### 1. Modelli Registrati (FittyPalApp.swift)

Aggiunto al `modelContainer`:
```swift
PeriodizationPlan.self,
Mesocycle.self,
Microcycle.self,
TrainingDay.self,
PeriodizationTemplate.self
```

### 2. WorkoutCard Esteso

Aggiunto campo:
```swift
var splitType: SplitType? // Full Body, Upper/Lower, Push/Pull/Legs, etc.
```

### 3. Entry Point UI

Aggiungi `PeriodizationPlanListView` al menu principale dell'app (es. TabView o NavigationLink).

---

## 📝 TODO - Prossimi Step

### Priorità Alta
1. **Integrazione menu principale**: aggiungere tab/link a `PeriodizationPlanListView`
2. **Workout Picker**: implementare picker per associare WorkoutCard ai TrainingDay
3. **Modulazione schede**: completare RF5 con clonazione e modifica WorkoutSet in base a intensityFactor/volumeFactor
4. **Gestione 1RM**: integrare calcolo carico kg da OneRepMax records

### Priorità Media
5. **Template predefiniti**: creare libreria template comuni (es. "Starting Strength 12w", "Hypertrophy Block 8w")
6. **Export/Import**: esportare piani come JSON/template condivisibili
7. **Statistiche**: grafici progressione carico, volume totale per mesociclo
8. **Notifiche**: reminder allenamenti pianificati
9. **Auto-adjust**: adattamento automatico piano in base a RPE/performance

### Priorità Bassa
10. **Condivisione trainer-cliente**: flusso completo assignment con notifiche
11. **Deload intelligente**: calcolo automatico necessità scarico da RPE/volume accumulato
12. **AI suggestions**: suggerimenti piano ottimale basato su storico e obiettivi

---

## 🧪 Testing

### Test Manuali Consigliati

1. **Creazione piano:**
   - Crea piano lineare 12 settimane, 4x/settimana
   - Verifica generazione automatica mesocicli/microcicli/giorni
   - Controlla che ogni mesociclo abbia 1 settimana scarico (RF3)

2. **Navigazione timeline:**
   - Apri piano → timeline mesocicli
   - Tap su mesociclo → verifica microcicli
   - Tap su microciclo → verifica giorni

3. **Contesto corrente (RF4):**
   - Crea piano attivo che include oggi
   - Verifica che `getCurrentTrainingContext()` restituisca dati corretti

4. **Progressione carichi:**
   - Verifica calcolo `calculateProgressiveLoad()` per settimana 1, 2, 3, 4 (scarico)
   - Controlla che intensityFactor/volumeFactor siano applicati correttamente

### Test Automatici (da implementare)

```swift
@Test func testPlanGeneration() {
    let plan = PeriodizationPlan(...)
    let generator = PeriodizationGenerator()
    let result = generator.generateCompletePlan(plan)

    #expect(result.mesocycles.count > 0)
    #expect(result.mesocycles.allSatisfy { $0.hasDeloadWeek }) // RF3
}

@Test func testLoadProgression() {
    let calculator = LoadProgressionCalculator()
    let microcycle = Microcycle(loadLevel: .low, intensityFactor: 0.7)
    let result = calculator.calculateProgressiveLoad(baseLoad: 100, for: microcycle, in: mesocycle)

    #expect(result == 70.0) // 100 × 0.7
}
```

---

## 📚 Documentazione Tecnica

### Enum Reference

| Enum | Valori | Utilizzo |
|------|--------|----------|
| `PeriodizationModel` | linear, block, undulating | Tipo di periodizzazione |
| `PhaseType` | accumulation, intensification, transformation, deload | Tipo fase mesociclo |
| `LoadLevel` | high, medium, low | Livello carico settimana |
| `SplitType` | fullBody, upperLower, pushPullLegs, bodyPartSplit, custom | Tipo split scheda |

### Key Properties

**Microcycle (RF3, RF4, RF5):**
```swift
var loadLevel: LoadLevel               // HIGH, MEDIUM, LOW
var intensityFactor: Double            // 0.5-1.2 (modulazione intensità)
var volumeFactor: Double               // 0.5-1.2 (modulazione volume)
var loadProgressionPercentage: Double  // Incremento settimanale (default 2.5%)
```

**TrainingContext (RF4):**
```swift
struct TrainingContext {
    let plan: PeriodizationPlan
    let mesocycle: Mesocycle
    let microcycle: Microcycle
    let focusStrengthProfile: StrengthExpressionType
    let loadLevel: LoadLevel
    let intensityFactor: Double
    let volumeFactor: Double
}
```

---

## 🎯 Obiettivi Raggiunti

- ✅ Modello dati completo e scalabile
- ✅ Generazione automatica struttura periodizzazione
- ✅ UI navigabile con istogrammi visivi
- ✅ Sistema progressione carichi automatico
- ✅ Template riutilizzabili
- ✅ Integrazione trainer-clienti (base)
- ✅ Settimane scarico obbligatorie (RF3)
- ✅ Contesto corrente dinamico (RF4)

## 🔮 Visione Futura

Il sistema di periodizzazione è la base per:
- **Adaptive Training**: piano che si adatta automaticamente ai risultati
- **AI Coach**: suggerimenti intelligenti basati su ML
- **Social**: condivisione piani nella community
- **Analytics**: analisi progressi long-term
- **Wearable Integration**: adattamento da HRV, sonno, stress

---

## 👥 Contributori

- **Claude AI** - Design e implementazione completa
- **LordKenzo** - Product owner e requirements

---

*Per domande o supporto, aprire issue su GitHub o contattare il team di sviluppo.*
