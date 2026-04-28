import 'dart:io';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'package:car225/core/theme/app_colors.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../models/sale_model.dart';
import '../providers/hostess_sales_provider.dart';


import 'package:screenshot/screenshot.dart'; // <--- AJOUTE ÇA
import 'package:qr_flutter/qr_flutter.dart'; // <--- AJOUTE ÇA (si besoin plus tard)

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:image/image.dart' as img; // <--- AJOUTE ÇA
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'dart:convert'; // <--- AJOUTE ÇA TOUT EN HAUT






class HostessHistoryScreen extends StatefulWidget {
  const HostessHistoryScreen({super.key});

  @override
  State<HostessHistoryScreen> createState() => _HostessHistoryScreenState();
}

class _HostessHistoryScreenState extends State<HostessHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;


// --- NOUVELLES VARIABLES POUR L'IMPRIMANTE ---
  List<BluetoothInfo> _devices = []; // Le nouveau modèle d'appareil
  String? _selectedDeviceMac; // On sauvegarde juste l'adresse MAC
  bool _isPrinterConnected = false;

// 🟢 (Garde le ScreenshotController au cas où on repasse en mode image plus tard)
  ScreenshotController screenshotController = ScreenshotController();
  @override
  void initState() {
    super.initState();
    // Initialiser l'état de l'imprimante
    _initPrinter();
    // Charge les ventes dès l'ouverture de l'écran.
    // Utilisation de addPostFrameCallback car on ne peut pas appeler un Provider dans un initState directement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter();
    });
  }

  // Vérifie si on est déjà connecté au lancement
  Future<void> _initPrinter() async {
    // Nouvelle méthode pour vérifier le statut avec print_bluetooth_thermal
    bool isConnected = await PrintBluetoothThermal.connectionStatus;

    if (mounted) {
      setState(() {
        _isPrinterConnected = isConnected; // Plus besoin du "?? false", la réponse est toujours un vrai booléen
      });
    }
  }


  Future<void> _applyFilter() async {
    FocusScope.of(context).unfocus();

    // 1. Récupération du Provider
    final provider = context.read<HostessSalesProvider>();

    try {
      // 2. Instanciation du Repository exactement comme dans ton ChangePassword
      final repository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // 3. On passe le repository au Provider pour qu'il fasse l'appel
      await provider.fetchSalesHistory(
        repository,
        startDate: _startDate,
        endDate: _endDate,
      );

      // 4. Si une erreur est interceptée par le Provider, on l'affiche
      if (mounted && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Sécurité supplémentaire au cas où l'instanciation elle-même échoue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    // On relance la recherche sans filtre
    _applyFilter();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }


  Future<bool> _requestBluetoothPermissions() async {
    // On demande les permissions de localisation (nécessaire pour scanner le BT sur Android)
    // Et les nouvelles permissions Android 12+ (Scan et Connect)
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    // On vérifie si tout est accordé
    bool isGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted) {
        isGranted = false;
      }
    });

    if (!isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Les permissions Bluetooth et Localisation sont requises pour imprimer."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return false;
    }

    return true;
  }


  Future<void> _printTicket(HostessSaleModel sale) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      if (_selectedDeviceMac == null) {
        // 🟢 Remplacement du SnackBar par la top notification (Erreur)
        _showTopNotification("Veuillez connecter une imprimante Bluetooth.", isError: true);
        return;
      }
      bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: _selectedDeviceMac!);
      if (!connected) {
        // 🟢 Ajout d'une notification si la connexion échoue
        _showTopNotification("Échec de la connexion à l'imprimante.", isError: true);
        return;
      }
    }

    try {
      // 🟢 Remplacement du SnackBar par la top notification (Succès/Info)
      _showTopNotification("Impression du billet en cours...", isError: false);

      // Nettoyage de la flèche pour éviter les bugs d'encodage
      String trajetNettoye = sale.trajet.replaceAll('→', '->');

      // 🟢 CONSTRUCTION DU BILLET EN TSPL
      String tsplCommand =
          "SIZE 50 mm, 80 mm\r\n" +  // Taille du papier
              "GAP 0 mm, 0 mm\r\n" +     // Pas d'espace entre les étiquettes
              "DIRECTION 1\r\n" +
              "CLS\r\n" +                // Nettoie la mémoire

              // --- EN-TÊTE ---
              "TEXT 100,20,\"4\",0,1,1,\"CAR225\"\r\n" +
              "TEXT 60,70,\"3\",0,1,1,\"Billet de transport\"\r\n" +

              // --- LIGNE DE SÉPARATION ---
              "BAR 20,110,340,3\r\n" +

              // --- INFOS PASSAGER ---
              "TEXT 20,140,\"2\",0,1,1,\"Ticket   : ${sale.ticketNo}\"\r\n" +
              "TEXT 20,180,\"2\",0,1,1,\"Passager : ${sale.passager}\"\r\n" +

              // --- TRAJET ---
              "TEXT 130,230,\"3\",0,1,1,\"TRAJET\"\r\n" +
              "TEXT 20,270,\"2\",0,1,1,\"${trajetNettoye}\"\r\n" +

              // --- QR CODE ---
              "QRCODE 100,330,H,5,A,0,\"${sale.reference}\"\r\n" +

              // --- PIED DE PAGE ---
              "TEXT 90,550,\"3\",0,1,1,\"Bon voyage !\"\r\n" +

              // --- IMPRESSION ---
              "PRINT 1\r\n";

      // 🟢 ENCODAGE MAGIQUE
      List<int> bytes = utf8.encode(tsplCommand).toList();

      // Envoi à l'imprimante
      bool result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        print("✅ [SUCCÈS] Billet imprimé avec succès !");
        // Optionnel : Tu peux rajouter une notification de succès finale
        // _showTopNotification("Billet imprimé avec succès !", isError: false);
      } else {
        print("❌ [ÉCHEC] Erreur lors de l'envoi.");
        _showTopNotification("Erreur lors de l'impression du billet.", isError: true);
      }

    } catch (e) {
      print("❌ [ERREUR] $e");
      _showTopNotification("Une erreur inattendue est survenue.", isError: true);
    }
  }


  void _showTopNotification(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.redAccent : Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () { if(mounted) overlayEntry.remove(); });
  }




  /*Future<void> _printTicket(HostessSaleModel sale) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      if (_selectedDeviceMac == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez connecter l'imprimante.")));
        return;
      }
      bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: _selectedDeviceMac!);
      if (!connected) return;
    }

    try {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Impression en cours...")));

      // Nettoyage de la flèche pour éviter les bugs d'encodage
      String trajetNettoye = sale.trajet.replaceAll('→', '->');

      // 🟢 CONSTRUCTION DU BILLET EN TSPL
      // La syntaxe TEXT : TEXT X, Y, "Police", Rotation, MultiplicateurX, MultiplicateurY, "Texte"
      // La syntaxe QRCODE : QRCODE X, Y, NiveauErreur, TailleCellule, Mode, Rotation, "Données"

      String tsplCommand =
          "SIZE 50 mm, 80 mm\r\n" +  // Taille du papier (ajuste la hauteur 80mm si le billet est coupé)
              "GAP 0 mm, 0 mm\r\n" +     // Pas d'espace entre les étiquettes (papier continu)
              "DIRECTION 1\r\n" +
              "CLS\r\n" +                // Nettoie la mémoire

              // --- EN-TÊTE ---
              "TEXT 100,20,\"4\",0,1,1,\"CAR225\"\r\n" +
              "TEXT 60,70,\"3\",0,1,1,\"Billet de transport\"\r\n" +

              // --- LIGNE DE SÉPARATION ---
              "BAR 20,110,340,3\r\n" +   // Dessine une ligne noire (X, Y, Largeur, Épaisseur)

              // --- INFOS PASSAGER ---
              "TEXT 20,140,\"2\",0,1,1,\"Ticket   : ${sale.ticketNo}\"\r\n" +
              "TEXT 20,180,\"2\",0,1,1,\"Passager : ${sale.passager}\"\r\n" +

              // --- TRAJET ---
              "TEXT 130,230,\"3\",0,1,1,\"TRAJET\"\r\n" +
              "TEXT 20,270,\"2\",0,1,1,\"${trajetNettoye}\"\r\n" +

              // --- QR CODE ---
              // X=100, Y=330, Marge d'erreur H (High), Taille 5
              "QRCODE 100,330,H,5,A,0,\"${sale.reference}\"\r\n" +

              // --- PIED DE PAGE ---
              "TEXT 90,550,\"3\",0,1,1,\"Bon voyage !\"\r\n" +

              // --- IMPRESSION ---
              "PRINT 1\r\n";

      // 🟢 ENCODAGE MAGIQUE
      List<int> bytes = utf8.encode(tsplCommand).toList();

      // Envoi à l'imprimante
      bool result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        print("✅ [SUCCÈS] Billet imprimé avec succès !");
      } else {
        print("❌ [ÉCHEC] Erreur lors de l'envoi.");
      }

    } catch (e) {
      print("❌ [ERREUR] $e");
    }
  }*/

  /*Future<void> _printTicket(HostessSaleModel sale) async {
    print("🚀 [TEST BLE] Vérification de la connexion...");

    bool isConnected = await PrintBluetoothThermal.connectionStatus;

    if (!isConnected) {
      if (_selectedDeviceMac == null) {
        print("❌ Aucune imprimante sélectionnée !");
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez connecter l'imprimante.")));
        return;
      }

      print("🔌 Tentative de reconnexion auto...");
      bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: _selectedDeviceMac!);
      if (!connected) {
        print("❌ Échec de la reconnexion !");
        return;
      }
    }

    try {
      print("🖨️ [TEST] Envoi des données TSPL (Langage Étiquette)...");

      // On écrit les commandes exactes de ton imprimante d'étiquettes
      String tsplCommand =
          "SIZE 40 mm, 50 mm\r\n" +
              "GAP 0 mm, 0 mm\r\n" +
              "DIRECTION 1\r\n" +
              "CLS\r\n" +
              "TEXT 10,10,\"4\",0,1,1,\"--- CAR225 ---\"\r\n" +
              "TEXT 10,60,\"4\",0,1,1,\"SI TU LIS CA\"\r\n" +
              "TEXT 10,110,\"4\",0,1,1,\"C'EST GAGNE !\"\r\n" +
              "PRINT 1\r\n";

      // 🟢 On encode le texte TSPL en liste de Bytes via utf8
      //List<int> bytes = utf8.encode(tsplCommand);

      // 🟢 On encode le texte TSPL en liste de Bytes via utf8 ET on convertit en liste classique
      List<int> bytes = utf8.encode(tsplCommand).toList();

      // On envoie !
      bool result = await PrintBluetoothThermal.writeBytes(bytes);

      if (result) {
        print("✅ [SUCCÈS] Le tuyau n'a pas cassé ! L'imprimante a accepté les données !");
      } else {
        print("❌ [ÉCHEC] Les données ont été refusées.");
      }

    } catch (e) {
      print("❌ [ERREUR] $e");
    }
  }*/


  // 📸 Prend une capture invisible du billet et le convertit pour l'imprimante
  Future<Uint8List> _generateTicketImage(HostessSaleModel sale) async {
    print("📸 [CAPTURING] Début de la capture invisible du billet...");

    // On capture le widget dessiné dans l'étape 3
    final imageBytes = await screenshotController.captureFromWidget(
      _buildTicketWidget(sale),
      delay: const Duration(milliseconds: 100), // Laisser un petit temps pour le QR Code
      pixelRatio: 2.0, // Bonne résolution
    );

    print("✅ [CAPTURING] Capture terminée ! Taille image : ${imageBytes.length} bytes");
    return imageBytes;
  }


  @override
  Widget build(BuildContext context) {
    // 1. On récupère les données de l'API via le Provider
    final salesProvider = context.watch<HostessSalesProvider>();
    final isLoading = salesProvider.isLoading;
    final List<HostessSaleModel> allSales = salesProvider.sales;

    // 2. 🟢 ON FILTRE LOCALEMENT LES DONNÉES ICI
    List<HostessSaleModel> filtered = allSales.where((sale) {
      // S'il n'y a aucun filtre, on affiche tout
      if (_startDate == null && _endDate == null) return true;

      try {
        // Attention : Adapte le format 'yyyy-MM-dd' ou 'dd/MM/yyyy' selon
        // la façon dont ton API renvoie la date (sale.date) !
        final saleDate = DateFormat('yyyy-MM-dd').parse(sale.date);

        final start = _startDate != null
            ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
            : DateTime(2000);

        final end = _endDate != null
            ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : DateTime(2100);

        return saleDate.isAfter(start) && saleDate.isBefore(end);
      } catch (e) {
        // Si la date n'est pas "parsable", on l'affiche par défaut
        return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildPremiumHeader(isLoading), // Ton header parfait
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : RefreshIndicator(
              // 🟢 Le widget magique qui gère le rafraîchissement
              onRefresh: _applyFilter,
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                key: const PageStorageKey('hostess_history_scroll'),
                // 🟢 Important: ça force la liste à être scrollable même s'il y a peu d'éléments
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                itemCount: filtered.length,
                itemBuilder: (context, index) =>
                    _buildHistoryItem(context, filtered[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }


  /*Future<void> _showPrinterSettings(BuildContext context) async {
    bool hasPermissions = await _requestBluetoothPermissions();
    if (!hasPermissions) return;

    try {
      // Nouvelle façon de récupérer les appareils avec print_bluetooth_thermal
      _devices = await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      debugPrint("Erreur scan Bluetooth : $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Imprimante Thermique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    if (_devices.isEmpty)
                      const Text("Aucun appareil Bluetooth associé. Allez dans les paramètres de votre téléphone pour associer l'imprimante.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),

                    if (_devices.isNotEmpty)
                      ..._devices.map((device) => ListTile(
                        leading: const Icon(Icons.print, color: Colors.blue),
                        title: Text(device.name), // Le nom ne sera plus null avec ce package
                        subtitle: Text(device.macAdress), // Attention à l'orthographe du package (macAdress)
                        trailing: _selectedDeviceMac == device.macAdress
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () async {
                          try {
                            print("🔄 Tentative de connexion à : ${device.name}");
                            setModalState(() => _selectedDeviceMac = device.macAdress);

                            // 1. Déconnexion préalable si nécessaire
                            bool isCurrentlyConnected = await PrintBluetoothThermal.connectionStatus;
                            if (isCurrentlyConnected) {
                              await PrintBluetoothThermal.disconnect;
                            }

                            // 2. Nouvelle façon de se connecter
                            bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);

                            if (connected) {
                              print("✅ Connexion réussie !");
                              setState(() => _isPrinterConnected = true);
                              setModalState(() => _isPrinterConnected = true);

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Imprimante connectée !"), backgroundColor: Colors.green)
                                );
                              }
                            } else {
                              throw Exception("L'imprimante a refusé la connexion");
                            }
                          } catch (e) {
                            print("🚨 Erreur de connexion : $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Échec : $e"), backgroundColor: Colors.red)
                              );
                            }
                          }
                        },
                      )).toList(),

                    const SizedBox(height: 20),
                    if (_isPrinterConnected)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () async {
                          try {
                            await PrintBluetoothThermal.disconnect;
                          } finally {
                            setState(() {
                              _isPrinterConnected = false;
                              _selectedDeviceMac = null;
                            });
                            setModalState(() => _isPrinterConnected = false);
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text("Déconnecter", style: TextStyle(color: Colors.white)),
                      )
                  ],
                ),
              );
            }
        );
      },
    );
  }*/


  Future<void> _showPrinterSettings(BuildContext context) async {
    bool hasPermissions = await _requestBluetoothPermissions();
    if (!hasPermissions) return;

    try {
      // Nouvelle façon de récupérer les appareils avec print_bluetooth_thermal
      _devices = await PrintBluetoothThermal.pairedBluetooths;
    } catch (e) {
      debugPrint("Erreur scan Bluetooth : $e");
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Imprimante Thermique", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    if (_devices.isEmpty)
                      const Text("Aucun appareil Bluetooth associé. Allez dans les paramètres de votre téléphone pour associer l'imprimante.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),

                    if (_devices.isNotEmpty)
                      ..._devices.map((device) => ListTile(
                        leading: const Icon(Icons.print, color: Colors.blue),
                        title: Text(device.name),
                        subtitle: Text(device.macAdress), // Package property name
                        trailing: _selectedDeviceMac == device.macAdress
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : null,
                        onTap: () async {
                          try {
                            print("🔄 Tentative de connexion à : ${device.name}");
                            setModalState(() => _selectedDeviceMac = device.macAdress);

                            // 1. Déconnexion préalable si nécessaire
                            bool isCurrentlyConnected = await PrintBluetoothThermal.connectionStatus;
                            if (isCurrentlyConnected) {
                              await PrintBluetoothThermal.disconnect;
                            }

                            // 2. Nouvelle façon de se connecter
                            bool connected = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);

                            if (connected) {
                              print("✅ Connexion réussie !");
                              setState(() => _isPrinterConnected = true);
                              setModalState(() => _isPrinterConnected = true);

                              // 🟢 SAUVEGARDE DE L'ADRESSE MAC ICI
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('printer_mac_address', device.macAdress);

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Imprimante connectée et sauvegardée !"), backgroundColor: Colors.green)
                                );
                              }
                            } else {
                              throw Exception("L'imprimante a refusé la connexion");
                            }
                          } catch (e) {
                            print("🚨 Erreur de connexion : $e");
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Échec : $e"), backgroundColor: Colors.red)
                              );
                            }
                          }
                        },
                      )).toList(),

                    const SizedBox(height: 20),
                    if (_isPrinterConnected)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () async {
                          try {
                            await PrintBluetoothThermal.disconnect;
                          } finally {
                            // 🟢 SUPPRESSION DE L'ADRESSE MAC EN CAS DE DÉCONNEXION MANUELLE
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.remove('printer_mac_address');

                            setState(() {
                              _isPrinterConnected = false;
                              _selectedDeviceMac = null;
                            });
                            setModalState(() => _isPrinterConnected = false);
                            if (mounted) Navigator.pop(context);
                          }
                        },
                        child: const Text("Déconnecter", style: TextStyle(color: Colors.white)),
                      )
                  ],
                ),
              );
            }
        );
      },
    );
  }


  // 🎨 Dessine le billet visuellement (Noir et Blanc strictly !)
  Widget _buildTicketWidget(HostessSaleModel sale) {
    // On remplace la flèche Unicode pour le design
    String trajetNettoye = sale.trajet.replaceAll('→', '->');

    // Tout le billet doit être dans un Container BLANC avec une largeur fixe
    return Container(
      width: 380, // Largeur idéale pour le papier 58mm
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min, // S'adapte à la hauteur du contenu
        children: [
          // En-tête (Gros et gras)
          const Text(
            'CAR225',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black, // <--- OBLIGATOIREMENT NOIR
              fontSize: 48,       // Très gros
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Billet de transport',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 18),
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.black, thickness: 2), // Ligne de séparation
          const SizedBox(height: 10),

          // Infos détaillées (Row pour simuler les colonnes)
          _buildTicketRow('Ticket:', sale.ticketNo, isBold: true),
          const SizedBox(height: 5),
          _buildTicketRow('Passager:', sale.passager),

          const SizedBox(height: 20),

          // Trajet
          const Text(
            'TRAJET',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            trajetNettoye,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 16),
          ),

          const SizedBox(height: 20),

          // 🟢 LE QR CODE VISUEL
          Center(
            child: QrImageView(
              data: sale.reference,
              version: QrVersions.auto,
              size: 150.0, // Taille du QR Code
              gapless: false,
              // ignore: deprecated_member_use
              foregroundColor: Colors.black, // OBLIGATOIREMENT NOIR
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Bon voyage !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
          ),

          // Espace de fin (très important pour le déroulement physique)
          const SizedBox(height: 50),
        ],
      ),
    );
  }

