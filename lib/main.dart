import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_appauth/flutter_appauth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
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
                fontSize: 5,
              ),
            ),
            SizedBox(height: 5.0),
            RaisedButton(
              onPressed: () async {
                FlutterAppAuth appAuth = FlutterAppAuth();
                AuthorizationTokenResponse result;
                try {
                  result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      "myapp",
                      "com.example.oidc:/callback",
                      clientSecret: "6343dc13-10ec-49b6-bfb7-fd1c5d3dcf7a",
                      discoveryUrl: "https://keycloak.sonrisa.co.jp/auth/realms/kong/.well-known/openid-configuration",
                    ),
                  );
                } on PlatformException catch (err) {
                  print("PlatformException: ${err.message}");
                } catch (err) {
                  print("Exception: ${err.message}");
                }
                setState(() {
                  accessToken = result.accessToken;
                });
              },
              child: Text("Token発行"),
            ),
          ],
        ),
      ),
    );
  }
}
