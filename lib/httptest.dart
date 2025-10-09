import 'dart:convert';

import 'package:dio/dio.dart';
import 'HttpHelper.dart';

import 'package:fluttertoast/fluttertoast.dart';
getMessageLogin(deviceID,posalUrlGetToken){
  var userPass={
    "username":"system",
    "password":"1"
  };
  HttpDioHelper helper = HttpDioHelper();
  helper.httpDioGet(posalUrlGetToken, "/api/InfoPublish/Login",body:userPass).then((datares) {

    if(datares.statusCode!=200){
    }else{
      var res = (datares.data);
      if('${res['code']}'!='200'){
        Fluttertoast.showToast(msg: "${res}");
      }else{
        var TokenValueLogin = res['data']['Token'];
        Fluttertoast.showToast(msg: "token$TokenValueLogin");
        // var bodySend = {
        //   'deviceID':deviceID,
        //   'TemplateId':'cff5ed65-5d44-4268-bb2c-ee12c3056471'
        // };
        // var headersSend = {
        //   "Authorization":TokenValueLogin
        // };
        // try{
        //   HttpDioHelper helper = HttpDioHelper();
        //   helper.httpDioGet(posalUrlGetToken, "/api/InfoPublish/GetTemplateContent",headers:headersSend,body:bodySend).then((datares) {
        //     if(datares.statusCode!=200){}
        //     else{
        //       var res = (datares.data);
        //       var dadata =res['data'];
        //       if(dadata!=null){
        //         var accdata =dadata['TemplateContent'];
        //         var ajaxDataValue =json.decode(accdata);
        //         var meetName=ajaxDataValue['RoomName'];
        //         var hostreLi = ajaxDataValue['Host'];
        //         var RoomIdreLi = ajaxDataValue['RoomId'];
        //       }else{
        //       }
        //
        //     }
        //   });
        // } catch (e) {
        //   if(e is DioError)
        //   {
        //   }
        //   else{
        //   }
        // }
      }

    }

  });
}