import 'package:flutter/material.dart';

class AlkTOUCHeckbox extends StatelessWidget {
  const AlkTOUCHeckbox({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text.rich(
        
        TextSpan(
        children: [
          TextSpan(
            text:'En cliquant sur ce buton, vous acceptez nos conditions générales de vente.',style: Theme.of(context).textTheme.bodySmall,
          ),
          
        ]
      )),
    );
  }
}
