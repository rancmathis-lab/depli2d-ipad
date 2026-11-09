# Dépli 2D — dessin de dépliés d'emballage pour iPad

Application iPadOS native (SwiftUI, iOS 17+) pour tracer des dépliés 2D
(*dielines*) de packaging : canvas vectoriel en millimètres, calques
coupe / pli / fond perdu, gabarit de carton ECMA 0201 paramétrable et export
PDF vectoriel / PNG.

## Fonctionnalités

- **Canvas en millimètres** (page A3 420 × 594 mm par défaut), zoom au
  pincement ancré sur le centre, déplacement au doigt.
- **Outils** : sélection / déplacement, ligne, rectangle, tracé libre
  (compatible Apple Pencil), main (déplacement de la vue).
- **Types de traits** : coupe (rouge, plein), pli / rainure (bleu, tireté),
  fond perdu (gris), annotation (orange).
- **Grille 10 mm + règles** graduées en mm, aimantation au millimètre
  (désactivable via l'aimant).
- **Gabarit ECMA 0201** (carton fendu à rabats) généré à partir de
  L × l × H, avec onglet de collage biseauté, jeu des rabats, contour en
  coupe et rainures en plis.
- **Édition** : annuler / rétablir, dupliquer, supprimer, changer le type de
  trait, repositionner précisément via les coordonnées X / Y du centroïde.
- **Export** : PDF vectoriel (une page = la feuille, traits à épaisseur
  constante en points, tirets à l'échelle) et PNG haute résolution (3×),
  via la feuille de partage iPad (AirDrop, Mail, Fichiers…).

## Lancer le projet

1. Ouvrir `Depli2D.xcodeproj` avec Xcode 15+.
2. Choisir une cible iPad (ou le simulateur iPad), puis lancer avec **Cmd+R**.
3. Régénérer le projet Xcode si besoin : `python3 Scripts/make_xcodeproj.py`.

## Structure

```
Depli2D/
├── Depli2DApp.swift            point d'entrée (@main)
├── SceneDelegate.swift
├── Info.plist
├── Models/
│   ├── ElementKind.swift       types de traits (couleurs, tirets)
│   ├── DelineElement.swift     polyligne typée, en mm, espace document
│   ├── DielineDocument.swift   page + liste d'éléments
│   └── PackagingTemplates.swift gabarit ECMA 0201 (contour + rainures)
├── ViewModels/
│   └── EditorViewModel.swift   état, gestes (drag / pincement), historique
├── Views/
│   ├── ContentView.swift       barre d'outils + feuilles
│   ├── CanvasView.swift        rendu Canvas 2D (grille, règles, éléments)
│   ├── InspectorBar.swift      édition de la sélection (type, X/Y, actions)
│   ├── TemplateSheet.swift     réglages du gabarit 0201 + aperçu
│   ├── DielineShape.swift      Shape réutilisable (aperçu / export)
│   ├── DocumentPreview.swift   rendu SwiftUI pour l'export PNG
│   └── ActivityView.swift      feuille de partage UIActivityViewController
└── Utils/
    ├── Geometry.swift          snap, hit-test, distance point/segment
    └── PDFExport.swift         export PDF vectoriel + PNG
Scripts/
└── make_xcodeproj.py           génère Depli2D.xcodeproj (sans Xcode)
```

## Conventions

- Les coordonnées du document sont exprimées en **millimètres**, origine en
  haut à gauche de la page ; la vue applique `échelle × zoom + décalage`.
- Le PDF est vectoriel : 1 mm = 72 / 25,4 pt, axe Y inversé pour Core
  Graphics, épaisseurs de trait conservées en points.

## Pistes d'évolution

- Autres codes ECMA (0427, 0201 avec poignée, fonds automatiques…)
- Perforations, rainures partielles, cotes et cotes automatiques
- Enregistrement / partage de documents (JSON `Codable` déjà en place)
- Export SVG / DXF pour les tables de découpe
