import 'package:alkirtas/common/widgets/images/AlkCircularImage.dart';
import 'package:alkirtas/common/widgets/layout/brandGridLayout.dart';
import 'package:alkirtas/common/widgets/roundedContainer.dart';
import 'package:alkirtas/features/shop/controllers/brand_controller.dart';
import 'package:flutter/material.dart';

class AlkHomeBrands extends StatelessWidget {
  const AlkHomeBrands({
    super.key,
    required BrandController brandController,
  }) : _brandController = brandController;

  final BrandController _brandController;

  @override
  Widget build(BuildContext context) {
    return AlkBrandGridLayout(
    
      itemCount: 8,
      mainAxisExtent: 60,
      
      itemBuilder: (_, index) {
        //adding fetching brands logic here
        return  FutureBuilder<Map<String, dynamic>?>(
          future: _brandController.fetchBrandData(index),
          builder: (context, snapshot) {
            if ( !snapshot.hasData){
              return const Center(
                child: CircularProgressIndicator() );
            }
              final brand = snapshot.data!;
        return GestureDetector(
          onTap: () {},
          child: AlkRoundedContainer(
            padding: EdgeInsets.all(0),
            
            showBorder: false,
            backgroundColor: Colors.transparent,
            child: Row(
              children: [
                // brand Image
                Flexible(
                  child: AlkCircularImage(
                    image: 'https://www.alkirtas.com/img/m/${brand['id']}.jpg', // logo brand li jebneh bessif 
                    backgroundColor: Colors.transparent,
                    isNetworkImage: true,
                    fit: BoxFit.contain,
                  ),
                ),
                
              ],
            ),
          ),
        );
      },
    );
              });
  }
}
