import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

// IdP情報をこちらに設定してください
const String CLIENT_NAME = "demoapp";
const String CLIENT_SECRET = "1cf337d0-1731-48cb-a6f9-97c2e54e64a5";
const String DISCOVERY_URL =
    "https://keycloak.briscola-api.net/auth/realms/apilabeyes/.well-known/openid-configuration";
const String REDIRECT_URL = "oidc://callback";

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OIDCデモ',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  var appAuth = FlutterAppAuth();
  String accessToken = "";
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              accessToken,
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 5,
                fontFamily: 'NotoSerif',
                fontWeight: FontWeight.normal,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: 5.0),
            ElevatedButton(
              child: Text("ログイン"),
              onPressed: () async {
                AuthorizationTokenResponse? result;
                try {
                  result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      CLIENT_NAME,
                      REDIRECT_URL,
                      promptValues: ['login'],
                      clientSecret: CLIENT_SECRET,
                      discoveryUrl: DISCOVERY_URL,
                    ),
                  );
                } on PlatformException catch (err) {
                  print("PlatformException: ${err.message}");
                }
                setState(() {
                  accessToken = result!.accessToken!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
