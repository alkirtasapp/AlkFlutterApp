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
            text:'J\'accepte  les conditions générales  et   la politique de confidentialité',style: Theme.of(context).textTheme.bodySmall,
          ),
          
        ]
      )),
    );
  }
}
