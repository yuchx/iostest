import 'dart:typed_data';

import 'passmdtext.dart';

import 'mattt_cert.dart';
import 'state/MQTTAppState.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import '../../Model.dart';
import '../../HttpHelper.dart';
import 'package:flutter/services.dart';
import '../shareLocal.dart';
import 'package:crypto/crypto.dart';//md5
var mytimer;//MQTT发送心跳
var myplayschtimer;//每S更新最后播放时间
String locaPath = "";
int certificate = 0;//0无证书 1有证书




MQTTAppState currentAppState = MQTTAppState();
MQTTManager? manager;
void configureAndConnect(urlMqtt,portMqttsd,clientIdT) {
  // TODO: Use UUID
  var portMqtt = int.parse('$portMqttsd');
  String osPrefix = 'Flutter${getDataNowNtp().millisecondsSinceEpoch}';
  var mytopic = '/InfoPublish_DownTopic/$clientIdT';//没有证书的时候的topic
  if(certificate==1){
    var beesmart_key = md5.convert(utf8.encode("tonle-InfoPW")).toString();//写死的跟后台统一的固定头
    var cltidmdval =md5.convert(utf8.encode("$clientIdT")).toString();
    var maxsmkey = beesmart_key.toUpperCase();//转换成大写
    var maxcltidmd = cltidmdval.toUpperCase();//转换成大写
    mytopic = "/InfoPublish_DownTopic/$maxsmkey/$maxcltidmd";//有证书时的topic
  }else{
    mytopic = '/InfoPublish_DownTopic/$clientIdT';//没有证书的时候的topic
  }
  manager = MQTTManager(
      host: urlMqtt,
      port: portMqtt,
      topic: mytopic,
      identifier: osPrefix,
      state: currentAppState
  );

  manager?.initializeMQTTClient();//安全证书的初始化  0初始化成功  !=0初始化失败
    manager?.connect();
}
void publishMessage(String text) {
  String osPrefix = 'Flutter_Android';
  manager?.publish(text);
}
class MQTTManager{
  final MQTTAppState _currentState;
  MqttServerClient? _client;
  final String _identifier;
  final String _host;
  final int _port;
  final String _topic;

  // Constructor
  MQTTManager({
    required String host,
    required int port,
    required String topic,
    required String identifier,
    required MQTTAppState state
  }): _identifier = identifier, _host = host, _port = port, _topic = topic, _currentState = state ;

