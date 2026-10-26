-- LarQuest | Execute uma vez no SQL Editor de um projeto Supabase NOVO.
-- Não necessita service_role no cliente. Todas as recompensas são decididas no banco.
begin;
create schema if not exists larquest_private;
revoke all on schema larquest_private from public, anon;
grant usage on schema larquest_private to authenticated;
create table public.profiles (
 id uuid primary key references auth.users on delete cascade,
 nickname text not null check (char_length(nickname) between 1 and 30),
 xp integer not null default 0 check(xp>=0),
 coins integer not null default 0 check(coins>=0),
 mascot_color text not null default 'sage',
 created_at timestamptz not null default now()
);
create table public.missions (
 id text primary key, title text not null, description text not null,
 room text not null check(room in ('Sala','Cozinha','Quarto','Banheiro')),
 category text not null, difficulty text not null, points integer not null check(points>0),
 instructions text[] not null, sort_order integer not null default 0
);
create table public.user_missions (
 user_id uuid references public.profiles on delete cascade,
 mission_id text references public.missions,
 status text not null check(status in ('in_progress','completed')),
 started_at timestamptz not null default now(), completed_at timestamptz,
 primary key(user_id,mission_id),
 check((status='completed')=(completed_at is not null))
);
create table public.achievements (
 id text primary key, name text not null, description text not null,
 metric text not null check(metric in ('total','days','recycling')), threshold integer not null check(threshold>0)
);
create table public.user_achievements (
 user_id uuid references public.profiles on delete cascade,
 achievement_id text references public.achievements, unlocked_at timestamptz not null default now(),
 primary key(user_id,achievement_id)
);
create table public.shop_items (
 id text primary key, name text not null, kind text not null,
 room text check(room in ('Sala','Cozinha','Quarto','Banheiro')),
 price integer not null check(price>=0), color text,
 check((kind='color' and room is null and color in ('sage','rose','sky','sun')) or (kind<>'color' and room is not null and color is null))
);
create table public.inventory (
 user_id uuid references public.profiles on delete cascade,
 item_id text references public.shop_items, acquired_at timestamptz not null default now(),
 primary key(user_id,item_id)
);
create table public.placements (
 user_id uuid references public.profiles on delete cascade,
 item_id text references public.shop_items, room text not null,
 x double precision not null check(x between 0.08 and 0.92),
 y double precision not null check(y between 0.15 and 0.85),
 primary key(user_id,item_id),
 foreign key(user_id,item_id) references public.inventory(user_id,item_id) on delete cascade
);
create index user_missions_completed on public.user_missions(user_id,completed_at) where status='completed';
create index profiles_ranking on public.profiles(xp desc,created_at,id);

-- Leitura de catálogos e dados próprios. Nenhum INSERT/UPDATE/DELETE direto pelo cliente.
alter table public.profiles enable row level security;
create policy own_profile on public.profiles for select to authenticated using(id=(select auth.uid()));
grant select on public.profiles to authenticated;
alter table public.missions enable row level security;
create policy catalog_read on public.missions for select to authenticated using(true);
grant select on public.missions to authenticated;
alter table public.achievements enable row level security;
create policy catalog_read on public.achievements for select to authenticated using(true);
grant select on public.achievements to authenticated;
alter table public.shop_items enable row level security;
create policy catalog_read on public.shop_items for select to authenticated using(true);
grant select on public.shop_items to authenticated;
alter table public.user_missions enable row level security;
create policy own_read on public.user_missions for select to authenticated using(user_id=(select auth.uid()));
grant select on public.user_missions to authenticated;
alter table public.user_achievements enable row level security;
create policy own_read on public.user_achievements for select to authenticated using(user_id=(select auth.uid()));
grant select on public.user_achievements to authenticated;
alter table public.inventory enable row level security;
create policy own_read on public.inventory for select to authenticated using(user_id=(select auth.uid()));
grant select on public.inventory to authenticated;
alter table public.placements enable row level security;
create policy own_read on public.placements for select to authenticated using(user_id=(select auth.uid()));
grant select on public.placements to authenticated;
revoke all on public.profiles, public.missions, public.user_missions, public.achievements, public.user_achievements, public.shop_items, public.inventory, public.placements from anon, authenticated;
grant select on public.profiles, public.missions, public.user_missions, public.achievements, public.user_achievements, public.shop_items, public.inventory, public.placements to authenticated;
create function larquest_private.new_player() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,nickname) values(new.id, left(coalesce(nullif(trim(new.raw_user_meta_data->>'nickname'),''),'Jogador'),30));
 return new;
