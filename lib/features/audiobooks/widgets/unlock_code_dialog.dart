import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../services/audiobook_unlock_service.dart';

/// Dialog for entering unlock codes
class UnlockCodeDialog extends StatefulWidget {
  final String audiobookTitle;
  final VoidCallback? onUnlockSuccess;

  const UnlockCodeDialog({
    super.key,
    required this.audiobookTitle,
    this.onUnlockSuccess,
  });

  /// Show the dialog and return true if unlock was successful
  static Future<bool> show(
    BuildContext context, {
    required String audiobookTitle,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UnlockCodeDialog(audiobookTitle: audiobookTitle),
    );
    return result ?? false;
  }

  @override
  State<UnlockCodeDialog> createState() => _UnlockCodeDialogState();
}

class _UnlockCodeDialogState extends State<UnlockCodeDialog> {
  final _codeController = TextEditingController();
  final _unlockService = AudiobookUnlockService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _submitCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await _unlockService.init();
    final result = await _unlockService.redeemCode(_codeController.text);

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(result.message),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() {
        _errorMessage = result.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Iconsax.lock_1, color: primaryColor),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Déverrouiller',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.audiobookTitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Entrez votre code',
              prefixIcon: const Icon(Iconsax.key),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorText: _errorMessage,
            ),
            onSubmitted: (_) => _submitCode(),
            enabled: !_isLoading,
          ),
          const SizedBox(height: 8),
          Text(
            'Entrez le code que vous avez reçu lors de votre achat',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Annuler',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Déverrouiller'),
        ),
      ],
    );
  }
}
