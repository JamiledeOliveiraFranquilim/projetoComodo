import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef Json = Map<String, dynamic>;

class GameStore extends ChangeNotifier {
  GameStore(this.db) {
    subscription = db.auth.onAuthStateChange.listen((event) {
      profile = null;
      missions = []; progress = []; badges = []; unlocked = []; inventory = []; placements = []; ranking = [];
      notifyListeners();
      if (db.auth.currentSession != null) unawaited(load());
    });
  }
  final SupabaseClient db;
  late final StreamSubscription<AuthState> subscription;
  Json? profile;
  List<Json> missions = [], progress = [], badges = [], unlocked = [], items = [], inventory = [], placements = [], ranking = [];
  bool loading = false, busy = false;
  String? error;
  int generation = 0;
  bool get signedIn => db.auth.currentSession != null;
  String get userId => db.auth.currentUser!.id;
  int get xp => (profile?['xp'] as num?)?.toInt() ?? 0;
  int get coins => (profile?['coins'] as num?)?.toInt() ?? 0;
  int get completed => progress.where((p) => p['status'] == 'completed').length;
  String get name => profile?['nickname'] as String? ?? 'Jogador';
  String status(String id) => progress.where((p) => p['mission_id'] == id).firstOrNull?['status'] as String? ?? 'available';
  bool owns(String id) => inventory.any((p) => p['item_id'] == id);
  Future<void> load() async {
    if (!signedIn) return;
    final uid = userId, ticket = ++generation;
    loading = true; error = null; notifyListeners();
    try {
      final data = await Future.wait<dynamic>([
        db.from('profiles').select().eq('id', uid).single(),
        db.from('missions').select().order('sort_order'),
        db.from('user_missions').select().eq('user_id', uid),
        db.from('achievements').select().order('threshold'),
        db.from('user_achievements').select().eq('user_id', uid),
        db.from('shop_items').select().order('price'),
        db.from('inventory').select().eq('user_id', uid),
        db.from('placements').select().eq('user_id', uid),
        db.rpc('get_ranking'),
      ]);
      if (!signedIn || userId != uid || ticket != generation) return;
      profile = Map<String, dynamic>.from(data[0] as Map);
      List<Json> rows(dynamic v) => (v as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      missions = rows(data[1]); progress = rows(data[2]); badges = rows(data[3]); unlocked = rows(data[4]);
      items = rows(data[5]); inventory = rows(data[6]); placements = rows(data[7]); ranking = rows(data[8]);
    } catch (e) { if (ticket == generation) error = message(e); }
    finally { if (ticket == generation) { loading = false; notifyListeners(); } }
  }
  Future<String?> action(String fn, Json params) async {
    if (busy) return 'Aguarde a operação atual.';
    busy = true; notifyListeners();
    try { await db.rpc(fn, params: params); await load(); return error; }
    catch (e) { return message(e); }
    finally { busy = false; notifyListeners(); }
  }
  Future<void> logout() async { ++generation; await db.auth.signOut(); }
  static String message(Object e) {
    if (e is AuthException) {
      if (e.message.contains('Invalid login')) return 'E-mail ou senha incorretos.';
      if (e.message.contains('Email not confirmed')) return 'Confirme seu e-mail antes de entrar.';
      if (e.message.contains('already registered')) return 'Este e-mail já possui uma conta.';
      if (e.message.contains('rate limit')) return 'Muitas tentativas. Aguarde antes de tentar novamente.';
      return e.message;
    }
    if (e is PostgrestException) return e.message;
    return 'Não foi possível conectar. Verifique sua internet e tente novamente.';
  }
  @override void dispose() { subscription.cancel(); super.dispose(); }
}
