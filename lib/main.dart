import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'store.dart';
import 'widgets.dart';
import 'screens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (url.isEmpty || key.isEmpty || url.contains('SEU-PROJETO') || key.startsWith('SUA_')) {
    runApp(MaterialApp(theme:appTheme,home:const Scaffold(body:Center(child:Padding(padding:EdgeInsets.all(32),child:Text('LarQuest\n\nConfigure o Supabase para começar.\nCopie config.example.json para config.json, preencha a URL e a chave pública e execute:\n\nflutter run -d chrome --dart-define-from-file=config.json',textAlign:TextAlign.center))))));
    return;
  }
  try {
    await Supabase.initialize(url:url,anonKey:key);
    runApp(LarQuest(store:GameStore(Supabase.instance.client)));
  } catch (_) {
    runApp(MaterialApp(theme:appTheme,home:const Scaffold(body:Center(child:Text('Não foi possível iniciar. Confira config.json e recarregue.')))));
  }
}
final appTheme = ThemeData(useMaterial3:true, colorScheme:ColorScheme.fromSeed(seedColor:sage,primary:ink,surface:cream),scaffoldBackgroundColor:cream,fontFamily:'sans-serif',textTheme:const TextTheme(bodyMedium:TextStyle(color:ink,fontSize:14),headlineMedium:TextStyle(color:ink,fontWeight:FontWeight.w800)),inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:Colors.white,border:OutlineInputBorder(borderRadius:BorderRadius.circular(18),borderSide:BorderSide.none)),filledButtonTheme:FilledButtonThemeData(style:FilledButton.styleFrom(padding:const EdgeInsets.symmetric(horizontal:24,vertical:20),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(18)))));
class LarQuest extends StatefulWidget {
  const LarQuest({super.key,required this.store}); final GameStore store;
  @override State<LarQuest> createState()=>_LarQuestState();
}
class _LarQuestState extends State<LarQuest> {
  bool ready=false;
  late final GoRouter router=GoRouter(initialLocation:'/splash',refreshListenable:widget.store,redirect:(_,state){
    final path=state.uri.path;
    if(!ready) return path=='/splash'?null:'/splash';
    if(!widget.store.signedIn) return path=='/login'?null:'/login';
    if(path=='/login'||path=='/splash') return '/';
    return null;
  },routes:[
    GoRoute(path:'/splash',builder:(_,__)=>Splash(onDone:(){ready=true;router.refresh();})),
    GoRoute(path:'/login',builder:(_,__)=>AuthScreen(store:widget.store)),
    ShellRoute(builder:(c,s,child)=>AppShell(store:widget.store,path:s.uri.path,child:child),routes:[
      GoRoute(path:'/',builder:(_,__)=>HomeScreen(store:widget.store)),
      GoRoute(path:'/mission/:id',builder:(_,s)=>MissionScreen(store:widget.store,id:s.pathParameters['id']!)),
      GoRoute(path:'/house',builder:(_,__)=>HouseScreen(store:widget.store)),
      GoRoute(path:'/shop',builder:(_,__)=>ShopScreen(store:widget.store)),
      GoRoute(path:'/achievements',builder:(_,__)=>AchievementsScreen(store:widget.store)),
      GoRoute(path:'/ranking',builder:(_,__)=>RankingScreen(store:widget.store)),
      GoRoute(path:'/profile',builder:(_,__)=>ProfileScreen(store:widget.store)),
    ]),
  ],errorBuilder:(c,s)=>Scaffold(body:Center(child:TextButton(onPressed:()=>c.go('/'),child:const Text('Página não encontrada. Voltar ao início')))));
  @override void initState(){super.initState(); if(widget.store.signedIn) unawaited(widget.store.load());}
  @override void dispose(){router.dispose();widget.store.dispose();super.dispose();}
  @override Widget build(BuildContext context)=>MaterialApp.router(title:'LarQuest',debugShowCheckedModeBanner:false,theme:appTheme,routerConfig:router);
}
class Splash extends StatefulWidget {
  const Splash({super.key,required this.onDone});final VoidCallback onDone;
  @override State<Splash> createState()=>_SplashState();
}
class _SplashState extends State<Splash>{
  Timer? timer;
  @override void initState(){super.initState();timer=Timer(const Duration(milliseconds:1900),widget.onDone);}
  @override void dispose(){timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:pastels[0],body:Center(child:TweenAnimationBuilder<double>(tween:Tween(begin:0,end:1),duration:const Duration(milliseconds:950),curve:Curves.easeOutCubic,builder:(_,v,child)=>Opacity(opacity:v,child:Transform.translate(offset:Offset(0,30*(1-v)),child:child)),child:const Column(mainAxisSize:MainAxisSize.min,children:[Mascot(size:150),SizedBox(height:26),Text('LarQuest',style:TextStyle(fontSize:42,fontWeight:FontWeight.w900,color:ink)),Text('Pequenas tarefas. Grandes transformações.'),SizedBox(height:28),SizedBox(width:80,child:LinearProgressIndicator())]))));
}
