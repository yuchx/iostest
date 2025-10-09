import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:ntp/ntp.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';
import 'dart:io';
import 'custom_channel.dart';
import 'demo/localfileUseSetting.dart';
import 'shareLocal.dart';
import 'HttpHelper.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';//md5
Map<String, dynamic> DeviceInfo =  {
  'DeviceId' :'',
  'DeviceName':'',
  'IPAddress':'',
  'MACAddress':'',
  'MachineCode':'',
  'SystemVersion':'',
  'DeviceType':'',
  'DeviceVersion':'',
  'Memory':'',
  'DiskFreeSize':'',
  'Location':'',
  'Width':'',
  'Height':'',
  'AuthorizationCode':'',
  'EncryptedSignatureData':'',
  'TcpClientID':'',
  'CurrentStickTime':'',
};

getDeviceInfo() async {
  DeviceInfoPlugin deviceInfo = new DeviceInfoPlugin();//设备信息
  if(Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    await _readAndroidBuildData(androidInfo);
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    _readIosDeviceInfo(iosInfo);
  }
}
//安卓获取设备信息
Future<Map<String, dynamic>> _readAndroidBuildData(AndroidDeviceInfo build) async {
  try {
    // 获取设备上的文档目录（通常是根目录）的引用
    // Directory directory = await getExternalStorageDirectory();
    String directory = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
    if (directory != null&&directory != 'null'&&directory != '') {
      String filePath = '${directory}/deviceInfo.txt';// 创建文件路径
      File file = File(filePath);
      if (await file.exists()) {
        print('文件已存在，不需要创建');
      } else {
        await file.create();
        print('文件不存在，已成功创建');
      }
      String fileContent = await file.readAsString();//读取到文件里的内容
      print(fileContent);
      var deviceidbefor = build.id;//在设备中获取的唯一标识
      if(fileContent==""){
        var uuid = Uuid();
        var uuidv4 = uuid.v4();
        var savecode = md5.convert(utf8.encode('$deviceidbefor$uuidv4')).toString();
        await file.writeAsString('$savecode');
        DeviceInfo['DeviceId'] = '$savecode';//deviceId设备ID
      }else{
        DeviceInfo['DeviceId'] = '$fileContent';//deviceId设备ID
        // DeviceInfo['DeviceId'] = build.androidId;//deviceId设备ID
      }
      print('文件创建并写入成功：$filePath');
    } else {
      print('无法获取文件目录');
      DeviceInfo['DeviceId'] = build.id;//deviceId设备ID
    }
  } catch (e) {
    print('发生错误：$e');//发生错误时，先放上在设备上获取的deviceId
    deviceLogAdd(-1, '获取唯一标识文件出错deviceid${build.id}', '获取唯一标识文件出错deviceid${build.id}');
    DeviceInfo['DeviceId'] = build.id;//deviceId设备ID
  }
  DeviceInfo['DeviceName'] = build.model;//deviceId设备名称
  DeviceInfo['DeviceVersion'] = build.model;//DeviceVersion
  DeviceInfo['SystemVersion'] = 'android'+build.version.release;//SystemVersion
  return <String, dynamic>{
  'DeviceId' :build.id,//deviceId设备ID
  'DeviceName' : build.model,//deviceId设备名称
  'DeviceVersion' :build.model,//DeviceVersion
  'SystemVersion' :'android'+build.version.release,//SystemVersion
  };
}
//IOS获取设备信息
// IOS获取设备信息
Future<Map<String, dynamic>> _readIosDeviceInfo(IosDeviceInfo data) async {
  try {
    // iOS 没有 Android 那样的公共目录，这里用应用沙盒的 Document 目录保存
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/deviceInfo.txt';
    final file = File(filePath);

    if (await file.exists()) {
      print('文件已存在');
    } else {
      await file.create();
      print('文件不存在，已成功创建');
    }

    String fileContent = await file.readAsString();
    print('iOS 文件内容: $fileContent');

    var deviceidbefor = data.identifierForVendor ?? ""; // iOS 提供的唯一标识（可能为null）
    if (fileContent.isEmpty) {
      var uuid = Uuid();
      var uuidv4 = uuid.v4();
      var savecode =
      md5.convert(utf8.encode('$deviceidbefor$uuidv4')).toString();
      await file.writeAsString(savecode);
      DeviceInfo['DeviceId'] = savecode;
    } else {
      DeviceInfo['DeviceId'] = fileContent;
    }

    print('iOS 唯一标识写入成功: $filePath');
  } catch (e) {
    print('iOS 获取唯一标识文件出错：$e');
    deviceLogAdd(-1, 'iOS 获取唯一标识文件出错 ${data.identifierForVendor}',
        'iOS 获取唯一标识文件出错 ${data.identifierForVendor}');
    DeviceInfo['DeviceId'] = data.identifierForVendor ?? "unknown";
  }

  // 统一封装 DeviceInfo
  DeviceInfo['DeviceName'] = data.name;
  DeviceInfo['DeviceVersion'] = data.model;
  DeviceInfo['SystemVersion'] = '${data.systemName} ${data.systemVersion}';

  return <String, dynamic>{
    'DeviceId': DeviceInfo['DeviceId'],
    'DeviceName': data.name,
    'DeviceVersion': data.model,
    'SystemVersion': '${data.systemName} ${data.systemVersion}',
  };
}



// Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
//   return <String, dynamic>{
//     'name': data.name,
//     'systemName': data.systemName,
//     'systemVersion': data.systemVersion,
//     'model': data.model,
//     'localizedModel': data.localizedModel,
//     'identifierForVendor': data.identifierForVendor,
//     'isPhysicalDevice': data.isPhysicalDevice,
//     'utsname.sysname:': data.utsname.sysname,
//     'utsname.nodename:': data.utsname.nodename,
//     'utsname.release:': data.utsname.release,
//     'utsname.version:': data.utsname.version,
//     'utsname.machine:': data.utsname.machine,
//   };
// }


//常见文件a.txt并写入文件内容
Future<void> createAndWriteToFile() async {
  try {
    // 获取设备上的文档目录（通常是根目录）的引用
    // Directory directory = await getExternalStorageDirectory();
    String directory = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS);
    if (directory != null&&directory != 'null'&&directory != '') {
      // 创建文件路径
      // String filePath = '${directory.path}/a.txt';
      String filePath = '${directory}/a.txt';

      // 打开文件并写入内容
      File file = File(filePath);

      if (await file.exists()) {
        print('文件已存在');
      } else {
        await file.create();
        print('文件已成功创建');
      }

      String fileContent = await file.readAsString();//读取到文件里的内容
      print(fileContent);
      await file.writeAsString('你要写入的内容');

      print('文件创建并写入成功：$filePath');
    } else {
      print('无法获取文件目录');
    }
  } catch (e) {
    print('发生错误：$e');
  }
}



var posalUrl='';//服务器地址
var posalport = '';//服务器端口号
var devicecode = '';//设备授权码

var meetorderUrl='';//会议预约服务器地址

var meetName = '';//会议室默认名称
var meetRoomCodeUrl = '';//会议室二维码的地址
String? deviceID = '';//设备ID
var mqttUrl = '';//Mqtt的网址
var mqttPort = '';//Mqtt的端口号
var MqttUser = '';//Mqtt的用户名
var MqttPassword = '';//Mqtt的密码
var upanName="";//插入U盘的名字
var meetPreview = '3';//会议的预览天数
double numcompare = -1;//调节音量相关
var haveMeet=false;//当前有无正在进行的会议
var havePro = 3;//1为会议+节目，0为单会议（有会议二维码）不带节目 2单节目为不带会议  3单会议（不带会议二维码） 4摄像头人脸签到版本
int havesucccode = 0;//是否正确授权 0没有授权授权过期授权失效  1授权
bool isKeptOn = true;//屏幕是否打开默认屏幕是开的,把他的状态缓存到APP中----因为看门狗拉起来的时候有可能是关屏状态
var KeySend = '15e3be2df66a108106b2c4e92a95b253';//与后台约定的授权相关的接口的Key  Tonle123的32位Md5值
var NtpServer='';//NTP时间校对（一天同步一次，首次进入同步一次）
int systimeDiff=0;//系统时间与NTP时间的差值 单位ms
//当前正在播放的任务的信息（任务ID，实际开始播放的时间，最后播放时间，从开始到现在播了多久  单位统一为ms）
//每过一秒记录一下最后播放时间并存在缓存中，节目停止播放或切换（上传后需要重新把本次播放的赋值上去）上传给后台并清空变量以及缓存的值
//每次进入APP首先判断缓存中是否有值，如果有则说明是没有上传过的数据（APP异常关闭导致），重新上传给服务器(接口支持一次性上传)，并清空缓存的值
//遇到上传任务播放时间接口请求失败时，失败的数据保存一份在缓存，MQTT重新连接以后重新上传至服务器（接口支持一次性上传），上传成功后清空缓存，同时进入APP后也需要判断一下缓存中是否有任务失败数据
var nowplayschMess = {
  'scheduleID':'',//任务ID
  'proID':'',//节目ID
  'playStart':'',//开始播放时间时间戳
  'lastplaytime':'',//最后播放时间戳
  'Durationtime':''//持续时间单位ms毫秒
};
Map<String, dynamic> ajaxDataValue = {
  "Icon": "http://uploads.xuexila.com/allimg/1703/1040-1F30Q01916.jpg",
  "RoomName": "",
  "RoomId": "",
  "Host": "",
  "ScheduleTable": [
  ],
  "Message": ""
};
var ajaxData = {
  'RoomName':ajaxDataValue['RoomName'],
  'currentAddData': '',
  'ScheduleTable': ajaxDataValue['ScheduleTable'],
  'meetList':[],
  'CurrentName': "",
  'CurrentTeacher': "",
  'CurrentTime': "",
  'nextCurrentName': "",
  'CurrentOrderId':"",//正在进行的会议的ID
  'CurrentopSign':"",//是否开启签到
  'AllSignPeoNum':0,//所有的签到人数
  'SignReMess':"",//签到结果
  'SignReTime':0,//签到结果的时间
  'SignSendPosition': {
    'x':0,
    'y':0,
    'x2':0,
    'y2':0,
    'upnum':0//人脸提交次数
  },//签到结果的时间
};
var showupApp=0;//0要不要去下载
var showhotload = 0;//要不要展示热更下载的动画  0不展示 1展示
String expectedChecksum = '';//热更新文件的md5的值先默认一个值，后期从MQTT命令里返回回来ae241a898f58fefe1492818ebe63a434
var hotdownpath = '';//要下载的热更新的包的位置
var mqoffstanum = 2;//MQTT掉线后是1，未连接2和正常连接都是0
var offlinelogList = [];//离线后日志需要提交的内容的合集

