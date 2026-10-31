/// Numéro d'étape (1 à 5) du suivi d'un colis, d'après son libellé français.
int parcelStep(String? status) => switch (status) {
      'Livré' => 5,
      'Arrivé au Togo' || 'En livraison' => 4,
      'En transit' => 2,
      'Collecté' || 'Collecté aux États-Unis' => 2,
      _ => 1,
    };
