import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'store.dart';
import 'widgets.dart';

void notice(BuildContext c,String text) {if(c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(text)));}
Future<void> act(BuildContext c,GameStore s,Json params,{String success='Tudo certo!'}) async {
 final before=s.unlocked.length; final error=await s.action('game_action',params);
 if(c.mounted) notice(c,error??(s.unlocked.length>before?'✨ Nova conquista desbloqueada! $success':success));
}
Color mascotColor(GameStore s)=>switch(s.profile?['mascot_color']){'rose'=>const Color(0xFFE9AEBF),'sky'=>const Color(0xFFAAD5E7),'sun'=>const Color(0xFFF3D587),_=>sage};
class AuthScreen extends StatefulWidget {
 const AuthScreen({super.key,required this.store});final GameStore store;
 @override State<AuthScreen> createState()=>_AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen>{
 final form=GlobalKey<FormState>(),email=TextEditingController(),password=TextEditingController(),name=TextEditingController();
 bool register=false,busy=false,hidden=true;String? error;
 @override void dispose(){email.dispose();password.dispose();name.dispose();super.dispose();}
 Future<void> submit()async{
  if(!form.currentState!.validate())return;
  setState((){busy=true;error=null;});
  try{
   if(register){final response=await widget.store.db.auth.signUp(email:email.text.trim(),password:password.text,data:{'nickname':name.text.trim()});if(mounted&&response.session==null){setState(()=>register=false);notice(context,'Conta criada! Confira seu e-mail para confirmar o cadastro e depois entre.');}}
   else {await widget.store.db.auth.signInWithPassword(email:email.text.trim(),password:password.text);}
  }catch(e){if(mounted)setState(()=>error=GameStore.message(e));}finally{if(mounted)setState(()=>busy=false);}
 }
 @override Widget build(BuildContext c)=>Scaffold(body:Center(child:SingleChildScrollView(padding:const EdgeInsets.all(24),child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:440),child:Column(children:[const Mascot(size:110),const Text('LarQuest',style:TextStyle(fontSize:38,fontWeight:FontWeight.w900)),const Text('Cuide do seu lar. Crie um mundo seu.'),const SizedBox(height:30),SoftCard(color:pastels[0],child:Form(key:form,child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Text(register?'Seu próximo capítulo começa aqui.':'Que bom ter você em casa.',style:const TextStyle(fontSize:23,fontWeight:FontWeight.bold)),const SizedBox(height:22),if(register)...[TextFormField(controller:name,maxLength:30,decoration:const InputDecoration(labelText:'Seu apelido'),validator:(v)=>(v?.trim().isEmpty??true)?'Informe seu apelido.':null),const SizedBox(height:12)],TextFormField(controller:email,keyboardType:TextInputType.emailAddress,autofillHints:const[AutofillHints.email],decoration:const InputDecoration(labelText:'E-mail'),validator:(v)=>RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v??'')?null:'Digite um e-mail válido.'),const SizedBox(height:12),TextFormField(controller:password,obscureText:hidden,onFieldSubmitted:(_)=>busy?null:submit(),decoration:InputDecoration(labelText:'Senha',suffixIcon:IconButton(tooltip:hidden?'Mostrar senha':'Ocultar senha',onPressed:()=>setState(()=>hidden=!hidden),icon:Icon(hidden?Icons.visibility_outlined:Icons.visibility_off_outlined))),validator:(v)=>(v?.length??0)<8?'Use pelo menos 8 caracteres.':null),if(error!=null)Padding(padding:const EdgeInsets.symmetric(vertical:12),child:Text(error!,style:const TextStyle(color:Colors.red))),const SizedBox(height:20),FilledButton(onPressed:busy?null:submit,child:Text(busy?'Aguarde…':register?'Criar minha conta':'Entrar na aventura')),TextButton(onPressed:busy?null:()=>setState((){register=!register;error=null;}),child:Text(register?'Já tenho uma conta':'Primeira visita? Crie sua conta'))])))])))));
}
const navPaths=['/','/house','/shop','/achievements','/ranking','/profile'];
const navLabels=['Missões','Minha casa','Loja','Conquistas','Ranking','Perfil'];
const navIcons=[Icons.grid_view_rounded,Icons.cottage_outlined,Icons.storefront_outlined,Icons.workspace_premium_outlined,Icons.leaderboard_outlined,Icons.person_outline];
class AppShell extends StatelessWidget{
 const AppShell({super.key,required this.store,required this.path,required this.child});final GameStore store;final String path;final Widget child;
 @override Widget build(BuildContext c)=>ListenableBuilder(listenable:store,builder:(c,_) {
 final selected=navPaths.indexOf(path).clamp(0,5),wide=MediaQuery.sizeOf(c).width>=1000;
 final body=store.profile==null?Center(child:store.error!=null?Column(mainAxisSize:MainAxisSize.min,children:[Text(store.error!),TextButton(onPressed:store.load,child:const Text('Tentar novamente')),TextButton(onPressed:store.logout,child:const Text('Sair'))]):const CircularProgressIndicator()):Column(children:[if(store.loading)const LinearProgressIndicator(minHeight:2),if(store.error!=null)MaterialBanner(content:Text(store.error!),actions:[TextButton(onPressed:store.load,child:const Text('Recarregar'))]),Expanded(child:child)]);
 return Scaffold(appBar:AppBar(title:const Text('⌂ LarQuest',style:TextStyle(fontWeight:FontWeight.w900)),backgroundColor:cream,actions:[if(store.busy)const Padding(padding:EdgeInsets.all(16),child:SizedBox.square(dimension:20,child:CircularProgressIndicator(strokeWidth:2))),Center(child:Text('✦ ${store.coins} moedas  ')),IconButton(tooltip:'Recarregar dados',onPressed:store.loading?null:store.load,icon:const Icon(Icons.refresh))]),body:Row(children:[if(wide)NavigationRail(extended:true,backgroundColor:cream,selectedIndex:selected,onDestinationSelected:(i)=>c.go(navPaths[i]),destinations:List.generate(6,(i)=>NavigationRailDestination(icon:Icon(navIcons[i]),label:Text(navLabels[i])))),Expanded(child:body)]),bottomNavigationBar:wide?null:NavigationBar(height:75,selectedIndex:selected,labelBehavior:NavigationDestinationLabelBehavior.onlyShowSelected,onDestinationSelected:(i)=>c.go(navPaths[i]),destinations:List.generate(6,(i)=>NavigationDestination(icon:Icon(navIcons[i]),label:navLabels[i]))));
 });
}
class PageBody extends StatelessWidget{
 const PageBody({super.key,required this.children});final List<Widget> children;
 @override Widget build(BuildContext c)=>SingleChildScrollView(padding:const EdgeInsets.fromLTRB(22,16,22,32),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:1050),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:children))));
}
Widget heading(String title,[String? subtitle])=>Padding(padding:const EdgeInsets.only(bottom:22),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontSize:30,fontWeight:FontWeight.w800)),if(subtitle!=null)Text(subtitle,style:const TextStyle(color:Color(0xFF6D7D70)))]));
class HomeScreen extends StatefulWidget{
 const HomeScreen({super.key,required this.store});final GameStore store;
 @override State<HomeScreen> createState()=>_HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen>{
 String room='Todos',filter='Todos';
 @override Widget build(BuildContext c){
 final s=widget.store,visible=s.missions.where((m)=>(room=='Todos'||m['room']==room)&&(filter=='Todos'||s.status(m['id'])==filter)).toList();
 final featured=s.missions.where((m)=>s.status(m['id'])!='completed').firstOrNull;
 return PageBody(children:[heading('Olá, ${s.name} ☀','Um pouquinho de cuidado muda tudo.'),ProgressCard(xp:s.xp,coins:s.coins,completed:s.completed),const SizedBox(height:18),SoftCard(child:Row(children:[Mascot(size:90,color:mascotColor(s)),const SizedBox(width:18),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Seu cantinho está esperando',style:TextStyle(fontSize:21,fontWeight:FontWeight.bold)),const Text('Transforme tarefas em um lar com a sua cara.'),TextButton(onPressed:()=>c.go('/house'),child:const Text('Visitar minha casa →'))]))])),const SizedBox(height:26),if(featured!=null)...[heading('Um bom começo','Missão em destaque'),MissionCard(mission:featured,status:s.status(featured['id']),onTap:()=>c.go('/mission/${featured['id']}')),const SizedBox(height:26)],heading('Seu plano de cuidado','Escolha o cômodo e cuide de uma tarefa por vez.'),Wrap(spacing:8,runSpacing:8,children:['Todos',...rooms].map((r)=>ChoiceChip(label:Text(r),selected:room==r,onSelected:(_)=>setState(()=>room=r))).toList()),const SizedBox(height:12),DropdownButtonFormField<String>(initialValue:filter,decoration:const InputDecoration(labelText:'Status'),items:['Todos','available','in_progress','completed'].map((v)=>DropdownMenuItem(value:v,child:Text(v=='Todos'?v:statusLabel(v)))).toList(),onChanged:(v)=>setState(()=>filter=v!)),const SizedBox(height:20),if(visible.isEmpty)const SoftCard(child:Text('Nenhuma tarefa neste filtro. Experimente outro cômodo.')),LayoutBuilder(builder:(c,b){final columns=b.maxWidth>730?3:b.maxWidth>480?2:1;return Wrap(spacing:16,runSpacing:16,children:List.generate(visible.length,(i)=>SizedBox(width:(b.maxWidth-(columns-1)*16)/columns,child:MissionCard(mission:visible[i],status:s.status(visible[i]['id']),index:i,onTap:()=>c.go('/mission/${visible[i]['id']}')))));})]);
 }
}
class MissionScreen extends StatelessWidget{
 const MissionScreen({super.key,required this.store,required this.id});final GameStore store;final String id;
 @override Widget build(BuildContext c){final m=store.missions.where((m)=>m['id']==id).firstOrNull;if(m==null)return PageBody(children:[heading('Missão não encontrada'),TextButton(onPressed:()=>c.go('/'),child:const Text('Voltar às missões'))]);final status=store.status(id);
 return PageBody(children:[Align(alignment:Alignment.centerLeft,child:TextButton.icon(onPressed:()=>c.go('/'),icon:const Icon(Icons.arrow_back),label:const Text('Central de missões'))),const SizedBox(height:12),heading(m['title'], '${m['room']} · ${m['category']} · ${m['difficulty']}'),SoftCard(color:pastels[2],child:Row(children:[const Icon(Icons.auto_awesome,size:42),const SizedBox(width:18),Expanded(child:Text('+${m['points']} XP e moedas\n${statusLabel(status)}',style:const TextStyle(fontSize:22,fontWeight:FontWeight.bold)))])),const SizedBox(height:22),Text(m['description'],style:const TextStyle(fontSize:20)),const SizedBox(height:22),...List.generate((m['instructions'] as List).length,(i)=>Padding(padding:const EdgeInsets.only(bottom:14),child:SoftCard(child:Text('${i+1}. ${m['instructions'][i]}')))),const SizedBox(height:20),FilledButton.icon(onPressed:store.busy||status=='completed'?null:()async{if(status=='available'){await act(c,store,{'action':'start','mission':id},success:'Missão iniciada. Bom cuidado!');}else{final confirmed=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:const Text('Tarefa realizada?'),content:const Text('Confirme depois de realizar a tarefa. Esta missão só concede pontos uma vez.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Ainda não')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Sim, concluí!'))]));if(confirmed==true&&c.mounted)await act(c,store,{'action':'complete','mission':id},success:'+${m['points']} XP e moedas!');}},icon:Icon(status=='completed'?Icons.check_circle:Icons.play_arrow),label:Text(status=='completed'?'Missão concluída':status=='available'?'Iniciar missão':'Concluir tarefa'))]);
 }
}
class AchievementsScreen extends StatelessWidget{
 const AchievementsScreen({super.key,required this.store});final GameStore store;
 @override Widget build(BuildContext c)=>PageBody(children:[heading('Pequenas vitórias, grandes histórias','${store.unlocked.length} de ${store.badges.length} conquistas desbloqueadas'),...store.badges.map((b)=>Padding(padding:const EdgeInsets.only(bottom:14),child:AchievementBadge(badge:b,unlocked:store.unlocked.any((u)=>u['achievement_id']==b['id']))))]);
}
class RankingScreen extends StatelessWidget{
 const RankingScreen({super.key,required this.store});final GameStore store;
 @override Widget build(BuildContext c)=>PageBody(children:[heading('Quem cuida, inspira','Ranking por XP acumulado. Comprar mobília não reduz sua posição.'),if(store.ranking.isEmpty)const SoftCard(child:Text('O ranking ainda está vazio. Conclua sua primeira missão.')),...store.ranking.map((r){final own=r['id']==store.userId;return Padding(padding:const EdgeInsets.only(bottom:12),child:SoftCard(color:own?pastels[0]:r['position']<=3?pastels[2]:Colors.white,child:Row(children:[Text(r['position']<=3?['🥇','🥈','🥉'][(r['position'] as int)-1]:'#${r['position']}',style:const TextStyle(fontSize:26)),const SizedBox(width:16),Expanded(child:Text('${r['nickname']}${own?' (você)':''}',style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold))),Text('${r['xp']} XP')])));})]);
}
class ProfileScreen extends StatefulWidget{
 const ProfileScreen({super.key,required this.store});final GameStore store;
 @override State<ProfileScreen> createState()=>_ProfileScreenState();
}
class _ProfileScreenState extends State<ProfileScreen>{
 late final name=TextEditingController(text:widget.store.name);
 @override void dispose(){name.dispose();super.dispose();}
 @override Widget build(BuildContext c){final s=widget.store;return PageBody(children:[heading('Seu jeito de cuidar'),Center(child:Mascot(size:130,color:mascotColor(s))),const SizedBox(height:16),Text(s.db.auth.currentUser?.email??'',textAlign:TextAlign.center),const SizedBox(height:22),ProgressCard(xp:s.xp,coins:s.coins,completed:s.completed),const SizedBox(height:14),SoftCard(child:Text('${s.unlocked.length} conquistas desbloqueadas · Nível ${1+s.xp~/200}')),const SizedBox(height:20),TextField(controller:name,maxLength:30,decoration:const InputDecoration(labelText:'Apelido público')),FilledButton(onPressed:s.busy?null:()=>act(c,s,{'action':'nickname','new_name':name.text},success:'Apelido atualizado.'),child:const Text('Salvar apelido')),const SizedBox(height:22),const Text('A cor do seu companheiro',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),const Text('Desbloqueie novas cores na loja e selecione aqui.'),const SizedBox(height:14),Wrap(spacing:10,children:['sage','rose','sky','sun'].map((color){final unlocked=color=='sage'||s.items.any((i)=>i['color']==color&&s.owns(i['id']));return ChoiceChip(label:Text('${{'sage':'Verde','rose':'Rosa','sky':'Azul','sun':'Dourado'}[color]}${unlocked?'':' 🔒'}'),selected:s.profile?['mascot_color']==color,onSelected:unlocked&&!s.busy?(_)=>act(c,s,{'action':'color','item':color},success:'Novo visual aplicado!'):null);}).toList()),const SizedBox(height:30),OutlinedButton.icon(onPressed:s.busy?null:()async{try{await s.logout();}catch(e){if(c.mounted)notice(c,GameStore.message(e));}},icon:const Icon(Icons.logout),label:const Text('Encerrar sessão'))]);}
}
class ShopScreen extends StatefulWidget{
 const ShopScreen({super.key,required this.store});final GameStore store;
 @override State<ShopScreen> createState()=>_ShopScreenState();
}
class _ShopScreenState extends State<ShopScreen>{
 String filter='Todos';
 @override Widget build(BuildContext c){final s=widget.store,items=s.items.where((i)=>filter=='Todos'||(filter=='Mascote'?i['kind']=='color':i['room']==filter)).toList();return PageBody(children:[heading('Coisas que fazem um lar','${s.coins} moedas para deixar tudo do seu jeito.'),Wrap(spacing:8,runSpacing:8,children:['Todos',...rooms,'Mascote'].map((r)=>ChoiceChip(label:Text(r),selected:filter==r,onSelected:(_)=>setState(()=>filter=r))).toList()),const SizedBox(height:22),LayoutBuilder(builder:(c,b){final n=b.maxWidth>700?3:b.maxWidth>450?2:1;return Wrap(spacing:16,runSpacing:16,children:items.map((i){final owned=s.owns(i['id']);return SizedBox(width:(b.maxWidth-(n-1)*16)/n,child:SoftCard(color:pastels[items.indexOf(i)%4],child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[Center(child:i['kind']=='color'?Mascot(size:70,color:switch(i['color']){'rose'=>const Color(0xFFE9AEBF),'sky'=>const Color(0xFFAAD5E7),_=>const Color(0xFFF3D587)}):Furniture(kind:i['kind'],size:65)),const SizedBox(height:18),Text(i['name'],style:const TextStyle(fontSize:19,fontWeight:FontWeight.bold)),Text('${i['room']??'Personalização'} · ${i['price']} moedas'),const SizedBox(height:16),FilledButton(onPressed:owned||s.busy||s.coins<i['price']?null:()async{final ok=await showDialog<bool>(context:c,builder:(d)=>AlertDialog(title:Text('Comprar ${i['name']}?'),content:Text('Custa ${i['price']} moedas. Seu XP permanece igual.'),actions:[TextButton(onPressed:()=>Navigator.pop(d,false),child:const Text('Cancelar')),FilledButton(onPressed:()=>Navigator.pop(d,true),child:const Text('Comprar'))]));if(ok==true&&c.mounted)await act(c,s,{'action':'buy','item':i['id']},success:'Compra feita! Decore a casa ou visite seu perfil.');},child:Text(owned?'No inventário':s.coins<i['price']?'Faltam moedas':'Comprar'))])));}).toList());})]);}
}
class HouseScreen extends StatefulWidget {
  const HouseScreen({super.key, required this.store});
  final GameStore store;
  @override State<HouseScreen> createState() => _HouseScreenState();
}
class _HouseScreenState extends State<HouseScreen> {
  String room = 'Sala';
  String? selected;
  @override Widget build(BuildContext c) {
    final s = widget.store;
    final owned = s.items.where((i) => i['room'] == room && s.owns(i['id'])).toList();
    final placed = s.placements.where((p) => p['room'] == room).toList();
    final tasks = s.missions.where((m) => m['room'] == room).toList();
    final done = tasks.where((m) => s.status(m['id']) == 'completed').length;
    return PageBody(children: [
      heading('Um lar que cresce com você', 'Toque em um cômodo. Escolha uma mobília e toque no chão para posicioná-la.'),
      SoftCard(color: pastels[0], child: Row(children: [
        Mascot(size: 75, color: mascotColor(s)), const SizedBox(width: 16),
        Expanded(child: Text('$done/${tasks.length} tarefas de $room concluídas', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
      ])),
      const SizedBox(height: 20),
      AspectRatio(aspectRatio: 1.35, child: GridView.count(
        crossAxisCount: 2, physics: const NeverScrollableScrollPhysics(), childAspectRatio: 1.35,
        mainAxisSpacing: 7, crossAxisSpacing: 7,
        children: List.generate(4, (i) => InkWell(
          onTap: () => setState(() { room = rooms[i]; selected = null; }),
          child: Container(
            decoration: BoxDecoration(color: pastels[i], borderRadius: BorderRadius.circular(18), border: Border.all(color: room == rooms[i] ? ink : Colors.transparent, width: 3)),
            child: Stack(children: [
              Positioned(top: 12, left: 14, child: Text(rooms[i], style: const TextStyle(fontWeight: FontWeight.bold))),
              Center(child: Icon(roomIcons[i], size: 42, color: ink.withValues(alpha: .35))),
              Positioned(bottom: 12, right: 14, child: Text('${s.placements.where((p) => p['room'] == rooms[i]).length} itens')),
            ]),
          ),
        )),
      )),
      const SizedBox(height: 24),
      heading('Decorando: $room', selected == null ? 'Selecione um item do inventário abaixo.' : 'Toque no piso para colocar o item selecionado.'),
      AspectRatio(aspectRatio: 1.35, child: LayoutBuilder(builder: (c, b) {
        return GestureDetector(
          onTapDown: selected == null || s.busy ? null : (d) async {
            final x = (d.localPosition.dx / b.maxWidth).clamp(.08, .92);
            final y = (d.localPosition.dy / b.maxHeight).clamp(.15, .85);
            await act(c, s, {'action': 'place', 'item': selected, 'room_name': room, 'pos_x': x, 'pos_y': y}, success: 'Mobília posicionada!');
          },
          child: Container(
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), color: pastels[rooms.indexOf(room)], border: Border.all(color: const Color(0xFFD3DCC8), width: 8)),
            child: Stack(children: [
              Positioned.fill(child: CustomPaint(painter: _FloorPainter())),
              Positioned(top: 12, left: 18, child: Text(room, style: const TextStyle(fontWeight: FontWeight.bold))),
              Positioned(bottom: 18, left: 18, child: Mascot(size: 60, color: mascotColor(s))),
              ...placed.map((p) {
                final item = s.items.where((i) => i['id'] == p['item_id']).firstOrNull;
                if (item == null) return const SizedBox.shrink();
                return Positioned(
                  left: (p['x'] as num).toDouble() * b.maxWidth - 30,
                  top: (p['y'] as num).toDouble() * b.maxHeight - 30,
                  child: Tooltip(message: item['name'], child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .65), borderRadius: BorderRadius.circular(14)),
                    child: Padding(padding: const EdgeInsets.all(6), child: Furniture(kind: item['kind'])),
                  )),
                );
              }),
            ]),
          ),
        );
      })),
      const SizedBox(height: 20),
      if (owned.isEmpty) SoftCard(child: Column(children: [
        const Text('Seu inventário deste cômodo está vazio.'),
        TextButton(onPressed: () => c.go('/shop'), child: const Text('Explorar a loja')),
      ])),
      Wrap(spacing: 8, runSpacing: 8, children: owned.map((i) => InputChip(
        avatar: Furniture(kind: i['kind'], size: 22), label: Text(i['name']), selected: selected == i['id'],
        onSelected: (_) => setState(() => selected = selected == i['id'] ? null : i['id']),
        onDeleted: s.busy || !placed.any((p) => p['item_id'] == i['id']) ? null : () => act(c, s, {'action': 'remove', 'item': i['id']}, success: 'Item guardado no inventário.'),
      )).toList()),
      const SizedBox(height: 12),
      const Text('O × guarda a mobília no inventário. Para mover, selecione o item e toque em outra posição. Cada compra representa uma unidade.'),
    ]);
  }
}
class _FloorPainter extends CustomPainter{
 @override void paint(Canvas c,Size s){final p=Paint()..color=ink.withValues(alpha:.05)..strokeWidth=1;for(double y=40;y<s.height;y+=36){c.drawLine(Offset(0,y),Offset(s.width,y),p);}for(double x=35;x<s.width;x+=70){c.drawLine(Offset(x,0),Offset(x,s.height),p);}}
 @override bool shouldRepaint(_FloorPainter old)=>false;
}