var schplanlist = [];//所有的任务的总和


List SignPeoList = [];//签到人员列表

// final playerMeet = AudioPlayer();//定义一个全局的音频----会议签到相关
//发送系统通知
// FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin;
//steam检测
StreamController<String> streamDemo= StreamController.broadcast();//节目相关
StreamController<String> streamtemplate= StreamController.broadcast();//模板相关
StreamController<String> streanupApp= StreamController.broadcast();//热更新的下载相关
StreamController<String> streamhotload= StreamController.broadcast();//热更新的遮罩
StreamController<String> streamchangebg= StreamController.broadcast();//更换背景图
StreamController<String> streaminsert= StreamController.broadcast();//插播消息
StreamController<String> streamMeetThing= StreamController.broadcast();//会议进行情况等

StreamController<String> streamsdAddPeoImg= StreamController.broadcast();//检测到人脸
//接收到热更新文件下载的命令，传递给weidget去下载
void downhotfile(val){
  showupApp = val;
  streanupApp.add('$val');
  showhotload = 1;//要不要展示下载的动画  0不展示 1展示
  streamhotload.add('$showhotload');
}
//显示或隐藏热更新加载动画
void hideshowhotload(val){
  showhotload = val;//要不要展示下载的动画  0不展示 1展示
  streamhotload.add('$showhotload');
}


//更改会议室名称以及会议室二维码
void meetnamechange(val){
  streamDemo.add('${val}${meetRoomCodeUrl}');
}
//更改模板样式
void changetemp(booVal){
  // if(booVal=="0"){
  //   havePro=0;//终端只加载会议--有小程序二维码
  //   StorageUtil.setIntItem('havePro',havePro);//存储是否有节目
  //   streamtemplate.add('$havePro');
  // }else if(booVal=="1"){
  //   havePro=1;//终端加载会议和节目
  //   StorageUtil.setIntItem('havePro',havePro);//存储是否有节目
  //   streamtemplate.add('$havePro');
  // }else if(booVal=="2"){
  //   havePro=2;//终端只加载节目
  //   StorageUtil.setIntItem('havePro',havePro);//存储是否有节目
  //   streamtemplate.add('$havePro');
  // }else if(booVal=="3"){
  //   havePro=3;//终端只加载会议--无小程序二维码
  //   StorageUtil.setIntItem('havePro',havePro);//存储是否有节目
  //   streamtemplate.add('$havePro');
  // }else if(booVal=="4"){
  //   havePro=4;//终端只加载会议--摄像头人脸签到版本
  //   StorageUtil.setIntItem('havePro',havePro);//存储是否有节目
  //   streamtemplate.add('$havePro');
  // }
}

