class WalletModel {
  final int solde;
  final List<WalletTransaction> transactions;

  WalletModel({required this.solde, required this.transactions});

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    // 1. CORRECTION SOLDE : On parse en double d'abord pour gérer "700.00"
    double soldeDouble = double.tryParse(json['solde'].toString()) ?? 0.0;
    int soldeFinal = soldeDouble.toInt(); // On convertit 700.00 en 700

    // 2. CORRECTION TRANSACTIONS
    List<WalletTransaction> transacList = [];

    if (json['transactions'] != null) {
      var rawTransacs = json['transactions'];
      List<dynamic> listData = [];

      // Gestion de la pagination Laravel (data wrapper)
      if (rawTransacs is Map<String, dynamic> && rawTransacs.containsKey('data')) {
        listData = rawTransacs['data'];
      } else if (rawTransacs is List) {
        listData = rawTransacs;
      }

      transacList = listData
          .map((e) => WalletTransaction.fromJson(e))
          .toList();
    }

    return WalletModel(
      solde: soldeFinal,
      transactions: transacList,
    );
  }
}

class WalletTransaction {
  final String titre;
  final String montant;
  final String date;
  final bool isCredit;

  WalletTransaction({
    required this.titre,
    required this.montant,
    required this.date,
    required this.isCredit,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    // CORRECTION ICI SELON TES LOGS :
    // amount: 100.00
    // description: Rechargement...
    // type: credit / debit

    return WalletTransaction(
      titre: json['description'] ?? "Transaction", // <-- C'était 'description' dans les logs
      montant: json['amount'].toString(),          // <-- C'était 'amount' dans les logs
      date: json['created_at'] ?? DateTime.now().toString(),
      isCredit: json['type'] == 'credit',          // <-- Simple et efficace
    );
  }
}