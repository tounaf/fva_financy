# Technologies et Plugins

Ce document liste les technologies et bibliothèques utilisées dans le projet.

## Stack Technologique

- **Framework** : [Flutter](https://flutter.dev/) (SDK ^3.5.3)
- **Langage** : [Dart](https://dart.dev/)
- **Backend (API)** : PHP / Symfony (distant)

## Plugins Principaux

| Plugin | Usage |
| :--- | :--- |
| `http` | Communication avec l'API REST (utilisé via `ApiService`). |
| `shared_preferences` | Stockage local persistant des données de comptage et configuration. |
| `intl` | Formatage des dates et des devises (Ariary). |
| `google_fonts` | Utilisation de polices personnalisées (ex: Poppins). |
| `fl_chart` | Affichage des graphiques de répartition des offrandes. |
| `image_picker` | Capture de photos des bordereaux pour la validation du Sabbat. |
| `package_info_plus` | Récupération de la version de l'application. |
| `ota_update` | Gestion de la mise à jour automatique de l'APK via GitHub. |
| `flutter_launcher_icons` | Génération des icônes de l'application. |

## Mise à jour Automatique

L'application intègre un mécanisme de vérification de version via l'API GitHub. Si une nouvelle version est disponible, l'utilisateur est invité à télécharger et installer l'APK directement depuis l'application.

---

**Navigation Documentation :**
- [Sommaire (README)](../README.md)
- [Architecture](architecture.md)
- [Logique Business](business.md)
