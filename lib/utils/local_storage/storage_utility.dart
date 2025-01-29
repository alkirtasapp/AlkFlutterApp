import 'package:get_storage/get_storage.dart';

class AlkLocalStorage{
  static final AlkLocalStorage _instance = AlkLocalStorage._internal();


  factory  AlkLocalStorage(){
    return _instance;
  } 
  AlkLocalStorage._internal();
  

  final  _storage=GetStorage();

  // Generic method to save data 
  Future <void> saveData<T>(String key , T value ) async {
    await _storage.write(key, value);
  }

  // Generic method to read data 
  Future <void> readData<T>(String key ) async {
    await _storage.read(key);
  }

  // Generic method to remove data 
  Future <void> removeData<T>(String key ) async {
    await _storage.remove(key);
  }

  // Generic method to clear all  
  Future <void> clearAll() async {
    await _storage.erase();
  }

}