import 'dart:io' show Platform;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wakelock/wakelock.dart';
import 'package:qr_flutter/qr_flutter.dart';

// 직원 호출 요청 함수
void sendStaffCallToServer() async {
  final url = Uri.parse('http://13.209.77.79:3003/send-email');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: '''
      {
        "subject": "도서관 직원 호출",
        "message": "도서관에서 직원 호출 버튼이 눌렸습니다. 위치: 송내동 작은 도서관"
      }
    ''',
  );

  if (response.statusCode == 200) {
    print('이메일 전송 성공');
  } else {
    print('이메일 전송 실패: ${response.statusCode}');
  }
}

// 서버 상태 확인 함수
Future<String> fetchStatus() async {
  final url = Uri.parse('http://13.209.77.79:3003/status');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'] ?? "available";
    }
    return "available";
  } catch (e) {
    return "available";
  }
}

// 앱 시작
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isLinux) {
    await Wakelock.enable();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Library App',
      theme: ThemeData(
        fontFamily: 'NotoSansKR',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
      ),
      home: const MyHomePage(title: ''),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String currentStatus = "available";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    final status = await fetchStatus();
    setState(() {
      currentStatus = status;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String surveyUrl =
        "https://docs.google.com/forms/d/e/1FAIpQLSdtQmP_lv8nBxMlszcpGnRuo__AI-5I0eDKKCghnAx5EkqU5g/viewform?usp=dialog";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(widget.title),
        centerTitle: true, // ✅ 앱바 제목 중앙정렬
      ),
      body: currentStatus == "outdoor"
          ? const Center(
              child: Text(
                '현재 외근중입니다.',
                style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            )
          : SafeArea( // ✅ SafeArea로 감싸기
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 중앙에 위치하도록 Expanded 사용
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '도서 대출 및 도움 요청',
                            style: TextStyle(
                              fontSize: 42,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),
                          ElevatedButton(
                            onPressed: () {
                              sendStaffCallToServer();
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  Future.delayed(const Duration(seconds: 10), () {
                                    if (Navigator.of(context).canPop()) {
                                      Navigator.of(context).pop();
                                    }
                                  });
                                  return const AlertDialog(
                                    title: Text('알림'),
                                    content: Text('곧 도와드리겠습니다.'),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              '직원 호출하기',
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 70),
                          const Text(
                            '대출 및 반납 가능 시간 10:00 ~ 16:00',
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 푸터 (항상 맨 아래)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        QrImageView(
                          data: surveyUrl,
                          version: QrVersions.auto,
                          size: 150.0,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '송내동 작은도서관 설문',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

