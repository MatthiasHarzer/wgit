import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/config_service.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/views/household_view.dart';

import 'drawer/main_page_drawer.dart';
import 'firebase_options.dart';
import 'theme.dart';

void main() async {
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
          iconTheme: IconThemeData(color: Colors.grey[350]),
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
          brightness: Brightness.dark),
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
  final GlobalKey<ScaffoldState> _key = GlobalKey();

  TextStyle get buttonStyle => TextStyle(
        color: theme.colorScheme.primary,
        fontSize: 18,
      );
  @override
  void initState() {
    super.initState();

    AuthService.stateChange.listen((u) => setState(() {}));

    FirebaseService.availableHouseholds.listen((households) {
      if (_currentHousehold == null && households.isNotEmpty) {
        var resolved = households.where(
            (household) => household.id == ConfigService.currentHouseholdId);
        if (resolved.length == 1) {
          _switchToHousehold(resolved.first);
          // _currentHousehold = resolved.first;
        } else {
          // Switch to any available household
          _switchToHousehold(households.first);
        }
      }
    });
  }

  void open() {
    // FirebaseService.createHousehold("Test Haus 222222222222");
  }

  void _switchToHousehold(HouseHold household) {
    print("Switching to $household");
    ConfigService.currentHouseholdId = household.id;
    setState(() {
      _currentHousehold = household;
    });
  }

  /// Builds the appbar title depending on [_currentHousehold]
  Widget _buildAppBarTitle() {
    if (_currentHousehold == null) {
      return const Text("WGit");
    } else {
      return Text(_currentHousehold!.name);
    }
  }

  void _signInTaped() async {
    _key.currentState!.openDrawer();
    await AuthService.signInWithGoogle();
  }

  /// Builds the widget if the user is not in any household
  Widget _buildNoHouseholdView() {
    if (!AuthService.signedIn) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "You need to be signed in to view your households.",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          MaterialButton(
            onPressed: _signInTaped,
            child: Text(
              "SIGN IN",
              style: buttonStyle,
            ),
          )
        ],
      );
    }
    return Text("");
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      key: _key,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primaryContainer,
        title: _buildAppBarTitle(),
      ),
      body: Center(
        child: AuthService.signedIn
            ? HouseHoldView(houseHold: _currentHousehold)
            : _buildNoHouseholdView(),
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
