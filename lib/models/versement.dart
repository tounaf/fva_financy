class Versement {
  final String type; // 'CASH' ou 'MOBILE_MONEY'
  final double montant;
  final String reference;
  final double frais;
  final int sabbatValidationId;

  Versement({
    required this.type,
    required this.montant,
    required this.reference,
    required this.frais,
    required this.sabbatValidationId,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'montant': montant,
    'reference': reference,
    'frais': frais,
    'sabbatValidation': '/api/sabbat_validations/$sabbatValidationId',
  };
}