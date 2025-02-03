import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../utils/backendData/userData.dart';
import '../../../utils/constants/colors.dart';
import '../icons/circularIcons.dart';

class AlkProfileTile extends StatelessWidget {
  const AlkProfileTile({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AlkCircularIcon(
        icon: Iconsax.user,
        width: 50,
        height: 50,
        backgroundColor: Colors.white,
        size: 20,
      ),
      title: Text(
        "${UserData.firstname} ${UserData.lastname}",
        style: Theme.of(context)
            .textTheme
            .headlineSmall!
            .apply(color: AlkColors.white),
      ),
      subtitle: Text("${UserData.email} ",
      style: Theme.of(context).textTheme.labelMedium!.apply(color: AlkColors.white),),
      trailing: IconButton(onPressed: (){},icon: const Icon(Iconsax.edit),color: Colors.white,),
    );
  }
}