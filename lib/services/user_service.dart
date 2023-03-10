import 'package:ant/models/balance_model.dart';
import 'package:ant/widgets/login_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  static Future<BalanceModel> isLogin(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final login = prefs.getString('login');

    if ((login?.isEmpty ?? true) && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const Login(),
        ),
      );
    }
    switch (login) {
      case 'kakao':
        KakaoSdk.init(
          nativeAppKey: dotenv.env['KAKAO_NATIVE_APP_KEY'],
        );
        OAuthToken? auth;

        if ((await AuthApi.instance.hasToken()) == false) {
          try {
            auth = await isKakaoTalkInstalled()
                ? await UserApi.instance.loginWithKakaoTalk()
                : await UserApi.instance.loginWithKakaoAccount();
          } catch (e) {
            if (kDebugMode) {
              switch (e.runtimeType) {
                case PlatformException:
                  final p = e as PlatformException;
                  print(
                    {
                      p.code,
                      p.details,
                      p.message,
                      p.stacktrace,
                    },
                  );
                  break;

                case KakaoAuthException:
                  final ka = e as KakaoAuthException;
                  print(
                    {
                      ka.error,
                      ka.errorDescription,
                      ka.message,
                      await KakaoSdk.origin,
                    },
                  );
                  break;
              }
            }
          }
        }
        final info = await UserApi.instance.accessTokenInfo();
        final user = await UserApi.instance.me();

        if (kDebugMode) {
          if (auth != null && auth.scopes != null) {
            for (var scope in auth.scopes!) {
              print(scope);
            }
          }
          print(
            {
              info.id,
              info.appId,
              info.expiresIn,
              auth?.accessToken,
              auth?.refreshToken,
              auth?.idToken,
              user.kakaoAccount?.name,
              user.kakaoAccount?.email,
              user.groupUserToken,
            },
          );
        }
        return BalanceModel(
          id: info.id,
          name: user.kakaoAccount?.name,
          type: login,
        );
    }
    return BalanceModel(
      type: login,
    );
  }
}
