# Guichet+ Agent Mobile

Application Flutter pour iOS et Android permettant aux agents de guichet d'utiliser le panneau Guichet+ depuis un smartphone ou une tablette.

## Fonctionnalités

- authentification avec les comptes agents Guichet+ existants ;
- appel, rappel, transfert et clôture des tickets via le panneau serveur ;
- file d'attente en temps réel et conservation de session ;
- interface responsive téléphone/tablette, portrait/paysage ;
- prise en charge de la caméra pour les QR codes ;
- reprise automatique après retour du réseau ;
- navigation limitée au domaine sécurisé `gplus.digitalfactory.sn`.

## Vérification

```bash
flutter analyze
flutter build apk --debug
flutter build ios --simulator --debug
```

## Identifiants

- Android : `sn.digitalfactory.guichetplus.agent`
- iOS : `sn.digitalfactory.guichetplus.agent`

La publication Play Store et App Store nécessite les certificats et profils de distribution de Digital Factory.