  int initializeMQTTClient(){
    _client = MqttServerClient(_host,_identifier);
    _client?.port = _port;
    _client?.keepAlivePeriod = 20;
    _client?.onDisconnected = onDisconnected;
    _client?.logging(on: true);
    if(certificate==1){
      _client?.secure = true;//安全认证  有证书之后是true
    }else{
      _client?.secure = false;//安全认证  没有证书是false
    }
    // 安全认证
    SecurityContext context = SecurityContext.defaultContext;
    _client?.onConnected = onConnected;
    _client?.onSubscribed = onSubscribed;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_identifier)
        .withWillTopic('willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(MqttQos.atMostOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    _client?.connectionMessage = connMess;
    try {
      if(certificate==1){
        context.setTrustedCertificatesBytes(utf8.encode(cert_ca));//安全认证ca.crt赋值
        context.useCertificateChainBytes(utf8.encode(cert_client_crt));//安全认证client.crt赋值
        context.usePrivateKeyBytes(utf8.encode(cert_client_key));//安全认证client.key赋值
        // context.setAlpnProtocols(['TLSv1.0', 'TLSv1.1', 'TLSv1.2', 'TLSv12'],false);// 设置 ALPN 协议   TLS 协议  false 指示是否为服务器请求
      }
    }catch (e) {
      //出现异常 证书配置语法方面的错误
      print("SecurityContext set  error : " + e.toString());
      deviceLogAdd(-1,"证书配置错误$e",'证书配置错误$e');
      return -1;
    }
    if(certificate==1){
      _client?.securityContext = context;//安全证书赋值
    }

    _client?.setProtocolV311();//安全证书相关

    return 0;
  }
  void connect() async{
    assert(_client != null);
    try {
      print('EXAMPLE::Mosquitto start client connecting....');
      await _client?.connect('$MqttUser','$MqttPassword');//需要传递用户名和密码
      print('成功');
      Fluttertoast.showToast(msg: "MQTT连接成功");
      deviceLogAdd('1', 'MQTT连接成功', 'MQTT连接成功');
      //连接成功后每10秒发送一次心跳
      if(mytimer!=null){
        mytimer.cancel();
      }
      startTimer();

    } catch(e) {

      disconnect();
    }
  }
  void startTimer() {
    const period = const Duration(seconds: 10);
    mytimer = Timer.periodic(period, (timer) {
      //到时回调
      send();
    });
  }
  //发送心跳
  send() async{
    print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^");
    String ipsocket = "";
    for (var interface in await NetworkInterface.list()) {
      for (var addr in interface.addresses) {
        ipsocket = '${addr.address}';
        print('${addr.address}');
      }
    }
    StorageUtil.setStringItem('ipAddress',ipsocket);//设备Ip
    deviceID = await StorageUtil.getStringItem('deviceID');
    var diskTotal = 100;//当前总的存储空间
    var diskFree = 100;//当前剩余的存储空间
    double diskPre = 0;//剩余空间占总容量的百分比
    if (diskTotal != null && diskTotal > 0 && diskFree != null) {
      diskPre = 1 - (diskFree / diskTotal);
    }
    var diskPreDou = (diskPre*100).toStringAsFixed(0);

    var memoryTotal = 100;//总物理内存
    var freememoryVal = 100;//空闲的物理内存
    double memoryPre = 1-(freememoryVal/memoryTotal);//剩余空间占总容量的百分比
    var diskPrememory = (memoryPre*100).toStringAsFixed(0);

    //看是否有deviceID
    StorageUtil.getStringItem('deviceID').then((datares) async {
      //发送过心跳
      if(datares != null){
        // print('发送注册完心跳');
        var dataJson = {
          "Memory":"$diskPrememory",
          "Disk":"$diskPreDou",
          "SysVolunme":0,
        };
        var sendData={
          "ClientId":datares,
          "DataType":1,
          "DataJson":dataJson
        };

        print(sendData);
        if(certificate==1){
          var newsenddata = await jiamiasc(sendData);
          String message = encodeBase64(json.encode(newsenddata));
          publishMessage(message);
        }else{
          String message = encodeBase64(json.encode(sendData));
          publishMessage(message);
        }
      }
      else{
        var deviceIDs = DeviceInfo['DeviceId'];
        var deviceName =  DeviceInfo['DeviceName'];
        var deviceVersion = DeviceInfo['DeviceVersion'];
        var systemVersion = DeviceInfo['SystemVersion'];
        Map register = (
            {
              "DeviceId":"",
              "DeviceName":deviceName,
              "IPAddress":ipsocket,
              "MACAddress":deviceIDs,
              "MachineCode":deviceIDs,
              "SystemVersion":systemVersion,
              "DeviceType":"2",
              "DeviceVersion":deviceVersion,
              "Memory":0,
              "DiskFreeSize":0,
              "Location":"",
              "Width":0,
              "Height":0,
              "AuthorizationCode":devicecode,
              "EncryptedSignatureData":"",
              "TcpClientID":"",
              "CurrentStickTime": getDataNowNtp().millisecondsSinceEpoch
            }
        );
        Map sendData={
          "ClientId":"",
          "DataType":0,
          "DataJson":register
        };

        if(certificate==1){
          var newsenddata = await jiamiasc(sendData);
          String message = encodeBase64(json.encode(newsenddata));
          publishMessage(message);
        }else{
          String message = encodeBase64(json.encode(sendData));
          publishMessage(message);
        }

        print(sendData);
      }

    });

  }

  void disconnect() {
    print('Disconnected');
    _client?.disconnect();
  }

