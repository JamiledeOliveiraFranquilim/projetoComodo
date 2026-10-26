import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:larquest/widgets.dart';
void main() {
  testWidgets('ProgressCard apresenta XP, moedas e nível separadamente', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ProgressCard(xp:250, coins:20, completed:5))));
    expect(find.text('250 XP · 20 moedas'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('5 tarefas concluídas'), findsOneWidget);
  });
  testWidgets('Missão concluída mantém estado e permite abrir detalhes', (tester) async {
    var opened = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: MissionCard(
      mission: const {'id':'test','title':'Arrumar a cama','description':'Organize seu quarto.','room':'Quarto','difficulty':'Fácil','points':25},
      status:'completed', onTap:()=>opened=true,
    ))));
    expect(find.text('Concluída'), findsOneWidget);
    await tester.tap(find.text('Arrumar a cama'));
    expect(opened, isTrue);
  });
  testWidgets('Conquistas ainda não obtidas aparecem bloqueadas', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AchievementBadge(
      badge:{'name':'Consistência','description':'Conclua tarefas em três dias diferentes.'}, unlocked:false,
    ))));
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('Ainda bloqueada'), findsOneWidget);
  });
}
