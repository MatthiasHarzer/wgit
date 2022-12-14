import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:wgit/services/config_service.dart';
import 'package:wgit/services/firebase/auth_service.dart';
import 'package:wgit/services/firebase/firebase_service.dart';
import 'package:wgit/util/components.dart';
import 'package:wgit/util/util.dart';
import 'package:wgit/views/add_or_create_household/base.dart';
import 'package:wgit/views/add_user_to_household_view.dart';
import 'package:wgit/views/edit_or_new_activity.dart';
import 'package:wgit/views/household/household_view.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

import '../../types/household.dart';
import '../../types/app_user.dart';


import 'drawer/drawer.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'types/app_user.dart';
import 'types/audit_log_item.dart';

final getIt = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await ConfigService.ensureInitialized();

  final authService = AuthService();
  getIt.registerSingleton(authService);

  final firebaseService = FirebaseService();
  getIt.registerSingleton(firebaseService);

  await authService.ensureInitialized();
  await firebaseService.ensureInitialized();

  setPathUrlStrategy();





  // await AuthService.ensureInitialized();

  // String link = "https://wgit.page.link/GUDU";
  // String link = "https://wgit.page.link/k29C";
  // final PendingDynamicLinkData? initialLink =
  //     await FirebaseDynamicLinks.instance.getDynamicLink(Uri.parse(link));

  // Get any initial links
  if (kIsWeb) {
    runApp(const MyApp(initialUserId: null));
  } else {
    final PendingDynamicLinkData? initialLink =
        await FirebaseDynamicLinks.instance.getInitialLink();
    String? uid;
    if(initialLink != null){
      Uri uri = initialLink.link;
      uid = uri.queryParameters["user"];
    }
    // uid = "2XYOJ10MmNgBP42aIh7nAukFsox1";
    runApp(MyApp(initialUserId: uid));
  }
}

class MyApp extends StatelessWidget {
  final String? initialUserId;

  const MyApp({required this.initialUserId, super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    var primary = Colors.deepOrange;
    var accent = Colors.deepOrangeAccent;

    var theme = ThemeData(
      dividerTheme: const DividerThemeData(thickness: 0.3, space: 1),
      iconTheme: IconThemeData(
        color: Colors.grey[350],
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? accent : null),
        trackColor: MaterialStateProperty.resolveWith((states) =>
            states.contains(MaterialState.selected) ? primary[500] : null),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary[700],
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          textStyle: MaterialStateProperty.all(
            TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: primary),
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
        actionTextColor: accent,
      ),
      checkboxTheme:
          CheckboxThemeData(fillColor: MaterialStateProperty.all(accent)),
      primarySwatch: primary,
      brightness: Brightness.dark,
    );
    theme = theme.copyWith(
        textTheme: theme.textTheme.apply(
          bodyColor: Colors.grey[200],

          // displayColor: Colors.black
        ),
        colorScheme: theme.colorScheme.copyWith(secondary: Colors.orange[700]),
    );

    return MaterialApp(
      title: 'WG IT',
      theme: theme,
      initialRoute: "/",
      // routes: {
      //   "/": (context) => MainPage(initialLink: initialLink),
      // },
      // home: MainPage(
      //   initialLink: initialLink,
      // ),
      onGenerateRoute: (settings) {
        String? initialUid = initialUserId;
        try{
          final route = settings.name ?? "";
          final settingsUri = Uri.parse(route);
          settings = settings.copyWith(name: route.split("?").first);
          initialUid ??= settingsUri.queryParameters["user"];
        }catch(e){
          print("Couldn't parse uri ${settings.name}");
          print(e);
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (context)=>MainPage(initialUserId: initialUid),
        );

        // return MainPage(initialLink: initialLink);
        // return NavigatorRoute.route(settings.name);
      },
    );
  }
}

class MainPage extends StatefulWidget {
  final String? initialUserId;

  const MainPage({required this.initialUserId, super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  HouseHold? _currentHousehold;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  final authService = getIt<AuthService>();
  final firebaseService = getIt<FirebaseService>();
  List<HouseHold> _availableHouseholds = [];

  @override
  void initState() {
    super.initState();

    print(Uri.base.toString());

    authService.appUserStream.listen((AppUser? user) {
      if (user == null) {
        setState(() {
          _currentHousehold = null;
        });
      }
    });

    authService.onFirstSignIn(() {
      if (widget.initialUserId != null) {
        _handleInitialUid(widget.initialUserId!);
      }
    });

    firebaseService.availableHouseholds.listen((households) {
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
      } else if (!households.map((h) => h.id).contains(_currentHousehold?.id)) {
        _currentHousehold = households.first;
      }
      setState(() {});
    });

    getIt.get<AuthService>().appUserStream.listen((event) {
      print("AUTHSTREAM EVENT");
      print(event);
      print("----");
    });

    getIt.get<AuthService>().appUserStream.listen((event) {
      print("AUTHSTREAM EVENT 2");
      print(event);
      print("----");
    });
  }

  void _openAddUserToHouseholdDialog(AppUser user) {
    Navigator.push(
      context,
      Util.createScaffoldRoute(
        view: AddUserToHouseholdView(
          user: user,
        ),
      ),
    );
  }

  void _handleInitialUid(String uid) async {
    // Navigator.pu
    AppUser? user = await AppUser.fromUid(uid);
    if (user == null) return;
    if (user.uid == authService.currentUser?.uid) return;
    _openAddUserToHouseholdDialog(user);
  }

  void _switchToHousehold(HouseHold household) {
    // print("Switching to $household");
    ConfigService.currentHouseholdId = household.id;
    setState(() {
      _currentHousehold = household;
    });
  }

  void _signInTaped() async {
    _key.currentState!.openDrawer();
    await Future.delayed(const Duration(milliseconds: 500));
    await authService.signInWithGoogle();
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
        TextButton(
          onPressed: _signInTaped,
          child: const Text(
            "SIGN IN",
          ),
        )
      ],
    );
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
        child: authService.signedIn
            ? _buildCurrentHouseHoldViewOrInfo()
            : _buildNoHouseholdView(),
      ),
      floatingActionButton: Visibility(
        visible: authService.signedIn,
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
