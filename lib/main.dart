import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fmradioplayer/modules/HomeScreen/view/notification.dart';
import 'package:fmradioplayer/modules/SplashScreen/view/splash_screen.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'utility/color_utility.dart';

GetStorage getStorage = GetStorage();

void main() async {
  await GetStorage.init();
  WidgetsFlutterBinding.ensureInitialized();
  NotificationService().initNotification();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    return GetMaterialApp(
      // localizationsDelegates: const [CountryLocalizations.delegate],
      // initialBinding: AppBinding(),
      theme: ThemeData(scaffoldBackgroundColor: colorWhite),
      builder: (context, widget) => ResponsiveWrapper.builder(
        ClampingScrollWrapper.builder(context, widget!),
        maxWidth: 1200,
        minWidth: 420,
        defaultScale: true,
        breakpoints: [
          const ResponsiveBreakpoint.resize(420, name: MOBILE),
          const ResponsiveBreakpoint.autoScale(800, name: TABLET),
          const ResponsiveBreakpoint.autoScale(1000, name: TABLET),
          const ResponsiveBreakpoint.resize(1200, name: DESKTOP),
          const ResponsiveBreakpoint.autoScale(2460, name: "4K"),
        ],
      ),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
