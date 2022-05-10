import 'package:flutter/material.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:ncmb/ncmb.dart';

void main() {
  // NCMBの初期化
  NCMB('YOUR_APPLICATION_KEY', 'YOUR_CLIENT_KEY');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  NCMBUser? _user;
  // TwitterのConsumer Key（APIキー）
  final _apiKey = 'YOUR_TWITTER_API_KEY';
  // TwitterのConsumer Secret Key（APIシークレットキー）
  final _apiSecretKey = 'YOUR_TWITTER_API_SECRET_KEY';
  // アプリのURIスキーム
  final _sheme = 'ncmbauth://';

  @override
  void initState() {
    super.initState();
    Future(() async {
      // 現在ログインしているユーザー情報（未ログインの場合はnull）を取得
      final user = await NCMBUser.currentUser();
      setState(() {
        _user = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Twitter Login App'),
        ),
        body: Center(
            child: _user == null
                // 未ログインの場合
                ? TextButton(
                    child: const Text('Login With Twitter'),
                    onPressed: login,
                  )
                // ログインしている場合
                : TextButton(
                    child: Text(
                        'Logged in by ${_user!.getString('displayName', defaultValue: 'No name')}'),
                    onPressed: logout,
                  )),
      ),
    );
  }

  // ログアウト処理
  logout() async {
    await NCMBUser.logout();
    setState(() {
      _user = null;
    });
  }

  // ログイン処理
  login() async {
    // Twitterでのログイン情報
    final twitterLogin = TwitterLogin(
      apiKey: _apiKey,
      apiSecretKey: _apiSecretKey,
      redirectURI: _sheme,
    );
    // ログインを実行して結果を受け取る
    final authResult = await twitterLogin.login();
    switch (authResult.status!) {
      case TwitterLoginStatus.loggedIn:
        // ログイン成功
        // ユーザーデータは繰り返し使うので取り出す
        final userData = authResult.user!;
        // 認証用データの作成
        final data = {
          'oauth_token': authResult.authToken,
          'oauth_token_secret': authResult.authTokenSecret,
          'oauth_consumer_key': _apiKey,
          'consumer_secret': _apiSecretKey,
          'id': userData.id.toString(), // 文字列で指定します
          'screen_name': userData.screenName,
        };
        // ログイン実行
        var user = await NCMBUser.loginWith('twitter', data);
        // 表示名を追加
        user.set('displayName', userData.screenName);
        // 更新実行
        await user.save();
        // 表示に反映
        setState(() {
          _user = user;
        });
        // success
        break;
      case TwitterLoginStatus.cancelledByUser:
        // 認証をキャンセルした場合
        debugPrint('TwitterLoginStatus.cancelledByUser');
        break;
      case TwitterLoginStatus.error:
        // 認証でエラーが発生した場合
        debugPrint('TwitterLoginStatus.error');
        break;
    }
  }
}
