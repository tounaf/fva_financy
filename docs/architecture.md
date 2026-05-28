# Architecture du Projet

Ce document détaille l'architecture logicielle de l'application **fva_financy**.

## Structure des Dossiers

L'application est structurée de la manière suivante dans le répertoire `lib/` :

- **`models/`** : Contient les modèles de données et la logique métier associée.
  - `offering_data.dart` : Gère l'état global des offrandes, le calcul des totaux et la persistance locale via SharedPreferences.
  - `expense.dart` : Modèle pour les dépenses.
- **`screens/`** : Contient les différents écrans de l'application.
  - `fiangonana_selection_screen.dart` : Écran initial de sélection/connexion de l'église.
  - `offering_counter_screen.dart` : Écran principal avec les onglets de comptage.
  - `sync_screen.dart` : Gère la synchronisation des données avec le serveur distant.
  - `dashboard/` : Sous-dossier pour les écrans de visualisation (graphiques).
- **`widgets/`** : Composants UI réutilisables.
  - `offering_tab.dart` : Composant pour chaque onglet d'offrande.
  - `auto_update_dialog.dart` : Dialogue pour les mises à jour automatiques.
- **`services/`** : Services pour la communication externe.
  - `api_service.dart` : Centralise tous les appels vers l'API REST.
- **`utils/`** : Constantes et utilitaires.
  - `constants.dart` : Définit les types de billets, les types d'offrandes et leurs catégories.
  - `config.dart` : Configuration de l'environnement (ex: URL de l'API).

## Flux de Données

1. **Persistance Locale** : L'application utilise `shared_preferences` pour stocker les comptages en cours, l'ID de l'église sélectionnée et d'autres paramètres afin de ne pas perdre de données en cas de fermeture de l'application.
2. **Gestion d'État** : L'état est principalement géré via des `StatefulWidget` et la classe `OfferingData` qui centralise les calculs.
3. **Communication API** : L'application communique avec une API REST (Symfony) via un service centralisé (`ApiService`). Ce service utilise une configuration globale (`AppConfig`) permettant de changer facilement l'URL de base selon l'environnement (développement ou production).

## Navigation

Le flux de navigation principal est :
`Main` -> `FiangonanaSelectionScreen` (si non connecté) -> `OfferingCounterScreen` (Dashboard) -> `SyncScreen` / `SabbatAverserScreen`.

---

**Navigation Documentation :**
- [Sommaire (README)](../README.md)
- [Technologies & Plugins](technologies.md)
- [Logique Business](business.md)
