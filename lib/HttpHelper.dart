import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class HttpClientHelper {
  Future<Map<String, dynamic>?> httpGet(String url,{required Map<String,String> headers}) async {
    var httpClient = new HttpClient();

    try {
      var request = await httpClient.getUrl(Uri.parse(url));

      //头部信息
      //request.headers.set('content-type', 'application/json');//Content-Type大小写都ok
      if(headers.isNotEmpty) {
        for(var name in headers.keys) {
          request.headers.set(name, headers[name]!);
        }
      }

      var response = await request.close();
      print("statusCode:${response.statusCode}");

      if (response.statusCode == HttpStatus.ok) {
        var responseBody = await response.transform(utf8.decoder).join();
        var data = jsonDecode(responseBody);
        print(responseBody);
        return data;
      } else {
        print('Error getting IP address:\n url:$url，Http status ${response.statusCode}');
      }
    } catch (exception) {
      print('Fail getting IP address,url:$url,$exception');
    }
    return null;
  }

  Future<String?> httpGetString(
      String url, {
        Map<String, String>? headers,
      }) async {
    // 这里的 headers 如果不传就给个空 Map
    final Map<String, String> safeHeaders = headers ?? {};
    final result = await this.httpGet(url, headers: safeHeaders);
    // result 可能是 null，也可能是 Map<String, dynamic>
    return result?.toString();
  }

  Future<Map<String, dynamic>?> httpPost(
      String url, {
        Map<String, String>? headers,
        String? body,
      }) async {
    var httpClient = HttpClient();
    try {
      var request = await httpClient.postUrl(Uri.parse(url));

      // 设置请求头
      request.headers.set('content-type', 'application/json');
      if (headers != null && headers.isNotEmpty) {
        for (var name in headers.keys) {
          request.headers.set(name, headers[name]!);
        }
      }

      // 写入请求体
      if (body != null) {
        request.write(body);
      }

      var response = await request.close();
      debugPrint("statusCode: ${response.statusCode}");
      if (response.statusCode == HttpStatus.ok) {
        debugPrint(response.headers.toString()); // 打印头部信息
        String responseBody = await response.transform(utf8.decoder).join();
        var data = jsonDecode(responseBody);
        return data is Map<String, dynamic> ? data : null;
      } else {
        debugPrint(
          'Error getting IP address:\n url:$url, Http status ${response.statusCode}',
        );
      }
    } catch (exception) {
      debugPrint('Fail getting IP address, url:$url, $exception');
    }
    return null;
  }

  Future<String?> httpPostString(
      String url, {
        Map<String, String>? headers,
      }) async {
    final result = await this.httpPost(url, headers: headers);
    return result?.toString();
  }
}

class HttpDioHelper {
  final _timeout = 30000;

  ///Get请求
  ///url和path可拼接也可以只填一个
  Future<dynamic> httpDioGet(
      String url,
      String path, {
        Map<String, dynamic>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      Dio dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: Duration(milliseconds: _timeout),
          receiveTimeout: Duration(milliseconds: _timeout),
        ),
      );

      // 设置请求头
      Options options = Options();
      if (headers != null && headers.isNotEmpty) {
        options.headers = headers;
      }

