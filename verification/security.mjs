import { PGlite } from '@electric-sql/pglite';
import fs from 'node:fs';
const db=new PGlite();
await db.exec(`create role anon; create role authenticated; create schema auth; create table auth.users(id uuid primary key, raw_user_meta_data jsonb default '{}'); create function auth.uid() returns uuid language sql stable as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$; grant usage on schema public,auth to anon,authenticated; grant execute on function auth.uid() to public;`);
await db.exec(fs.readFileSync(new URL('../supabase/setup.sql', import.meta.url),'utf8'));
const u='00000000-0000-0000-0000-000000000001',v='00000000-0000-0000-0000-000000000002';
await db.query(`insert into auth.users(id,raw_user_meta_data) values($1,'{"nickname":"Ana"}'),($2,'{"nickname":"Bia"}')`,[u,v]);
await db.exec(`set role authenticated; set request.jwt.claim.sub='${u}';`);
let passed=0;
function check(ok,label){if(!ok)throw Error(label);passed++;console.log('PASS',label);}
async function rejected(sql,label){try{await db.exec(sql);}catch{check(true,label);return;}throw Error('Expected rejection: '+label);}
await db.exec(`select public.game_action('start','sala-objetos');select public.game_action('complete','sala-objetos');`);
let p=(await db.query('select * from public.profiles')).rows;
check(p.length===1&&p[0].xp===25&&p[0].coins===25,'isolamento e recompensa');
await rejected(`select public.game_action('complete','sala-objetos')`,'sem recompensa duplicada');
await rejected(`select public.game_action('complete','sala-po')`,'exige início');
await rejected(`update public.profiles set xp=9999`,'bloqueia pontuação direta');
await rejected(`insert into public.inventory(user_id,item_id) values('${u}','sofa')`,'bloqueia inventário direto');
await rejected(`select public.game_action('buy',item=>'sofa')`,'saldo insuficiente');
await db.exec(`select public.game_action('buy',item=>'plant')`);
p=(await db.query('select * from public.profiles')).rows[0];
check(p.xp===25&&p.coins===0,'compra preserva XP');
await rejected(`select public.game_action('buy',item=>'plant')`,'sem compra duplicada');
await rejected(`select public.game_action('place',item=>'sofa',room_name=>'Sala',pos_x=>0.5,pos_y=>0.5)`,'exige posse');
await rejected(`select public.game_action('place',item=>'plant',room_name=>'Quarto',pos_x=>0.5,pos_y=>0.5)`,'valida cômodo');
await db.exec(`select public.game_action('place',item=>'plant',room_name=>'Sala',pos_x=>0.5,pos_y=>0.5)`);
check((await db.query('select * from public.placements')).rows.length===1,'posicionamento persistido');
await rejected(`select public.game_action('color',item=>'rose')`,'cor bloqueada sem compra');
check((await db.query('select * from public.user_achievements')).rows.length===1,'primeira conquista automática');
check((await db.query('select * from public.get_ranking()')).rows.length===2,'ranking real entre contas');
await db.exec(`set request.jwt.claim.sub='${v}'`);
check((await db.query('select * from public.placements')).rows.length===0,'decoração privada');
check((await db.query('select * from public.user_missions')).rows.length===0,'missões privadas');
// Conclui todas as missões da segunda conta, simulando duas datas anteriores em fixtures.
const catalog=(await db.query('select id from public.missions order by sort_order')).rows;
for (const m of catalog.slice(0,2)) {
  await db.query("select public.game_action('start',mission=>$1)",[m.id]);
  await db.query("select public.game_action('complete',mission=>$1)",[m.id]);
}
await db.exec('reset role');
await db.query("update public.user_missions set completed_at=now()-interval '2 days' where user_id=$1 and mission_id=$2",[v,catalog[0].id]);
await db.query("update public.user_missions set completed_at=now()-interval '1 day' where user_id=$1 and mission_id=$2",[v,catalog[1].id]);
await db.exec('set role authenticated');
for (const m of catalog.slice(2)) {
  await db.query("select public.game_action('start',mission=>$1)",[m.id]);
  await db.query("select public.game_action('complete',mission=>$1)",[m.id]);
}
check((await db.query('select * from public.user_achievements')).rows.length===5,'todas as conquistas, incluindo dias e reciclagem');
check((await db.query('select xp from public.profiles')).rows[0].xp===485,'soma completa das recompensas');
await db.exec("select public.game_action('buy',item=>'rose');select public.game_action('color',item=>'rose')");
check((await db.query('select mascot_color from public.profiles')).rows[0].mascot_color==='rose','personalização após compra');
await rejected("truncate public.profiles cascade",'bloqueia TRUNCATE do cliente');
await db.exec(`reset role;set role anon;`);
await rejected(`select public.game_action('start','sala-po')`,'RPC negada sem autenticação');
console.log(`${passed} verificações aprovadas`);
await db.close();