  void publish(String message){
    final MqttClientPayloadBuilder builder = MqttClientPayloadBuilder();
    builder.addString(message);
    final payload = builder.payload!; // typed.Uint8Buffer
    if('${_client?.connectionStatus?.state}'=='${MqttConnectionState.connected}'){
      _client?.publishMessage("InfoPublishMqtt_CallBack", MqttQos.atMostOnce, payload);
    }else{
      Fluttertoast.showToast(msg: "MQTT连接处于断开状态");
    }

  }

  /// 订阅的回调
  void onSubscribed(String topic) {
    print('onSubscribed');
  }

  /// 主动断开连接回调
  void onDisconnected() {
//    print('EXAMPLE::OnDisconnected client callback - Client disconnection');
    print('连接断开');
    Fluttertoast.showToast(msg: "MQTT连接断开，10S后进行重连");
    if(mqoffstanum==1){
      //已经上传过MQTT断开连接的日志了，已经掉线了
    }else{
      //还没有上传过连接断开的消息
      deviceLogAdd(19,"MQTT连接断开，10S后进行重连","MQTT连接断开，10S后进行重连");
      mqoffstanum = 1;//MQTT掉线后是1，未连接和正常连接都是0
    }

    Future.delayed(Duration(seconds: 10), (){
      print('重新连接');
      manager?.connect();
    });
    if (_client?.connectionStatus?.disconnectionOrigin == MqttDisconnectionOrigin.solicited) {
      print('EXAMPLE::OnDisconnected callback is solicited, this is correct');
    }
  }

  /// 成功的连接回调
  void onConnected() {
//    _currentState.setAppConnectionState(MQTTAppConnectionState.connected);
    print('EXAMPLE::Mosquitto client connected.....');
    _client?.subscribe(_topic, MqttQos.atMostOnce);
    _client?.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      //接收到的消息
      final MqttPublishMessage recMess = c[0].payload as MqttPublishMessage;;
      final String pt =MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      var message = decodeBase64(pt);
      // print(message);
      // print('EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      Map resBefore = json.decode(message);
      if(certificate==1){
        jiemiascwww(resBefore).then((resstr) {
          Map res = json.decode(resstr);
          arrangeMqttMess(res,message);//后续数据的处理
        });
      }else{
        arrangeMqttMess(resBefore,message);//后续数据的处理
      }


    });
    print('EXAMPLE::OnConnected client callback - Client connection was sucessful');
  }

}
//MQTT数据处理后的一系列操作
arrangeMqttMess(res,message) async {
  Fluttertoast.showToast(msg: "收到DataType是${res['DataType']}的命令");
}
String decodeBase64(String data){
//  return String.fromCharCodes(base64Decode(data));
  return Utf8Decoder().convert(base64Decode(data));
}
//授权信息更改
changAuthorize(sucodeval){
  streamtemplate.add('$sucodeval');
}

bool CompareTime(one, two) {
  DateTime? d1;
  DateTime? d2;
  if (one.runtimeType == String) {
    d1 = DateTime.parse(one);
  } else if (one.runtimeType == DateTime) {
    d1 = one;
  }
  if (two.runtimeType == String) {
    d2 = DateTime.parse(two);
  }else if (two.runtimeType==DateTime)
  {d2=two;}
  if(d1!=null&&d2!=null){
    return d2.isBefore(d1);
  }else{
    return false;
  }
}
//比较两个日期的大小第一个值比第二个值大返回true，否则返回false
bool CompareDate(one, two) {
  DateTime ?d1;
  DateTime ?d2;
  if (one.runtimeType == String) {
    d1 = DateTime.parse(one);
  } else if (one.runtimeType == DateTime) {
    d1 = one;
  }
  if (two.runtimeType == String) {
    d2 = DateTime.parse(two);
  }else if (two.runtimeType==DateTime)
  {d2=two;}
  if(d1!=null&&d2!=null) {
    return d2.isBefore(d1);
  }else{
    return false;
  }

}

//base64加密
String encodeBase64(String data){
  var content = utf8.encode(data);
  var digest = base64Encode(content);
  return digest;
}