      Response response = await dio.get(
        path,
        options: options,
        queryParameters: body,
      );
      return response; // 若成功，直接返回响应
    } catch (e) {
      debugPrint('Error getting IP address, url: $url$path, $e');
      // 若是 DioError
      if (e is DioError) {
        // 这里可根据业务逻辑判断返回什么
        if (e.error == "Http status error [403]") {
          Response response = Response(
            statusCode: 400,
            data: {'code': '400'},
            requestOptions: RequestOptions(path: path),
          );
          return response;
        } else {
          Response response = Response(
            statusCode: 400,
            data: {'code': '400'},
            requestOptions: RequestOptions(path: path),
          );
          return response;
        }
      }
      return null;
    }
  }
  /// GET 请求（参数是 String）
  Future<dynamic> httpDioGetSendString(
      String url,
      String path, {
        Map<String, dynamic>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      Dio dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: Duration(milliseconds: _timeout),
          receiveTimeout: Duration(milliseconds: _timeout),
        ),
      );

      // 设置请求头
      Options options = Options(contentType: "application/json");
      if (headers != null && headers.isNotEmpty) {
        options.headers = headers;
      }

      Response response = await dio.get(
        path,
        options: options,
        queryParameters: body,
      );
      return response;
    } catch (e) {
      debugPrint('Error getting IP address, url: $url$path, $e');
      if (e is DioError) {
        if (e.error == "Http status error [403]") {
          Response response = Response(
            statusCode: 400,
            data: {'code': '400'},
            requestOptions: RequestOptions(path: path),
          );
          return response;
        } else {
          Response response = Response(
            statusCode: 400,
            data: {'code': '400'},
            requestOptions: RequestOptions(path: path),
          );
          return response;
        }
      }
      return null;
    }
  }

  /// 发送 POST 请求，application/json
  Future<dynamic> httpDioPost(
      String url,
      String path, {
        Map<String, dynamic>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      Dio dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: Duration(milliseconds: _timeout),
          receiveTimeout: Duration(milliseconds: _timeout),
        ),
      );

      Options options = Options(contentType: "application/json");
      if (headers != null && headers.isNotEmpty) {
        options.headers = headers;
      }

      Response response = await dio.post(
        path,
        data: body,
        options: options,
      );
      return response;
    } catch (e) {
      // 捕获异常后，返回一个自定义响应
      Response response = Response(
        statusCode: 400,
        data: {'code': '400'},
        requestOptions: RequestOptions(path: path),
      );
      return response;
    }
  }
  ///发送POST请求，application/x-www-form-urlencoded
  Future<dynamic> postUrlencodedDio(String url,String path,{Map<String,String>? headers,Map<dynamic,dynamic>? body}) async {
    try {
      Dio dio = Dio(BaseOptions(
          baseUrl: url,
        connectTimeout: Duration(milliseconds: _timeout),
        receiveTimeout: Duration(milliseconds: _timeout),
      ));

      //设置请求头
      Options options = Options(contentType: "application/x-www-form-urlencoded");
      if(headers != null && headers.length > 0) {
        options.headers = headers;
      }

      Response response = await dio.post(path,data: body,options: options);
      // print("Code:${response.statusCode}");

      // if(response.statusCode == 200) {
      //   print('Success getting IP address,url:$url,response:${response.data}');
      // } else {
      //   print('Failed getting IP address,url:$url');
      // }
      return response ?? "";
    } catch(e) {
      print('Error getting IP address,url:$url，$e');

      Response response = Response(
        statusCode: 400,
        data: {'code': '400'},
        requestOptions: RequestOptions(path: path),
      );
      return response;
      // throw(e);
    }
  }

  /// 发送POST请求，multipart/form-data
  Future<dynamic> postFormDataDio(
      String url,
      String path, {
        Map<String, dynamic>? headers,
        Map<String, dynamic>? body,
      }) async {
    try {
      Dio dio = Dio(
        BaseOptions(
          baseUrl: url,
          connectTimeout: Duration(milliseconds: _timeout),
          receiveTimeout: Duration(milliseconds: _timeout),
        ),
      );

      Options options = Options(contentType: "multipart/form-data");
      if (headers != null && headers.isNotEmpty) {
        options.headers = headers;
      }

      FormData? formData;
      if (body != null && body.isNotEmpty) {
        formData = FormData.fromMap(body);
      }

      Response response = await dio.post(
        path,
        data: formData,
        options: options,
      );

      debugPrint("Code:${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint('Success: url:$url$path, response:${response.data}');
      } else {
        debugPrint('Failed: url:$url$path');
      }
      return response;
    } catch (e) {
      Response response = Response(
        statusCode: 400,
        data: {'code': '400'},
        requestOptions: RequestOptions(path: path),
      );
      return response;
    }
  }
  ///下载文件
  ///url和urlPath可拼接也可以只填一个
  Future<void> downloadFileDio(
      String url,
      String urlPath,
      String savePath, {
        Map<String, String>? headers,
      }) async {
    Dio dio = Dio();
    dio.options.baseUrl = url;

    try {
      await dio.download(
        urlPath,
        savePath,
        onReceiveProgress: (count, total) {
          if (total > 0) {
            debugPrint("${(count / total * 100).toStringAsFixed(0)}%");
          }
        },
      );
    } catch (e) {
      debugPrint('Error downloading file, url:$url, $e');
      rethrow;
    }
  }

  ///上传文件，发送POST请求，multipart/form-data
  Future<void> uploadFileDio(
      String url,
      String urlPath,
      Map<String, String> files, {
        Map<String, String>? headers,
        Map<String, String>? body,
      }) async {
    Dio dio = Dio();
    dio.options.baseUrl = url;

    Options options = Options();
    if (headers != null && headers.isNotEmpty) {
      options.headers = headers;
    }

    Map<String, dynamic> map = {};
    // 构造 files
    map["files"] = await _getFileFormData(files);

    // 若有额外表单字段
    if (body != null && body.isNotEmpty) {
      for (var key in body.keys) {
        map[key] = body[key];
      }
    }

    FormData formData = FormData.fromMap(map);

    try {
      Response response = await dio.post(
        urlPath,
        options: options,
        data: formData,
      );
      debugPrint("Code:${response.statusCode}");
      if (response.statusCode == 200) {
        debugPrint('Success uploading, url:$url, response:${response.data}');
      } else {
        debugPrint('Failed uploading, url:$url');
      }
    } catch (e) {
      debugPrint('Error uploading file, url:$url, $e');
      rethrow;
    }
  }

  Future<List<MultipartFile>> _getFileFormData(Map<String, String> files) async {
    List<MultipartFile> list = [];
    if (files.isNotEmpty) {
      for (var key in files.keys) {
        list.add(
          await MultipartFile.fromFile("${files[key]}", filename: key),
        );
      }
    }
    return list;
  }

}

class DownLoadManage {
  // 单例公开访问点
  factory DownLoadManage() => _getInstance();
  static DownLoadManage get instance => _getInstance();
  static DownLoadManage? _instance;

  // 私有构造
  DownLoadManage._();