getMessageLogin(deviceID){
  deviceLogAdd(19,"Login去获取token$deviceID","Login去获取token$deviceID");
  var posalUrlGetToken = 'http://$posalUrl:$posalport';
  var userPass={
    "username":"system",
    "password":"1"
  };
  HttpDioHelper helper = HttpDioHelper();
  helper.httpDioGet(posalUrlGetToken, "/api/InfoPublish/Login",body:userPass).then((datares) {

    if(datares.statusCode!=200){
      deviceLogAdd(-1,"获取token报400失败deviceID：$deviceID","获取token报400失败deviceID：$deviceID");
    }else{
      var res = (datares.data);
      if('${res['code']}'!='200'){
        deviceLogAdd(-1,"获取token失败${res['info']}","获取token失败${res['info']}");
      }else{
        deviceLogAdd(19,"获取token成功${res['data']['Token']}----${res['data']['ExpireTime']}传的deviceID：","获取token成功${res['data']['Token']}---${res['data']['ExpireTime']}传的deviceID：$deviceID");
        StorageUtil.remove('TokenValue');//Token的值
        StorageUtil.remove('TokenExpireTime');//Token的过期时间
        StorageUtil.setStringItem('TokenValue','${res['data']['Token']}');//Token的值
        StorageUtil.setStringItem('TokenExpireTime','${res['data']['ExpireTime']}');//Token的过期时间
        var TokenValueLogin = res['data']['Token'];
        var bodySend = {
          'deviceID':deviceID,
          'TemplateId':'cff5ed65-5d44-4268-bb2c-ee12c3056471'
        };
        var headersSend = {
          "Authorization":TokenValueLogin
        };
        try{
          HttpDioHelper helper = HttpDioHelper();
          helper.httpDioGet(posalUrlGetToken, "/api/InfoPublish/GetTemplateContent",headers:headersSend,body:bodySend).then((datares) {
            if(datares.statusCode!=200){
              Future.delayed(Duration(seconds: 30), (){
                getMessageLogin(deviceID);
              });
              deviceLogAdd(19,"$deviceID成功走通拉取数据接口GetTemplateContent但是400","$deviceID成功走通拉取数据接口GetTemplateContent但是400");
            }
            else{
              var res = (datares.data);
              var dadata =res['data'];
              if(dadata!=null){
                var accdata =dadata['TemplateContent'];
                ajaxDataValue =json.decode(accdata);
                meetName=ajaxDataValue['RoomName'];
                var hostreLi = ajaxDataValue['Host'];
                var RoomIdreLi = ajaxDataValue['RoomId'];
                meetRoomCodeUrl = '${hostreLi}/QrcodePath/Room/${RoomIdreLi}.png';
                meetnamechange(meetName);//动态更改更改会议室名称和会议室的二维码
                StorageUtil.setStringItem('meetName',meetName);//存储设备授权码
                print(ajaxDataValue);
                deviceLogAdd(19,"成功拉取到会议列表的数据$deviceID","成功拉取到会议列表的数据！");
              }else{
                deviceLogAdd(19,"拉取到会议的数据是空$deviceID","拉取到会议的数据是空！");
              }

            }
          });
        } catch (e) {
          if(e is DioError)
          {
            deviceLogAdd(-1,"获取模板内容异常",'获取模板内容异常:${e.error}');
          }
          else{
            deviceLogAdd(-1,"获取模板内容异常",'获取模板内容异常不是DioError');
          }
        }
      }

    }

  });
}
//获取数据
getMessage(deviceID,TokenValue){

  var bodySend = {
    'deviceID':deviceID,
    'TemplateId':'cff5ed65-5d44-4268-bb2c-ee12c3056471'
  };
  print(bodySend);
  var headersSend = {
    "Authorization":TokenValue
  };

  print('token$TokenValue');
  var posalUrlGetToken = 'http://$posalUrl:$posalport';
  try{
    HttpDioHelper helper = HttpDioHelper();
    helper.httpDioGet(posalUrlGetToken, "/api/InfoPublish/GetTemplateContent",headers:headersSend,body:bodySend).then((datares) {
      deviceLogAdd(19,"拉取到会议动作开始","拉取到会议动作开始token:$TokenValue");
      if(datares.statusCode!=200){
        deviceLogAdd(19,"成功走通拉取数据接口GetTemplateContent但是400","成功走通拉取数据接口GetTemplateContent但是400token:$TokenValue");
        Future.delayed(Duration(seconds: 30), (){
          getMessageLogin(deviceID);
        });
      }else{
        var res = (datares.data);
        var dadata =res['data'];
        var accdata =dadata['TemplateContent'];
        ajaxDataValue =json.decode(accdata);
        meetName=ajaxDataValue['RoomName'];
        var hostreLi = ajaxDataValue['Host'];
        var RoomIdreLi = ajaxDataValue['RoomId'];
        meetRoomCodeUrl = '${hostreLi}/QrcodePath/Room/${RoomIdreLi}.png';
        meetnamechange(meetName);//动态更改更改会议室名称和会议室的二维码
        StorageUtil.setStringItem('meetName',meetName);//存储设备授权码
        deviceLogAdd(19,"成功拉取到会议列表的数据,会议室名称：$meetName","成功拉取到会议列表的数据会议室名称：$meetName");
      }
    }).catchError(
        (e){
          if(e is DioError)
            {
              deviceLogAdd(-1,"获取模板内容异常",'获取模板内容异常:${e.error}');
            }
          //当token超时 会报403错误
          //deviceLogAdd(19,"获取模板内容异常",'获取模板内容异常 token:$TokenValue、line 264');
          Future.delayed(Duration(seconds: 30), (){
            deviceLogAdd(19,"重新尝试获取token",'重新尝试获取token');
            getMessageLogin(deviceID);
          });
        }
    ).whenComplete(() => deviceLogAdd(19, '拉取会议信息流程结束', '拉取会议信息流程结束'));
  }catch(e){
    print("拉取数据报错了$e");
    if(e is DioError)
    {
      deviceLogAdd(19,"获取模板内容异常",'获取模板内容异常:${e.error}');
    }else{
      deviceLogAdd(19,"获取模板内容异常",'获取模板内容异常不是DioError');
    }

  }

}