end $$;
revoke all on function larquest_private.new_player() from public,anon,authenticated;
create trigger larquest_new_player after insert on auth.users for each row execute function larquest_private.new_player();
-- Compatível com usuários criados antes da execução deste script.
insert into public.profiles(id,nickname) select id,left(coalesce(nullif(trim(raw_user_meta_data->>'nickname'),''),'Jogador'),30) from auth.users on conflict do nothing;

-- Função privilegiada privada: auth.uid() define o jogador; nunca aceita user_id ou pontos do cliente.
create function larquest_private.perform_action(action text, mission text default null, item text default null, room_name text default null, pos_x double precision default null, pos_y double precision default null, new_name text default null)
returns void language plpgsql security definer set search_path='' as $$
declare uid uuid:=auth.uid(); reward integer; product public.shop_items; total_count integer; days_count integer; recycling_count integer;
begin
 if uid is null then raise exception 'Autenticação necessária.'; end if;
 -- Serializa compras, conclusões e posicionamento da mesma conta.
 perform 1 from public.profiles where id=uid for update;
 if not found then raise exception 'Perfil não encontrado.'; end if;
 if action='start' then
  perform 1 from public.missions where id=mission;
  if not found then raise exception 'Missão não encontrada.'; end if;
  insert into public.user_missions(user_id,mission_id,status) values(uid,mission,'in_progress') on conflict do nothing;
 elsif action='complete' then
  select points into reward from public.missions where id=mission;
  if not found then raise exception 'Missão não encontrada.'; end if;
  if not exists(select 1 from public.user_missions where user_id=uid and mission_id=mission and status='in_progress') then
   raise exception 'Inicie esta missão antes de concluir. Missões concluídas não concedem novos pontos.';
  end if;
  update public.user_missions set status='completed',completed_at=now() where user_id=uid and mission_id=mission;
  update public.profiles set xp=xp+reward,coins=coins+reward where id=uid;
  select count(*),count(distinct (u.completed_at at time zone 'America/Sao_Paulo')::date),count(*) filter(where m.category='Reciclagem')
   into total_count,days_count,recycling_count from public.user_missions u join public.missions m on m.id=u.mission_id where u.user_id=uid and u.status='completed';
  insert into public.user_achievements(user_id,achievement_id)
   select uid,id from public.achievements where threshold <= case metric when 'total' then total_count when 'days' then days_count when 'recycling' then recycling_count end on conflict do nothing;
 elsif action='buy' then
  select * into product from public.shop_items where id=item;
  if not found then raise exception 'Produto não encontrado.'; end if;
  if exists(select 1 from public.inventory where user_id=uid and item_id=item) then raise exception 'Você já possui este item.'; end if;
  update public.profiles set coins=coins-product.price where id=uid and coins>=product.price;
  if not found then raise exception 'Moedas insuficientes. Conclua mais tarefas!'; end if;
  insert into public.inventory(user_id,item_id) values(uid,item);
 elsif action='place' then
  select s.* into product from public.shop_items s join public.inventory i on i.item_id=s.id where i.user_id=uid and s.id=item;
  if not found or product.kind='color' then raise exception 'Você não possui esta mobília.'; end if;
  if room_name is distinct from product.room then raise exception 'Este item pertence a outro cômodo.'; end if;
  if pos_x is null or pos_y is null or not(pos_x between 0.08 and 0.92) or not(pos_y between 0.15 and 0.85) then raise exception 'Posição inválida.'; end if;
  insert into public.placements values(uid,item,room_name,pos_x,pos_y) on conflict(user_id,item_id) do update set room=excluded.room,x=excluded.x,y=excluded.y;
 elsif action='remove' then
  delete from public.placements where user_id=uid and item_id=item;
 elsif action='color' then
  if item<>'sage' and not exists(select 1 from public.inventory i join public.shop_items s on s.id=i.item_id where i.user_id=uid and s.kind='color' and s.color=item) then raise exception 'Desbloqueie esta cor na loja.'; end if;
  if item not in ('sage','rose','sky','sun') or item is null then raise exception 'Cor inválida.'; end if;
  update public.profiles set mascot_color=item where id=uid;
 elsif action='nickname' then
  if new_name is null or char_length(trim(new_name)) not between 1 and 30 then raise exception 'Use um apelido de 1 a 30 caracteres.'; end if;
  update public.profiles set nickname=trim(new_name) where id=uid;
 else raise exception 'Operação inválida.';
 end if;
