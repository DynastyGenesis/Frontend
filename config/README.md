# Configuration de lancement

Copier `env.example.json` en `env.json` (ignoré par git), remplir les valeurs,
puis lancer :

```text
flutter run --dart-define-from-file=config/env.json
```

Dans VS Code, les profils « BarelGo (backend) » de `.vscode/launch.json` font la même chose.

- `API_BASE_URL` : `http://10.0.2.2:8000/api/v1` depuis l'émulateur Android,
  `http://localhost:8000/api/v1` sur le web ou iOS (simulateur).
- Les trois premières valeurs sont obligatoires pour démarrer l'application.
- `STRIPE_PUBLISHABLE_KEY` (`pk_test_...`) : facultative ; sans elle, le paiement reste masqué.
- `FIREBASE_*` : facultatives ; sans elles, pas de notifications push.

Uniquement des clés **publiques**. Aucune clé secrète (Supabase `sb_secret_...`,
Stripe `sk_...`, compte de service Firebase) ne doit figurer ici.

En web, ajouter l'adresse du site (ex. `http://localhost:5000`) à
`CORS_ALLOWED_ORIGINS` dans le `.env` du backend, et lancer avec
`--web-port=5000` pour qu'elle reste fixe.
