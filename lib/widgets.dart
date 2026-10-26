import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'store.dart';

const ink = Color(0xFF293D32);
const sage = Color(0xFFA8C981);
const cream = Color(0xFFF7F9F2);
const pastels = [Color(0xFFE8EFCB),Color(0xFFDCEEF0),Color(0xFFFFEACD),Color(0xFFF4DEE4)];
const rooms = ['Sala', 'Cozinha', 'Quarto', 'Banheiro'];
const roomIcons = [Icons.weekend_outlined, Icons.kitchen_outlined, Icons.bed_outlined, Icons.bathtub_outlined];
String statusLabel(String s) => switch(s) {'completed' => 'Concluída', 'in_progress' => 'Em andamento', _ => 'Disponível'};

class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.color = Colors.white, this.padding = 22});
  final Widget child; final Color color; final double padding;
  @override Widget build(BuildContext context) => Container(padding: EdgeInsets.all(padding), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)), child: child);
}
class Mascot extends StatefulWidget {
  const Mascot({super.key, this.color = sage, this.size = 100});
  final Color color; final double size;
  @override State<Mascot> createState() => _MascotState();
}
class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  @override void dispose() { c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: c, builder: (_, child) => Transform.translate(offset: Offset(0, -6*c.value), child: child), child: CustomPaint(size: Size.square(widget.size), painter: _MascotPainter(widget.color)));
}
class _MascotPainter extends CustomPainter {
  _MascotPainter(this.color); final Color color;
  @override void paint(Canvas canvas, Size s) {
    canvas.scale(s.width/100, s.height/100);
    final p = Paint()..color = color;
    canvas.drawOval(const Rect.fromLTWH(14,86,72,9), Paint()..color = ink.withValues(alpha:.08));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(15,22,70,66), const Radius.circular(28)),p);
    canvas.drawOval(const Rect.fromLTWH(18,9,22,35), p);
    canvas.drawOval(const Rect.fromLTWH(60,9,22,35), p);
    canvas.drawCircle(const Offset(36,51),3,Paint()..color=ink);
    canvas.drawCircle(const Offset(64,51),3,Paint()..color=ink);
    canvas.drawArc(const Rect.fromLTWH(42,55,16,11),0,math.pi,false,Paint()..color=ink..style=PaintingStyle.stroke..strokeWidth=2.5);
    canvas.drawCircle(const Offset(27,61),6,Paint()..color=const Color(0xFFEDB3A8));
    canvas.drawCircle(const Offset(73,61),6,Paint()..color=const Color(0xFFEDB3A8));
    canvas.drawOval(const Rect.fromLTWH(40,70,20,11),Paint()..color=Colors.white.withValues(alpha:.5));
  }
  @override bool shouldRepaint(_MascotPainter old) => old.color != color;
}
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.xp, required this.coins, required this.completed});
  final int xp, coins, completed;
  @override Widget build(BuildContext context) => SoftCard(color:pastels[0], child: Row(children:[
    SizedBox(width:80,height:80,child:Stack(alignment:Alignment.center,children:[SizedBox.square(dimension:72,child:CircularProgressIndicator(value:(xp%200)/200,backgroundColor:Colors.white,strokeWidth:7,color:ink)),Text('${1+xp~/200}',style:const TextStyle(fontSize:30,fontWeight:FontWeight.bold))])),
    const SizedBox(width:20),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('CADA PEQUENO PASSO CONTA',style:TextStyle(fontSize:10,letterSpacing:1.2)),const SizedBox(height:8),Text('$xp XP · $coins moedas',style:const TextStyle(fontSize:21,fontWeight:FontWeight.w800)),Text('$completed tarefas concluídas\n${200-xp%200} XP para o próximo nível')]))]));
}
class MissionCard extends StatelessWidget {
  const MissionCard({super.key,required this.mission,required this.status,required this.onTap, this.index=0});
  final Json mission; final String status; final VoidCallback onTap; final int index;
  @override Widget build(BuildContext context) => Semantics(button:true,child:InkWell(borderRadius:BorderRadius.circular(28),onTap:onTap,child:SoftCard(color:pastels[index%4],child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Row(children:[Icon(roomIcons[rooms.indexOf(mission['room']).clamp(0,3)]),const Spacer(),Text('+${mission['points']} XP',style:const TextStyle(fontWeight:FontWeight.w800))]),const SizedBox(height:22),Text(mission['title'],style:const TextStyle(fontWeight:FontWeight.bold,fontSize:20)),const SizedBox(height:7),Text(mission['description'],maxLines:2,overflow:TextOverflow.ellipsis),const SizedBox(height:18),Wrap(spacing:8,runSpacing:5,children:[Text('${mission['room']} · ${mission['difficulty']}',style:const TextStyle(fontSize:12)),Text(statusLabel(status),style:const TextStyle(fontSize:12,fontWeight:FontWeight.bold))])]))));
}
class AchievementBadge extends StatelessWidget {
  const AchievementBadge({super.key,required this.badge,required this.unlocked});
  final Json badge; final bool unlocked;
  @override Widget build(BuildContext context) => SoftCard(color:unlocked?pastels[2]:const Color(0xFFEAEEE8),child:Row(children:[Icon(unlocked?Icons.workspace_premium:Icons.lock_outline,size:38,color:unlocked?ink:Colors.grey),const SizedBox(width:16),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(badge['name'],style:const TextStyle(fontWeight:FontWeight.bold,fontSize:18)),Text(badge['description']),Text(unlocked?'Desbloqueada ✨':'Ainda bloqueada',style:const TextStyle(fontSize:12))]))]));
}
class Furniture extends StatelessWidget {
  const Furniture({super.key,required this.kind, this.size=44});
  final String kind; final double size;
  @override Widget build(BuildContext context) => Icon(switch(kind){'sofa'=>Icons.weekend,'plant'=>Icons.local_florist,'bed'=>Icons.bed,'table'=>Icons.table_restaurant,'lamp'=>Icons.light,'bath'=>Icons.bathtub,'rug'=>Icons.crop_landscape,_=>Icons.chair},size:size,color:ink);
}
