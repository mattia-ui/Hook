# Hook

Il tuo armadio virtuale per iPhone: fotografi i capi, li organizzi per categoria e crei i tuoi outfit.

## Requisiti

- Xcode 16 o successivo
- iOS 17 o successivo (solo iPhone)

## Come aprirlo

1. Apri `Hook.xcodeproj` in Xcode.
2. In *Signing & Capabilities* scegli il tuo team (serve solo per installarla su un iPhone vero).
3. Avvia lo schema **Hook** su un simulatore o sul tuo iPhone.

I test girano con `⌘U` e a ogni push su GitHub (vedi `.github/workflows/ios.yml`).

## Struttura

| Cartella | Contenuto |
| --- | --- |
| `Hook/App` | Avvio dell'app e tab principali |
| `Hook/Models` | Modelli SwiftData `Capo` e `Outfit`, categorie |
| `Hook/Features` | Schermate: Armadio, Aggiungi capo, Outfit |
| `Hook/Components` | Viste riutilizzabili |
| `Hook/Services` | Elaborazione immagini (e, dalla fase 2, scontorno e riconoscimento) |
| `HookTests` | Test con Swift Testing |
| `legacy/HangMe` | La versione UIKit del 2020, solo come riferimento: non si compila più così com'è |

## Roadmap

1. Fondamenta SwiftUI + SwiftData ✅
2. Scontorno automatico con Vision, colore dominante, riconoscimento categoria
3. Editor outfit, nuovo design, onboarding, localizzazione
4. Pubblicazione: privacy, App Store, TestFlight
