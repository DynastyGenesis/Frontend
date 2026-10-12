class QuoteService {
  Future<String> requestQuote(
      {required String from,
      required String to,
      required double weight,
      required String service,
      required String direction}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return 'Votre demande $direction a été préparée. Un conseiller barrelGo pourra vous confirmer le tarif.';
  }
}