end $$;
revoke all on function larquest_private.perform_action(text,text,text,text,double precision,double precision,text) from public,anon;
grant execute on function larquest_private.perform_action(text,text,text,text,double precision,double precision,text) to authenticated;
-- RPC pública é invoker; os detalhes privilegiados ficam no schema não exposto.
create function public.game_action(action text, mission text default null, item text default null, room_name text default null, pos_x double precision default null, pos_y double precision default null, new_name text default null)
returns void language sql security invoker set search_path='' as $$ select larquest_private.perform_action(action,mission,item,room_name,pos_x,pos_y,new_name) $$;
revoke all on function public.game_action(text,text,text,text,double precision,double precision,text) from public,anon;
grant execute on function public.game_action(text,text,text,text,double precision,double precision,text) to authenticated;
-- Ranking só divulga apelido, XP e ID; nunca e-mail/saldo. Inclui top 100 + posição própria.
create function larquest_private.ranking() returns table("position" bigint,id uuid,nickname text,xp integer)
language sql stable security definer set search_path='' as $$
 with ranks as (select row_number() over(order by p.xp desc,p.created_at,p.id) "position",p.id,p.nickname,p.xp from public.profiles p where auth.uid() is not null)
 select * from ranks where "position"<=100 or id=auth.uid() order by "position"
$$;
revoke all on function larquest_private.ranking() from public,anon;
grant execute on function larquest_private.ranking() to authenticated;
create function public.get_ranking() returns table("position" bigint,id uuid,nickname text,xp integer)
language sql stable security invoker set search_path='' as $$ select * from larquest_private.ranking() $$;
revoke all on function public.get_ranking() from public,anon;
grant execute on function public.get_ranking() to authenticated;

insert into public.achievements values
 ('first','Primeiros passos','Conclua sua primeira tarefa.','total',1),
 ('five','Lar em harmonia','Conclua cinco tarefas domésticas.','total',5),
 ('days','Consistência','Conclua tarefas em três dias diferentes.','days',3),
 ('recycle','Mestre da reciclagem','Conclua três missões de reciclagem.','recycling',3),
 ('all','Guardião do lar','Conclua todas as 16 tarefas.','total',16);
insert into public.shop_items values
 ('plant','Planta da sala','plant','Sala',25,null),('rug','Tapete aconchegante','rug','Sala',40,null),
 ('sofa','Sofá nuvem','sofa','Sala',90,null),('table','Mesa de jantar','table','Cozinha',65,null),
 ('chair','Cadeira de madeira','chair','Cozinha',35,null),('bed','Cama dos sonhos','bed','Quarto',90,null),
 ('lamp','Luminária lunar','lamp','Quarto',30,null),('bath','Banheira relax','bath','Banheiro',80,null),
 ('bathplant','Jardim do banho','plant','Banheiro',25,null),
 ('rose','Mascote rosa','color',null,45,'rose'),('sky','Mascote azul','color',null,45,'sky'),('sun','Mascote dourado','color',null,60,'sun');
