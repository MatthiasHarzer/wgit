import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/firebase/firebase_service.dart';

import 'drawer/main_page_drawer.dart';
import 'firebase_options.dart';
import 'theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseService.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WG IT',
      theme: ThemeData(
        iconTheme: IconThemeData(
          color: Colors.grey[350]
        ),
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? Colors.deepOrangeAccent
                : null),
            trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected)
                ? Colors.deepOrange[500]
                : null),
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: Colors.grey.shade900,
            contentTextStyle: TextStyle(color: Colors.grey[200]),
            actionTextColor: Colors.deepOrangeAccent,
          ),
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});


  @override
  State<MainPage> createState() => _MainPageState();
}



class _MainPageState extends State<MainPage> {

  void open(){

    FirebaseService.createHousehold("Test Haus 222222222222");
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(""),
      ),
      body: Center(
        child: IconButton(
          icon: Icon(Icons.plumbing, size: 50,),
          onPressed: (){
            open();
          },
        )

      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
      drawer: MainPageDrawer(),
    );
  }
}
