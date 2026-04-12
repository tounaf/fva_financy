import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

class AutoUpdateDialog extends StatefulWidget {
  final String url;
  final String version;

  const AutoUpdateDialog({super.key, required this.url, required this.version});

  @override
  State<AutoUpdateDialog> createState() => _AutoUpdateDialogState();
}

class _AutoUpdateDialogState extends State<AutoUpdateDialog> {
  String status = "Préparation...";
  double progress = 0;

  @override
  void initState() {
    super.initState();
    startUpdate();
  }

  void startUpdate() {
    try {
      // destinationFilename doit correspondre au nom final sur le tel
      OtaUpdate().execute(widget.url, destinationFilename: 'fva_update.apk').listen(
        (OtaEvent event) {
          setState(() {
            switch (event.status) {
              case OtaStatus.DOWNLOADING:
                status = "Téléchargement en cours...";
                progress = double.tryParse(event.value!) ?? 0;
                break;
              case OtaStatus.INSTALLING:
                status = "Installation...";
                break;
              case OtaStatus.ALREADY_RUNNING_ERROR:
                status = "Une mise à jour est déjà lancée.";
                break;
              case OtaStatus.PERMISSION_NOT_GRANTED_ERROR:
                status = "Permission d'installation refusée.";
                break;
              default:
                status = "Erreur : ${event.status}";
            }
          });
        },
      );
    } catch (e) {
      setState(() => status = "Échec : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Mise à jour v${widget.version}"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(status),
          const SizedBox(height: 20),
          LinearProgressIndicator(value: progress / 100),
          const SizedBox(height: 10),
          Text("${progress.toInt()}%"),
        ],
      ),
      actions: [
        if (status.contains("Erreur") || status.contains("refusée"))
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
      ],
    );
  }
}