getIframeConnect() async{
  deviceID = await StorageUtil.getStringItem('deviceID');

  var TokenValue = await StorageUtil.getStringItem('TokenValue');
  var TokenExpireTime = await StorageUtil.getStringItem('TokenExpireTime');
  var nowDataTime =getDataNowNtp().millisecondsSinceEpoch;
  if(TokenValue!=null&&TokenExpireTime!=null){

    var TokenExpireTimezh =  TokenExpireTime+'000';
    var TokenExpireTimeVV =  double.parse(TokenExpireTimezh);

    if(TokenExpireTimeVV>nowDataTime){

      getMessage(deviceID,TokenValue);
    }else{
      getMessageLogin(deviceID);
    }

  }else{
    getMessageLogin(deviceID);
  }

}
//上报之前离线的时候的日志--上限20条
sendofflog(){
  //offlinelogList = [];//上传完成后需要把离线日志的数据置空
  for(var a=0;a<offlinelogList.length;a++){
    if(a<20){
      var nowdatypeLi = offlinelogList[a]['datatype'];
      var dataContentLi = offlinelogList[a]['dataContent'];
      var moduleLi = offlinelogList[a]['module'];
      deviceLogAdd(nowdatypeLi,dataContentLi,moduleLi);
    }else{
      offlinelogList = [];//上传完成后需要把离线日志的数据置空
    }
  }
  offlinelogList = [];//上传完成后需要把离线日志的数据置空
}

