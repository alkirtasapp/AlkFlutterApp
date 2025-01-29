import 'package:intl/intl.dart';
class AlkFormatter {
  static String formatDate(DateTime? date){ 
    date ??=DateTime.now();
    return DateFormat('dd-MMM-yyyy').format(date) ; //customize the date format as needed 
  }

  static String formatCurrency(double amount ){
    return NumberFormat.currency(locale: 'fr_TN', symbol: 'TND').format(amount);
  }
}