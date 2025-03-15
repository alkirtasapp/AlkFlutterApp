import 'package:flutter/material.dart';
import 'package:alkirtas/utils/constants/colors.dart';

class AlkProductFeatures extends StatelessWidget {
  const AlkProductFeatures({
    super.key,
    required this.productFeatures,
  });

  final List<String>? productFeatures;

  @override
  Widget build(BuildContext context) {
    return Card(
      
      elevation: 5, // Shadow effect for a modern look
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(10), // Rounded corners
      ),
      margin: const EdgeInsets.all(
          3
          ), // Adds spacing around the card
      child: Padding(
        padding:
            const EdgeInsets.all(12), // Padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children:
              productFeatures!.asMap().entries.map((entry) {
            final feature = entry.value;
            final parts =
                feature.split(':'); // Split "Feature: Value"
            final featureName = parts[0].trim();
            final featureValue =
                parts.length > 1 ? parts[1].trim() : "N/A";
    
            return Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 6.0), // Space between items
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex:
                        4, // Adjusts spacing between feature & value
                    child: Text(
                      '$featureName:',
                      
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                  Expanded(
                    flex:
                        3, // Adjusts spacing between feature & value
                    child: Text(
                      featureValue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