//添加日志接口
deviceLogAdd(datatype,dataContent,module) async{
  // var deviceid = await StorageUtil.getStringItem('deviceID');
  // var time=getDataNowNtp().millisecondsSinceEpoch;
  // dataContent=dataContent+" time:$time" +"deviceid:$deviceid";
  // var bodySend = {
  //   'deviceid':'$deviceid',
  //   'datatype':'$datatype',
  //   'datajson':dataContent,
  //   'module':'$module',
  // };
  // print(bodySend);
  // var headersSend = {
  //   "Authorization":""
  // };
  // if(mqoffstanum!=0){
  //   // mqoffstanum = 0;//MQTT掉线后是1，未连接和正常连接都是0
  //   //MQTT连接状态不正常 offlinelogListMQTT离线时日志列表
  //   offlinelogList.add({
  //     'datatype':datatype,
  //     'dataContent':dataContent,
  //     'module':module,
  //     'ertype':0
  //   });
  // }
  // var posalUrlGetToken = 'http://$posalUrl:$posalport';
  // HttpDioHelper helper = HttpDioHelper();
  // if('$datatype'=='7'){
  //   helper.httpDioGet(posalUrlGetToken, "/InfoPublish/RegisterPlayer/DeviceUpdateLog",headers:headersSend,body:bodySend).then((datares) {
  //     print("----------热更新相关的日志接口------------");
  //   });
  // }else if('$datatype'=='-1'){
  //   //设备异常日志，但不包括热更新，热更有热更单独的日志
  //   helper.httpDioGet(posalUrlGetToken, "/InfoPublish/RegisterPlayer/DeviceLog",headers:headersSend,body:bodySend).then((datares) {
  //     var jsondatares = json.decode(datares.data);
  //     if('${jsondatares['code']}'!='200'){
  //       // deviceLogAdd(0, '${jsondatares['info']}', '${jsondatares['info']}');//日志接口报错，传回报错的info
  //       //日志接口出错后，添加到离线日志中
  //       offlinelogList.add({
  //         'datatype':'ex',
  //         'dataContent':'${jsondatares}',
  //         'module':'${jsondatares['info']}',
  //         'ertype':0
  //       });
  //     }
  //
  //     print("--------异常设备日志----------");
  //   });
  // }else{
  //   helper.httpDioGet(posalUrlGetToken, "/InfoPublish/RegisterPlayer/DeviceLog",headers:headersSend,body:bodySend).then((datares) {
  //     var jsondatares = json.decode(datares.data);
  //     if('${jsondatares['code']}'!='200'){
  //       // deviceLogAdd(0, '${jsondatares['info']}', '${jsondatares['info']}');//日志接口报错，传回报错的info
  //       //日志接口出错后，添加到离线日志中
  //       offlinelogList.add({
  //         'datatype':0,
  //         'dataContent':'${jsondatares}',
  //         'module':'${jsondatares['info']}',
  //         'ertype':0
  //       });
  //     }
  //
  //     print("--------普通设备日志----------");
  //   });
  // }
}
//走接口来提交保存更新状态接口
// devicehotUpAdd(upstaval) async{
//   var deviceid = await StorageUtil.getStringItem('deviceID');
//   String versionN = await getAndroidManifestVersion();
//   print('AndroidManifest.xml中的版本号: $versionN');
//   var uptime=getDataNowNtp();
//   var bodySend = {
//     'DeviceId':'$deviceid',
//     'UpdateStatus':'$upstaval',
//     'AppId':myAppId,
//     'VersionName':versionN,
//     'VersionNumber':myhotversionNum,
//     'UpdateDate':uptime
//   };
//   print(bodySend);
//   var headersSend = {
//     "Authorization":""
//   };
//
//   var posalUrlGetToken = 'http://$posalUrl:$posalport';
//   HttpDioHelper helper = HttpDioHelper();
//   helper.httpDioGet(posalUrlGetToken, "/InfoPublish/RegisterPlayer/AppUpdate",headers:headersSend,body:bodySend).then((datares) {
//     print("-------走接口来提交保存更新状态接口-----------");
//   });
// }
// devicehotUpAddNew(upstaval) async{
//   var deviceid = await StorageUtil.getStringItem('deviceID');
//   String versionN = await getAndroidManifestVersion();
//   print('AndroidManifest.xml中的版本号: $versionN');
//   var uptime=getDataNowNtp();
//   var bodySend = {
//     'DeviceId':'$deviceid',
//     'UpdateStatus':'$upstaval',
//     'AppId':myAppId,
//     'VersionName':versionN,
//     'VersionNumber':myhotversionNum,
//     'UpdateDate':uptime
//   };
//   print(bodySend);
//   var headersSend = {
//     "Authorization":""
//   };
//
//   await StorageUtil.setStringItem('upstanum','1');//upstanum 1更新进来的 0正常进入 2热更新步骤还未走完退出APP后进来的
//   var upstanumNow = await StorageUtil.getStringItem('upstanum');//upstanum 1更新进来的 0正常进入 2热更新步骤还未走完退出APP后进来的
//   Fluttertoast.showToast(msg: "upstanum:$upstanumNow");
//   var posalUrlGetToken = 'http://$posalUrl:$posalport';
//   HttpDioHelper helper = HttpDioHelper();
//   helper.httpDioGet(posalUrlGetToken, "/InfoPublish/RegisterPlayer/AppUpdate",headers:headersSend,body:bodySend).then((datares) {
//     print("------走接口来提交保存更新状态接口2-----------");
//     // 调用重新启动应用程序方法
//     Restart.restartApp();//插件版的重新启动应用程序方法
//   });
// }
// //一进程序来提交保存更新状态接口
// deviceNowAdd() async{
//   var deviceid = await StorageUtil.getStringItem('deviceID');
//   String versionN = await getAndroidManifestVersion();
//   print('AndroidManifest.xml中的版本号: $versionN');
//   var bodySend = {
//     'DeviceId':'$deviceid',
//     'AppId':myAppId,
//     'VersionName':versionN,
//     'VersionNumber':myhotversionNum,
//   };
//   print(bodySend);
//   var headersSend = {
//     "Authorization":""
//   };
//
//   var posalUrlGetToken = 'http://$posalUrl:$posalport';
//   if('$posalUrl'!=''){
//     HttpDioHelper helper = HttpDioHelper();
//     helper.httpDioGet(posalUrlGetToken, "/InfoPublish/RegisterPlayer/AppUpdate",headers:headersSend,body:bodySend).then((datares) {
//       print("---------一进程序来提交保存更新状态接口---------");
//     });
//   }
//
// }
//获取storage里的内容
void getLocalMess() async {
//  posalUrl='172.16.10.105';//服务器地址
//  posalport = '58992';//服务器端口号
//  devicecode = '03a8e1e4-dcbe-4629-bef2-f8ff5c2a272c';//设备授权码
  var posalUrlR = await StorageUtil.getStringItem('posalUrl');
  var posalportR = await StorageUtil.getStringItem('posalport');
  var devicecodeR = await StorageUtil.getStringItem('devicecode');
  var meetPreviewR = await StorageUtil.getStringItem('meetPreview');
  var meetNameR = await StorageUtil.getStringItem('meetName');
  var haveProR = await StorageUtil.getIntItem('havePro');
  var numcompareR = await StorageUtil.getStringItem('numcompare');
  deviceID = await StorageUtil.getStringItem('deviceID');
  posalUrl = isNullKong(posalUrlR);
  var meetorderUrlR = await StorageUtil.getStringItem('meetorderUrl');
  meetorderUrl = isNullKong(meetorderUrlR);
  // if(posalUrl==''){
  //   posalUrl='10.0.80.1';
  // }
  posalport = isNullKong(posalportR);
  // if(posalport==''){
  //   posalport='9002';
  // }
  devicecode = isNullKong(devicecodeR);
  meetPreview = isNullreKong(meetPreviewR);
  meetName = isNullKong(meetNameR);
  if(haveProR!=null){
    havePro = haveProR;
  }

  numcompare = double.parse(isNullKongFY(numcompareR));

  var mqttUrlR =await StorageUtil.getStringItem('mqttUrl');//MQTT服务器
  var mqttPortR =await StorageUtil.getStringItem('mqttPort');//MQTT端口号
  var MqttUserR =await StorageUtil.getStringItem('MqttUser');//
  var MqttPasswordR =await StorageUtil.getStringItem('MqttPassword');//
  var upanNameR =await StorageUtil.getStringItem('upanName');//MQTT服务器
  mqttUrl = isNullKong(mqttUrlR);
  mqttPort = isNullKong(mqttPortR);
  MqttUser = isNullKong(MqttUserR);
  MqttPassword = isNullKong(MqttPasswordR);
  upanName = isNullKong(upanNameR);
//上一次的开关屏状态
//   var lockstateR =await StorageUtil.getStringItem('lockstate');//
//   isKeptOn = isNullboolLock(lockstateR);//屏幕是否打开,把他的状态缓存到APP中----因为看门狗拉起来的时候有可能是关屏状态
//   // bool? result = await isLockScreen();//锁着是true  开着是false
//   bool? result = await myjavaisScreenOn();
//   if(result==true){
//     // isKeptOn = false;
//     isKeptOn = true;
//   }else{
//     // isKeptOn = true;
//     isKeptOn = false;
//   }

  // var nowbgpathR = await StorageUtil.getStringItem('bgImg');//整个APP的背景图的地址
  // if(nowbgpathR!=null&&nowbgpathR!='null'&&nowbgpathR!=''){
  //   File filebgimg = File(nowbgpathR);
  //   //读缓存里的背景图的地址
  //   bool imageExists = filebgimg.existsSync();
  //   if (imageExists) {
  //     print('图片存在');
  //     backimgAll = FileImage(filebgimg);//整个APP的背景图
  //   } else {
  //     print('图片不存在');
  //   }
  // }



  //一进入页面获取缓存里的计划时长的值
  String? playschmess = await StorageUtil.getStringItem('playschmess');
  if(playschmess!=null&&playschmess!='null'&&playschmess!=''){
    var messplay = json.decode(playschmess);
    //一进入页面有值说明是之前没有上传过的数据，有值就上传,传值过去以后就清空缓存里的值
    var sendlist = [
      {
        'ScheduleId':'${messplay['scheduleID']}',
        'ProgramId':'${messplay['proID']}',
        'DeviceId':'$deviceID',
        'StartDate':'${messplay['playStart']}',
        'EndDate':'${messplay['lastplaytime']}',
        'Duration':'${messplay['Durationtime']}',
      }
    ];
    if(nowplayschMess['scheduleID']==""){
      //只有是空的时候才是第一次进入APP
      StorageUtil.setStringItem('playschmess',"");//清空缓存里的值
      sendplschtimeMess(sendlist);//上传缓存里的数值
    }

  }else{
    //本地缓存里没有，不处理
  }

}
//字符串的空
String isNullKong(value){
  if (value == null||value=='null') {
    return "";
  }else{
    return value;
  }
}
//字符串的空
String isNullKongFY(value){
  if (value == null||value=='null') {
    return "-1";
  }else{
    return value;
  }
}
//开关屏的值
bool isNullboolLock(value){
  if (value==false||value=='false') {
    return false;
  }else if(value==true||value=='true'){
    return true;
  }else{
    //没有值默认开屏
    return true;
  }
}
//字符串的空
String isNullreKong(value){
  if (value == null||value=='null'||value=='0') {
    return "3";
  }else{
    return value;
  }
}