insert into public.missions values
('sala-objetos','Cada coisa em seu lugar','Recolha os objetos espalhados e devolva cada um ao seu lugar.','Sala','Organização','Fácil',25,array['Recolha brinquedos e objetos soltos.','Separe o que pertence a outros cômodos.','Guarde os objetos e libere as superfícies.'],0),
('sala-po','Um respiro para a sala','Remova o pó dos móveis e deixe a sala mais confortável.','Sala','Limpeza','Fácil',30,array['Use um pano adequado à superfície.','Comece pelos móveis mais altos.','Finalize as mesas e prateleiras.'],1),
('sala-chao','Chão de abraço','Varra o chão e finalize com um pano quando apropriado.','Sala','Limpeza','Média',40,array['Retire obstáculos do caminho.','Varra ou aspire a área.','Use produto adequado ao piso e espere secar.'],2),
('sala-economia','Modo economia','Apague luzes desnecessárias e aproveite a luz natural.','Sala','Sustentabilidade','Fácil',20,array['Confira quais lâmpadas estão acesas.','Apague as que não são necessárias.','Abra as cortinas quando for seguro.'],3),
('cozinha-louca','Louça em dia','Lave e guarde a louça usada.','Cozinha','Limpeza','Média',40,array['Separe a louça com cuidado.','Lave sem deixar a torneira aberta desnecessariamente.','Seque e guarde. Evite manusear objetos cortantes sem orientação.'],4),
('cozinha-bancada','Bancada livre','Organize e higienize a bancada da cozinha.','Cozinha','Limpeza','Fácil',30,array['Retire objetos e restos de alimentos.','Limpe com produto adequado.','Nunca misture produtos de limpeza.'],5),
('cozinha-reciclar','Separar para transformar','Separe embalagens recicláveis do lixo comum.','Cozinha','Reciclagem','Fácil',35,array['Identifique embalagens recicláveis.','Esvazie e separe os materiais secos.','Deixe-os no recipiente correto.'],6),
('cozinha-compra','Consumo inteligente','Planeje uma compra sem desperdício.','Cozinha','Sustentabilidade','Média',30,array['Veja o que já existe na despensa.','Confira a validade.','Monte uma lista apenas com o necessário.'],7),
('quarto-cama','Bom dia, caminha','Arrume sua cama e comece com uma pequena vitória.','Quarto','Organização','Fácil',25,array['Estique o lençol.','Ajeite cobertas e travesseiros.','Libere a área ao redor da cama.'],8),
('quarto-roupas','Guarda-roupa feliz','Separe roupas limpas, sujas e peças para doação.','Quarto','Organização','Média',40,array['Coloque as roupas sujas no cesto.','Dobre e guarde as roupas limpas.','Separe doações com autorização do responsável.'],9),
('quarto-reutilizar','Uma nova história','Dê uma nova utilidade a uma caixa ou pote.','Quarto','Reciclagem','Média',35,array['Escolha um objeto limpo e seguro.','Planeje uma nova função como organizador.','Coloque a ideia em prática sem ferramentas perigosas.'],10),
('quarto-mesa','Espaço para criar','Organize sua mesa de estudo.','Quarto','Organização','Fácil',25,array['Separe papéis e materiais.','Guarde o que não está em uso.','Deixe apenas o essencial na mesa.'],11),
('banheiro-pia','Pia brilhando','Limpe a pia e organize os produtos.','Banheiro','Limpeza','Média',35,array['Guarde os produtos.','Limpe a pia com material adequado.','Não misture químicos. Peça orientação quando necessário.'],12),
('banheiro-toalhas','Toalhas ao sol','Troque e organize as toalhas.','Banheiro','Organização','Fácil',25,array['Coloque as toalhas usadas para lavar.','Pendure as toalhas limpas.','Deixe-as em local ventilado.'],13),
('banheiro-lixo','Descarte consciente','Separe embalagens vazias de produtos de higiene.','Banheiro','Reciclagem','Fácil',30,array['Identifique embalagens vazias recicláveis.','Não abra nem reutilize produtos químicos.','Separe no destino adequado.'],14),
('banheiro-agua','Cada gota importa','Confira torneiras e evite desperdício de água.','Banheiro','Sustentabilidade','Fácil',20,array['Verifique se as torneiras ficaram abertas.','Feche sem forçar.','Avise um responsável se perceber vazamentos.'],15);
commit;
