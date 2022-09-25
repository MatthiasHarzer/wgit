import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/config_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';

import 'drawer/main_page_drawer.dart';
import 'firebase_options.dart';
import 'theme.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ConfigService.ensureInitialized();
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
  HouseHold? _currentHousehold;

  @override
  void initState(){
    super.initState();

    FirebaseService.availableHouseholds.listen((households) {
        if(_currentHousehold == null){
          var resolved = households.where((household) => household.id == ConfigService.currentHouseholdId);
          if(resolved.length == 1){
            _switchToHousehold(resolved.first);
            // _currentHousehold = resolved.first;
          }
        }
    });
  }

  void open(){

    // FirebaseService.createHousehold("Test Haus 222222222222");
  }

  void _switchToHousehold(HouseHold household){
    print("Switching to $household");
    ConfigService.currentHouseholdId = household.id;
    setState((){
      _currentHousehold = household;
    });
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
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
      drawer: MainPageDrawer(
        onSwitchTo: _switchToHousehold,
      ),
    );
  }
}