//所有下载事件的进度监听（下载节目以及下载热更新文件）
@pragma('vm:entry-point')
downloadCallback(String id, int status, int progress) {
  //走热更新的监听方法
  SendPort? sendapp = IsolateNameServer.lookupPortByName('newapp_port');
  sendapp?.send([id, status, progress]);
  //走节目相关的下载的监听
  SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}
//返回当前时间加了NTP差值的
DateTime getDataNowNtp(){
  return DateTime.now().add(Duration(milliseconds: systimeDiff));
}
//返回当前时间的时间戳加了NTP差值的
DateTime gettimeNowNtp(){
  return DateTime.now().add(Duration(milliseconds: systimeDiff));
}
//校对时间
Future<void> checkntpTime() async {
  DateTime _myTime;
  DateTime _ntpTime;
  _myTime = DateTime.now();
  if(NtpServer!=""){
    final int offset = await NTP.getNtpOffset(localTime: _myTime, lookUpAddress: '$NtpServer');
    systimeDiff = offset;//偏差的毫秒数
    // _ntpTime = _myTime.add(Duration(milliseconds: offset));//NTP的时间
    // print('My time: $_myTime');
    // print('NTP time: $_ntpTime');
    // print('Difference: ${_myTime.difference(_ntpTime).inMilliseconds}ms');
  }else{
    systimeDiff=0;//系统时间与NTP时间的差值 单位ms,NTP服务器为空则
  }

}
//上传计划播放时长
sendplschtimeMess(selist){
  var posalUrlGetToken = 'http://$posalUrl:$posalport';
  HttpDioHelper helper = HttpDioHelper();
  var sendmess = {
    'list':selist
  };
  helper.postUrlencodedDio(posalUrlGetToken, "/InfoPublish/RegisterPlayer/ProgramScheduleDetailSubmit",body:sendmess).then((datares) async {
    if(datares.statusCode!=200){
      String playsenderrmess = await StorageUtil.getStringItem('playsenderrmess');//之前没提交成功的播放时长的集合
      if(playsenderrmess!=""&&playsenderrmess!="null"&&playsenderrmess!=null){
        //如果之前不是空，则需要保存
        var messplay = json.decode(playsenderrmess);
        if(messplay.length>200){
          messplay.removeRange(0, 100);//如果超过200条，就删100条
        }
        messplay..addAll(selist);//合并之前缓存里的数组和当前上传的数组
        var messjsonNowStr = json.encode(messplay);
        StorageUtil.setStringItem('playsenderrmess', messjsonNowStr);//存在缓存里
      }else{
        //如果之前是空，则只需要保存本次没成功的数据
        var messplay = selist;
        var messjsonNowStr = json.encode(messplay);
        StorageUtil.setStringItem('playsenderrmess', messjsonNowStr);//存在缓存里
      }
    }else{
      //上传成功，保存在上传成功后的播放时长集合里
      String? playsdsucmess = await StorageUtil.getStringItem('playsdsucmess');//之前提交成功的播放时长的集合
      if(playsdsucmess!=""&&playsdsucmess!="null"&&playsdsucmess!=null){
        //如果之前不是空，则需要保存
        var messplay = json.decode(playsdsucmess);
        if(messplay.length>200){
          messplay.removeRange(0, 100);//如果超过200条，就删100条
        }
        messplay..addAll(selist);//合并之前缓存里的数组和当前上传的数组
        var messjsonNowStr = json.encode(messplay);
        StorageUtil.setStringItem('playsdsucmess', messjsonNowStr);//存在缓存里
      }else{
        //如果之前是空，则只需要保存本次没成功的数据
        var messplay = selist;
        var messjsonNowStr = json.encode(messplay);
        StorageUtil.setStringItem('playsdsucmess', messjsonNowStr);//存在缓存里
      }
    }
  });
}

