import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:wgit/services/config_service.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/services/types.dart';
import 'package:wgit/util/components.dart';
import 'package:wgit/util/util.dart';
import 'package:wgit/views/add_or_create_household/base.dart';
import 'package:wgit/views/household/household_view.dart';
import 'package:wgit/views/edit_or_new_activity.dart';

import 'drawer/drawer.dart';
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
    var theme = ThemeData(
      dividerTheme: const DividerThemeData(thickness: 0.3, space: 1),
      iconTheme: IconThemeData(
        color: Colors.grey[350],
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
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.deepOrange[700],
      ),
      buttonTheme: ButtonThemeData(
        textTheme: ButtonTextTheme.accent,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.deepOrange),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade900,
        contentTextStyle: TextStyle(color: Colors.grey[200]),
        actionTextColor: Colors.deepOrangeAccent,
      ),
      primarySwatch: Colors.deepOrange,
      brightness: Brightness.dark,
    );
    theme = theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.grey[300],

          // displayColor: Colors.black
        ),
        colorScheme: theme.colorScheme.copyWith(secondary: Colors.orange[700]));

    return MaterialApp(
      title: 'WG IT',
      theme: theme,
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
  List<HouseHold> _availableHouseholds = [];

  @override
  void initState() {
    super.initState();

    AuthService.stateChange.listen((u) => setState(() {
          if (u == null) {
            _currentHousehold = null;
          }
        }));

    FirebaseService.availableHouseholds.listen((households) {
      _availableHouseholds = households;
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
      } else if (households.isEmpty) {
        _currentHousehold = null;
      }
      setState(() {});
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

  void _signInTaped() async {
    _key.currentState!.openDrawer();
    await Future.delayed(const Duration(milliseconds: 500));
    await AuthService.signInWithGoogle();
  }

  void _newActivityTaped() {
    if (_currentHousehold == null) {
      Util.showSnackBar(context,
          content:
              const Text("Can't add an activity without an active household."));
      return;
    }
    Navigator.push(
        context,
        Util.createScaffoldRoute(
            view: EditOrNewActivity(houseHold: _currentHousehold!)));
  }

  /// Builds the appbar title depending on [_currentHousehold]
  Widget _buildAppBarTitle() {
    if (_currentHousehold == null) {
      return const Text("WGit");
    } else {
      return Text(_currentHousehold!.name);
    }
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
              style: AppTheme.materialButtonLabelStyle,
            ),
          )
        ],
      );
    }
    return Text("");
  }

  /// Builds the currently selected household or returns an info screen
  Widget _buildCurrentHouseHoldViewOrInfo() {
    if (_availableHouseholds.isEmpty) {
      return InfoActionWidget(
        label:
            "No households are available. You can create a new one or join an existing household",
        buttonText: "JOIN OR CREATE",
        onTap: () {
          Navigator.push(
            context,
            Util.createScaffoldRoute(
                view: JoinOrCreateHouseholdView(
              onFinished: _switchToHousehold,
            )),
          );
        },
      );
    }
    if (_currentHousehold == null) {
      return const CircularProgressIndicator();
    }
    return HouseHoldView(houseHold: _currentHousehold!);
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
            ? _buildCurrentHouseHoldViewOrInfo()
            : _buildNoHouseholdView(),
      ),
      floatingActionButton: Visibility(
        visible: AuthService.signedIn,
        child: FloatingActionButton(
          onPressed: _newActivityTaped,
          tooltip: "Add Activity",
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
      drawer: MainPageDrawer(
        onSwitchTo: _switchToHousehold,
        currentHouseHold: _currentHousehold,
      ),
    );
  }
}
