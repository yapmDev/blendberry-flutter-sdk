import 'package:blendberry_flutter_sdk/blendberry_flutter_sdk.dart';
import 'package:example/impl/mapper.dart';
import 'package:example/impl/mediator.dart';
import 'package:example/util/pref_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SharedPrefsManager.init();
  final mediator = RemoteConfigMediatorImpl.instance;
  await mediator.loadConfigs(Environment.staging.value);
  final customRemoteConfig = mediator.dispatch(CustomMapper());
  if (kDebugMode) {
    print(customRemoteConfig.useDarkTheme);
  }
  runApp(MaterialApp(theme: ThemeData.light(), darkTheme: ThemeData.dark(), home: Material(child: MyApp())));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return Center(child: Text("HELLO WORLD"));
  }
}