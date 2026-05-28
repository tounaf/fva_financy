# fva_financy

Application Flutter de gestion de comptage des offrandes et des dépenses pour les églises.

## Contexte du Projet

**fva_financy** est une application mobile conçue pour simplifier et digitaliser le processus de comptage financier hebdomadaire (Sabbat) au sein des églises. Elle permet aux trésoriers de saisir les quantités de billets par type d'offrande, de gérer les dépenses courantes et de synchroniser ces données avec un système centralisé pour un meilleur suivi et une transparence accrue.

## Fonctionnalités Clés

- **Comptage par billets** : Interface intuitive pour saisir le nombre de billets de chaque valeur.
- **Gestion des catégories** : Séparation automatique entre les différents types d'offrandes (F, A, Autres).
- **Suivi des dépenses** : Enregistrement des sorties de fonds.
- **Synchronisation API** : Envoi des données vers un serveur distant (Symfony).
- **Validation avec preuve** : Capture photo du bordereau signé avant la clôture.
- **Mises à jour automatiques** : Intégration avec les Releases GitHub pour faciliter les mises à jour.

## Documentation Détaillée

Pour plus d'informations sur le fonctionnement technique et métier de l'application, veuillez consulter les documents suivants :

1. [**Architecture**](docs/architecture.md) : Structure du code, flux de données et navigation.
2. [**Technologies & Plugins**](docs/technologies.md) : Liste des outils et bibliothèques utilisés.
3. [**Logique Métier**](docs/business.md) : Détails sur les calculs, les catégories d'offrandes et le processus de validation.

## Installation

### Prérequis
- Flutter SDK (^3.5.3)
- Dart SDK

### Lancement
```bash
flutter pub get
flutter run
```

---

## Ressources Flutter

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Online documentation](https://docs.flutter.dev/)
