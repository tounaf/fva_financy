# Logique Métier (Business Logic)

Ce document explique le fonctionnement métier de l'application **fva_financy**.

## 1. Sélection de la Fiangonana (Église)

Au premier lancement, l'utilisateur doit entrer un code unique propre à son église.
- La validation se fait via l'API.
- Une fois validée, l'ID et le nom de l'église sont stockés localement.
- Une valeur de "caution" par défaut est également récupérée.

## 2. Comptage des Offrandes

L'application permet de compter différents types d'offrandes (R1, R2, Manga, Mena, Mavo, etc.).
- Chaque type d'offrande appartient à une catégorie : **Vola miditra F**, **Vola miditra A** ou **Autre**.
- L'utilisateur saisit la quantité pour chaque dénomination de billet (20000, 10000, 5000, etc.).
- Les totaux sont calculés en temps réel.

## 3. Gestion des Dépenses

L'utilisateur peut enregistrer les dépenses effectuées durant le Sabbat.
- Chaque dépense a un libellé et un montant.
- Le total des dépenses est déduit de certains calculs de solde.

## 4. Calculs et Solde

- **Ambimbola teo aloha** : Solde restant du Sabbat précédent.
- **Vola miditra androany** : Somme de toutes les offrandes du jour.
- **Vola sisa eo antanana** : (Ambimbola teo aloha + Vola miditra androany) - Vola nivoaka.
- **Net à verser** : Calculé spécifiquement en fonction de la catégorie "Vola miditra A" et de la caution.

## 5. Synchronisation et Finalisation

- **Synchronisation** : Chaque type d'offrande et le lot de dépenses peuvent être envoyés individuellement à l'API.
- **Finalisation du Sabbat** :
  - L'utilisateur doit prendre une photo du bordereau signé.
  - Toutes les données financières récapitulatives sont envoyées à l'API pour validation finale par l'administration.

---

**Navigation Documentation :**
- [Sommaire (README)](../README.md)
- [Architecture](architecture.md)
- [Technologies & Plugins](technologies.md)