  // 静态、同步、私有访问点
  static DownLoadManage _getInstance() {
    _instance ??= DownLoadManage._();
    return _instance!;
  }

  // 用于记录正在下载的 url，避免重复下载
  var downloadingUrls = <String>[];

  /// 分块下载文件示例
  Future<void> downloadWithChunks(
      String url,
      String savePath, {
        ProgressCallback? onReceiveProgress,
      }) async {
    const firstChunkSize = 102;
    const maxChunk = 3;

    int total = 0;
    var dio = Dio();
    var progress = <int>[];
    File file = File(savePath);

    debugPrint('下载地址：$savePath');

    // 1. 文件若已存在，视为已下载完毕
    if (await file.exists()) {
      downloadingUrls.remove(url);
      return;
    }

    // 2. 若正在下载同一资源，直接 return
    if (downloadingUrls.contains(url)) {
      return;
    }
    downloadingUrls.add(url);

    createCallback(int no) {
      return (int received, _) {
        progress[no] = received;
        if (onReceiveProgress != null && total != 0) {
          onReceiveProgress(progress.reduce((a, b) => a + b), total);
        }
      };
    }

    Future<Response?> downloadChunk(String url, int start, int end, int no) async {
      progress.add(0);
      --end;

      File tempFile = File("$savePath.temp$no");
      int tempChunkSize = end - start;
      if (end > total) {
        tempChunkSize = total - start;
      }
      int tempFileSize = 0;
      if (await tempFile.exists()) {
        tempFileSize = tempFile.lengthSync();
      }

      // 临时文件若已经大于等于本分块大小，则视为已下载
      if (tempFileSize >= tempChunkSize) {
        return null;
      }

      // 否则继续下载
      if (tempFileSize > 0) {
        start += tempFileSize;
        Response response = await dio.get(
          url,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: false,
            headers: {"range": "bytes=$start-$end"},
          ),
          onReceiveProgress: createCallback(no),
        );
        IOSink tempSink = tempFile.openWrite(mode: FileMode.writeOnlyAppend);
        await tempSink.addStream((response.data as ResponseBody).stream);
        await tempSink.close();
        return response;
      } else {
        return dio.download(
          url,
          "$savePath.temp$no",
          onReceiveProgress: createCallback(no),
          options: Options(
            headers: {"range": "bytes=$start-$end"},
          ),
        );
      }
    }

    Future<void> mergeTempFiles(int chunk) async {
      File f = File("$savePath.temp0");
      IOSink ioSink = f.openWrite(mode: FileMode.writeOnlyAppend);
      for (int i = 1; i < chunk; i++) {
        File _f = File("$savePath.temp$i");
        await ioSink.addStream(_f.openRead());
        await _f.delete();
      }
      await ioSink.close();
      await f.rename(savePath);
    }

    try {
      Response response = await dio.head(url);
      if (response.statusCode == 200) {
        total = int.parse(response.headers.value(HttpHeaders.contentLengthHeader) ?? '0');
        int chunk = (total / firstChunkSize).ceil();
        int chunkSize = firstChunkSize;
        if (chunk > maxChunk) {
          chunk = maxChunk;
          chunkSize = (total / maxChunk).ceil();
        }
        var futures = <Future>[];
        for (int i = 0; i < maxChunk; i++) {
          int start = i * chunkSize;
          futures.add(downloadChunk(url, start, start + chunkSize, i));
        }
        await Future.wait(futures);
        await mergeTempFiles(chunk);
      }
    } catch (e) {
      debugPrint('downloadWithChunks error: $e');
    } finally {
      downloadingUrls.remove(url);
    }
  }
}


class UploadManage {
  factory UploadManage() => _getInstance();
  static UploadManage? _instance;

  UploadManage._();

  static UploadManage _getInstance() {
    _instance ??= UploadManage._();
    return _instance!;
  }

  Future<dynamic> isResume(String url) async {
    Dio dio = Dio();
    var res = await dio.get(url);
    return res.data;
  }

  /// 上传文件示例，multipart/form-data
  Future<void> uploadFileDio(
      String url,
      Map<String, dynamic> files, {
        Map<String, dynamic>? headers,
        Map<String, dynamic>? body,
      }) async {
    // 设置请求头
    Options options = Options();
    if (headers != null && headers.isNotEmpty) {
      options.headers = headers;
    }

    body ??= {};

    // 构造 FormData
    body["files"] = await _getFileFormData(files);
    FormData formData = FormData.fromMap(body);

    Dio dio = Dio();
    try {
      await dio.post(
        url,
        options: options,
        data: formData,
        onSendProgress: (int count, int total) {
          debugPrint("count:$count, total:$total => ${(count / total * 100).floor()}%");
        },
      );
    } catch (e) {
      debugPrint('Error uploading file, url:$url, $e');
      rethrow;
    }
  }

  Future<List<MultipartFile>> _getFileFormData(Map<String, dynamic> files) async {
    List<MultipartFile> list = [];
    if (files.isNotEmpty) {
      for (var key in files.keys) {
        list.add(await MultipartFile.fromFile("${files[key]}", filename: key));
      }
    }
    return list;
  }
}