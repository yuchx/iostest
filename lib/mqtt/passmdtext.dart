import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';//md5
import 'package:uuid/uuid.dart';
import '../Model.dart';

//加密
Future<Map> jiamiasc(searg) async{
  final uuid = Uuid();
  var onlysjtext=uuid.v4();//唯一的随机数
  var secretKey = md5.convert(utf8.encode("InfoPw$deviceID$onlysjtext")).toString();//唯一的随机数生成的秘钥
  var secretKeySub = secretKey.substring(0,16);
  var jstrarg = json.encode(searg);
  final key = Key.fromUtf8(secretKeySub);
  final encrypter = Encrypter(AES(key, mode: AESMode.ecb,padding:"PKCS7"));
  //加密
  var  encryptedData2=encrypter.encrypt(jstrarg);
  var tosend= encryptedData2.base64;
  Map sendmenew= {
    'msgid':onlysjtext,
    'arg':tosend,
    'ClientId':"$deviceID"
  };
  return sendmenew;
}

//解密Mqtt返回的
Future<String> jiemiascwww(jiatext) async {
  // 解密
  var remima =jiatext['msgid'];
  var rearg =jiatext['arg'];
  var secretKey = md5.convert(utf8.encode("InfoPw$deviceID$remima")).toString();//随机秘钥
  String passKey = secretKey.substring(0,16);
  final key = Key.fromUtf8(passKey);
  final encrypter = Encrypter(AES(key, mode: AESMode.ecb,padding:"PKCS7"));
  var todecrpt=Encrypted.fromBase64(rearg);
  String toreturn= encrypter.decrypt(todecrpt);
  return toreturn;
}
//揭秘授权码返回的是S的时间戳
Future<String> jiemisqcode(rearg) async {
  // 解密
  // var rearg ="VThkKzc4ZG5WekcxUHJ5bWpwWDE0QT09";
  String passKey = '1234567887654321123456788765info';
  final key = Key.fromUtf8(passKey);
  final encrypter = Encrypter(AES(key, mode: AESMode.ecb,padding:"PKCS7"));
  var toreturn ='';
  try{
    var aaarearg = decodeNnBase64('$rearg');
    var todecrpt=Encrypted.fromBase64(aaarearg);
    toreturn= encrypter.decrypt(todecrpt);
  }catch(e){
    toreturn="";
  }
  return toreturn;
}
String decodeNnBase64(String data){
//  return String.fromCharCodes(base64Decode(data));
  return Utf8Decoder().convert(base64Decode(data));
}



