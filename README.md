# Flutter+AppAuthプラグインを使ったOIDCログインサンプル

KeycloadなどのOIDC対応のIdPと連携してログインし、トークンを取得するサンプルアプリのFlutterのサンプルコードです。

[OpenID Foundation](https://openid.net/) のオフィシャルGithubサイト [OpenID](https://github.com/openid) にある [Android版AppAuth](https://github.com/openid/AppAuth-Android) と [iOS版AppAuth](https://github.com/openid/AppAuth-iOS) をベースに開発された [Flutter版AppAuth](https://github.com/MaikuB/flutter_appauth) である [flutter_appauthプラグイン](https://pub.dev/packages/flutter_appauth) を利用して、それなりの品質 & 低コストで開発することが可能です。

## 前提条件
1. インターネット経由でアクセス可能な管理者権限をもったKeycloakの環境が用意されていること (参考: https://www.keycloak.org/docs/latest/server_installation/)
2. Flutterの環境がインストールされていること (参考: https://flutter.dev/docs/get-started/install)
3. Flutterのサンプルアプリを開発PC経由でAndroid端末及びiPhoneに対して"flutter run"コマンドでコンパイル&実行することができること。iPhoneで試す場合はApple Developerのライセンス取得やXCodeの設定等が必要なのでこのあたりの操作に慣れていることも必要です。

## バージョン
- Flutter: 2.5
- Flutter AppAuthプラグイン: 2.0.0-dev.3 (endSessionEndpointが追加された)
- Android OS: 11
- iOS: 14
- Keycloak: 15

## Keycloakの設定手順
Keycloakにレルムを追加し、クライアントとユーザを追加します。Keycloakの設定方法の詳細は[Keycloakサーバ管理のオフィシャルドキュメント](https://www.keycloak.org/docs/latest/server_admin/)を参照します。
1. Keycloakの管理コンソールに管理者としてログインします。URLは通常 "https://[ホスト名]/auth/" で表示されるページから「Administration Console」に遷移するとKeycloak全体の管理コンソールに移動します。
2. 画面左の「Select realm」メニューを開いて「Add realm」を押下し、Nameに組織を表す名前を適当に記載し、「Create」ボタンを押下します。
3. 作成されたレルムに対して以下の設定を行います。
- 左メニュー「Realm Settings」>「Login」タブ >「User registration」から「Verify email」までにチェックを入れて「Save」(「Email as username」のチェックを外すとemailの代わりにユーザ名でログインできるようになります)
- 左メニュー「Realm Settings」>「Themes」タブ >「Internationalization Enabled」をオンにして、デフォルトロケールを「ja」にして「Save」
4. レルムに管理ユーザを作成します。
- 左メニュー「Users」> 右上「Add user」ボタンクリック >「Username」ほかを設定し「Email Verified」をオン
- 「Credentials」タブのパスワードをセットして「Temporary」を外して「Set password」ボタンをクリック
- 「Role Mappings」タブ >「Client Roles」に「realm-management」と入力すると「Available Roles」がリストされるのですべて「Assigned Roles」に移動し、ユーザにレルムの管理者権限を付与
5. レルムにクライアントと一般ユーザを作成します。
- レルムにレルム管理者としてログイン (https://[ホスト名]/auth/admin/[レルム名]/console/)
- 左メニュー「クライアント」> 右上「作成」ボタンをクリック
- クライアントIDに適当なクライアント名を設定して保存
- 「有効なリダイレクトURI」に「*」を設定 (アスタリスクで全リダイレクトURLを許可するのはセキュリティ上問題なので、本来は正確なリダイレクトURIのみを指定する必要があります)
- 「アクセスタイプ」を「Confidential」に設定
- 「クレデンシャル」タブをクリックして、「クライアント認証」が「Client Id and Secret」になっていることを確認して、「シークレット」の文字列をあとで「クライアントシークレット」として使うのでコピー
- 左メニュー「ユーザ」> 右上「ユーザの追加」ボタンクリック
- 「ユーザ名」ほかを設定し「Eメールが確認済み」をオン
- 「クリデンシャル」タブのパスワードをセットして「一時的」を外して「Set password」ボタンをクリック
- レルムに一般ユーザとしてログインできることを確認 (https://[ホスト名]/auth/realms/[レルム名]/account)

※ 以上はOIDCログインを行うために必要な設定の一例です。

## 本Flutterアプリの導入手順
1. FlutterのAppAuthに設定する値を上述で作成したKeycloakのレルムから取得します。あとでプログラミングに使うのでどこかにメモしておきましょう。
- クライアント名(CLIENT_NAME)とクライアントシークレット(CLIENT_SECRET)
- ディスカバリURL(DISCOVERY_URL): https://[Keycloakへのアドレス]/auth/realms/apilabeyes/.well-known/openid-configuration の形式になります。
- リダイレクトURL(REDIRECT_URL): カスタムスキーマといい、ネイティブアプリがWebViewを開いて処理が終わったらWebViewをクローズしてネイティブアプリに操作を戻すトリガーに使います。"[何らかの文字列]://callback"という形式をとり、ここでは"oidc://callback"としています。"://callback"部分はiOS用に設定する値でこのような形式の文字列がないとiOSでWebViewはクローズしません。一方、Androidでは後述する「build.gradle」ファイルと「AndroidManifest.xml」ファイルにリダイレクトURLを設定しますが、"://callback"を除いた値"oidc"を設定します。(参考: [カスタムスキームではじまるリダイレクト URI](https://qiita.com/TakahikoKawasaki/items/8567c80528da43c7e844#%E3%82%AB%E3%82%B9%E3%82%BF%E3%83%A0%E3%82%B9%E3%82%AD%E3%83%BC%E3%83%A0%E3%81%A7%E3%81%AF%E3%81%98%E3%81%BE%E3%82%8B%E3%83%AA%E3%83%80%E3%82%A4%E3%83%AC%E3%82%AF%E3%83%88-uri))

3. 本リポジトリをcloneして持ってきます。
```
$ git clone https://github.com/apilabeyes/oidc.git
```

4. "lib/main.dart"ファイルを開き、下記の箇所を上述2の通り編集します。
```
// IdP情報をこちらに設定してください
const String CLIENT_NAME = "(クライアント名)";
const String CLIENT_SECRET = "(クライアントシークレット)";
const String DISCOVERY_URL = "(ディスカバリURL)";
const String REDIRECT_URL = "oidc://callback";
```

5. [Android用設定] "android/app/build.gradle"ファイルに下記のカスタムスキーマが設定されていることを確認します。この場合、Androidの設定のため、"://callback"が付与されていません。
```
        manifestPlaceholders = [
            'appAuthRedirectScheme': 'oidc'
        ]
```
参考: https://github.com/openid/AppAuth-Android#capturing-the-authorization-redirect

6. [Android用設定] "android/app/src/main/AndroidManifest.xml"ファイルに下記のカスタムスキーマが設定されていることを確認します。この場合、Androidの設定のため、"://callback"が付与されていません。
```
        <activity android:name="net.openid.appauth.RedirectUriReceiverActivity">
          <intent-filter>
              <action android:name="android.intent.action.VIEW"/>
              <category android:name="android.intent.category.DEFAULT"/>
              <category android:name="android.intent.category.BROWSABLE"/>
              <data android:scheme="oidc"/>
          </intent-filter>
        </activity>
```
参考: https://github.com/openid/AppAuth-Android#capturing-the-authorization-redirect

7. [Android用設定] target APIが30以上の場合、"android/app/src/main/AndroidManifest.xml"ファイルに下記の記述が必要なので、この記述があることを確認します。
```
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.APP_BROWSER" />
        <data android:scheme="https" />
    </intent>
</queries>
```
参考: https://pub.dev/packages/flutter_appauth

8. [iOS用設定] "ios/Runner/Info.plist"ファイルに下記のカスタムスキーマが設定されていることを確認します。この場合、iOSの設定のため、"://callback"が付与されています。
```
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>oidc://callback</string>
            </array>
        </dict>
    </array>
```

9. Android端末を開発PCに認識させコンパイル&実行します。
```
$ flutter build appbundle
$ flutter devices
(認識された実行環境がリストされますのでそこにAndroid端末が含まれることを確認)
$ flutter run -d "(Android端末名)"
```

10. iPhoneを開発PCに認識させコンパイル&実行します。途中、XCodeを使ってApple Developerライセンスを認識させたり、CocoaPodをインストールするといった作業が必要です。
```
$ flutter build ios
$ flutter devices
(認識された実行環境がリストされますのでそこにiPhoneが含まれることを確認)
$ flutter run -d "(iPhone名)"
```

以上