// Petite fonction helper pour les lignes d'info (Ticket:, Passager:)
  Widget _buildTicketRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 90, child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 14))),
        Expanded(
          child: Text(
              value,
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal
              )
          ),
        ),
      ],
    );
  }



  Widget _buildPremiumHeader(bool isLoading) {
    final fmt = DateFormat('dd/MM/yyyy');
    final startLabel = _startDate != null ? fmt.format(_startDate!) : 'jj/mm/aaaa';
    final endLabel = _endDate != null ? fmt.format(_endDate!) : 'jj/mm/aaaa';
    final hasFilter = _startDate != null || _endDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 5, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Historique des ventes',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                    ),
                    Text(
                      'Suivi de vos transactions',
                      style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // 🟢 ZONE DES BOUTONS (Rafraîchir + Imprimante)
              Row(
                children: [
                  if (hasFilter)
                    GestureDetector(
                      onTap: _resetFilter,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  if (hasFilter) const Gap(10), // Espace si le filtre est actif

                  // 🖨️ BOUTON IMPRIMANTE
                  GestureDetector(
                    onTap: () => _showPrinterSettings(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _isPrinterConnected
                            ? Colors.greenAccent.shade400 // Vert si connecté
                            : Colors.white.withValues(alpha: 0.2), // Transparent sinon
                        shape: BoxShape.circle,
                        boxShadow: _isPrinterConnected ? [
                          BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.5), blurRadius: 8)
                        ] : [],
                      ),
                      child: Icon(
                          _isPrinterConnected ? Icons.print : Icons.print_disabled,
                          color: _isPrinterConnected ? Colors.black87 : Colors.white,
                          size: 20
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Du',
                  value: startLabel,
                  isEmpty: _startDate == null,
                  onTap: () => _selectStartDate(context),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _buildDateField(
                  label: 'Au',
                  value: endLabel,
                  isEmpty: _endDate == null,
                  onTap: () => _selectEndDate(context),
                ),
              ),
              const Gap(12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8)),
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: isLoading ? null : () {
                      HapticFeedback.mediumImpact();
                      _applyFilter();
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withValues(alpha: 0.1),
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: isLoading
                          ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)))
                          : const Icon(Icons.search_rounded, color: AppColors.primary, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildDateField({required String label, required String value, required bool isEmpty, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
          ),
          const Gap(6),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isEmpty ? Colors.white.withValues(alpha: 0.4) : Colors.white, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: isEmpty ? const Color(0xFFB0BEC5) : AppColors.primary),
                const Gap(8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? const Color.fromARGB(255, 103, 105, 106) : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Gap(100),
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          ),
          Gap(24),
          Text('Recherche en cours...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Gap(8),
          Text('Nous récupérons vos ventes', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    // 🟢 Utilisation d'un ListView avec AlwaysScrollableScrollPhysics
    // pour permettre le Pull-to-Refresh même quand c'est vide !
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Gap(70), // Un peu d'espace en haut
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
              ),
              const Gap(24),
              const Text('Aucune vente trouvée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const Gap(8),
              const Text('Essayez une autre période de temps ou tirez pour rafraîchir.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }

  // 🟢 UTILISATION DU MODEL HostessSaleModel
  Widget _buildHistoryItem(BuildContext context, HostessSaleModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSaleDetails(context, sale),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sale.ticketNo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                    ),
                    _buildStatusBadge(sale.statut),
                  ],
                ),
                const Gap(8),
                Text(sale.passager, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const Gap(6),
                Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const Gap(6),
                    Expanded(
                      child: Text(sale.trajet, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const Gap(6),
                    Text('${sale.date} • ${sale.heure}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ],
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: Text('Place ${sale.siege}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ),
                    Text(sale.prix, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 UTILISATION DU MODEL HostessSaleModel ICI AUSSI
  void _showSaleDetails(BuildContext context, HostessSaleModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSaleDetailsContent(context, sale),
    );
  }



  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final isConfirmed = status.toLowerCase() == 'confirmé';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }


  Widget _buildSaleDetailsContent(BuildContext context, HostessSaleModel sale) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        bottom: Platform.isAndroid ? true : false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Détails de la vente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                _buildStatusBadge(sale.statut),
              ],
            ),
            const Gap(24),

            // 🟢 AFFICHAGE DU QR CODE DANS LE BOTTOM SHEET
            if (sale.qrCodeUrl != null && sale.qrCodeUrl!.isNotEmpty) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.network(
                    sale.qrCodeUrl!,
                    width: 120,
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.qr_code, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              const Gap(16),
            ],

            _buildDetailRow('N° Billet', sale.ticketNo, isHighlight: true),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            _buildDetailRow('Passager', sale.passager),
            const Gap(16),
            _buildDetailRow('Trajet', sale.trajet),
            const Gap(16),
            _buildDetailRow('Date', sale.date),
            const Gap(16),
            _buildDetailRow('Heure', sale.heure),
            const Gap(16),
            _buildDetailRow('Place', sale.siege),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant total', style: TextStyle(fontSize: 16, color: Color(0xFF757575), fontWeight: FontWeight.w600)),
                Text(sale.prix, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ],
            ),
            const Gap(32),

            // 🟢 NOUVEAU BOUTON IMPRIMER
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context); // Ferme le bottom sheet
                  _printTicket(sale);     // Lance l'impression
                },
                icon: const Icon(Icons.print, color: Colors.white),
                label: const Text('Imprimer le billet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),
            const Gap(10),

            // Bouton fermer classique (secondaire)
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
            )
          ],
        ),
      ),
    );
  }


}