-- =============================================================================
-- BONBONK / FLIP - SCHÉMA DE BASE DE DONNÉES SUPABASE (ISOLATION SCHÉMA 'bonbonk')
-- =============================================================================
-- Ce script configure l'intégralité du backend dans un schéma dédié 'bonbonk'
-- qui cohabite sans aucun conflit avec vos autres projets dans la même base Supabase :
-- 1. Création et permissions du schéma 'bonbonk'
-- 2. Table des profils joueurs (bonbonk.player_profiles) avec sauvegarde JSONB
-- 3. Journal inviolable des achats / micro-transactions (bonbonk.purchases_ledger)
-- 4. Sécurité Row Level Security (RLS) étanche par joueur
-- 5. Triggers d'identité pour la liaison de compte (Google Play, Apple, Email)
-- 6. Vue publique des classements (bonbonk.leaderboard_survival)
-- =============================================================================

-- 1. CRÉATION DU SCHÉMA DÉDIÉ ET PERMISSIONS
create schema if not exists bonbonk;

-- Activer l'extension UUID si nécessaire
create extension if not exists "uuid-ossp";

-- Accorder l'accès au schéma pour l'API PostgREST (rôles anon et authenticated)
grant usage on schema bonbonk to anon, authenticated, service_role;
grant all on all tables in schema bonbonk to anon, authenticated, service_role;
grant all on all routines in schema bonbonk to anon, authenticated, service_role;
grant all on all sequences in schema bonbonk to anon, authenticated, service_role;
alter default privileges in schema bonbonk grant all on tables to anon, authenticated, service_role;
alter default privileges in schema bonbonk grant all on routines to anon, authenticated, service_role;
alter default privileges in schema bonbonk grant all on sequences to anon, authenticated, service_role;

-- =============================================================================
-- 2. TABLE DES PROFILS JOUEURS (bonbonk.player_profiles)
-- =============================================================================
create table if not exists bonbonk.player_profiles (
    -- Clé primaire liée 1-to-1 à l'identifiant immuable auth.users(id)
    id uuid primary key references auth.users(id) on delete cascade,
    
    -- Nom public du joueur
    display_name text not null default 'Gourmand',
    
    -- Type de compte : 'guest' (invité anonyme) ou 'cloud' (lié email/Google/Apple)
    account_type text not null default 'guest',
    
    -- Privilèges d'administration et outils de développement
    is_admin boolean not null default false,
    
    -- Soldes des monnaies (pour requêtes rapides sans parser le JSON)
    gold int not null default 250,
    diamonds int not null default 30,
    
    -- Progression du Mode Campagne
    campaign_unlocked_world int not null default 1,
    campaign_unlocked_level int not null default 1,
    
    -- Records du Mode Survie
    survival_best_wave int not null default 0,
    survival_best_score int not null default 0,
    
    -- Données de sauvegarde complètes (inventaire cartes, decks, étoiles par niveau, boosters)
    data jsonb not null default '{}'::jsonb,
    
    -- Liste des fournisseurs liés : ex: ['anonymous'], ['anonymous', 'google'], ['apple']
    linked_providers text[] not null default array['anonymous']::text[],
    
    -- Identifiants de services tiers pour liaison & support
    google_play_id text unique,
    apple_game_center_id text unique,
    email text unique,
    
    -- Compteur de révision et horodatage pour résolution non-destructive de conflits
    sync_revision int not null default 1,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists idx_bbk_profiles_updated_at on bonbonk.player_profiles (updated_at desc);
create index if not exists idx_bbk_profiles_survival_best on bonbonk.player_profiles (survival_best_wave desc, survival_best_score desc);

-- =============================================================================
-- 3. JOURNAL DES TRANSACTIONS & ACHATS IN-APP (bonbonk.purchases_ledger)
-- AUCUNE PERTE DE DONNÉES FINANCIÈRE TOLÉRÉE
-- =============================================================================
create table if not exists bonbonk.purchases_ledger (
    -- Identifiant unique de transaction généré par le client ou le store (UUID / Order ID)
    tx_id text primary key,
    
    -- Joueur ayant effectué l'achat
    user_id uuid not null references auth.users(id) on delete cascade,
    
    -- Identifiant du produit (ex: "pack_diamonds_tier_1", "starter_pack")
    product_id text not null,
    
    -- Montant payé et devise
    amount_paid numeric(10, 2) not null default 0.00,
    currency text not null default 'EUR',
    
    -- Récompenses attribuées
    granted_diamonds int not null default 0,
    granted_gold int not null default 0,
    granted_items jsonb not null default '{}'::jsonb,
    
    -- Plateforme du store : 'google_play', 'app_store', 'sandbox'
    platform text not null default 'sandbox',
    
    -- Reçu brut ou token de signature cryptographique du store (Google/Apple receipt)
    receipt_data text,
    
    -- Statut de validation serveur : 'completed', 'pending_verification', 'refunded'
    status text not null default 'completed',
    
    created_at timestamptz not null default now()
);

create index if not exists idx_bbk_purchases_user_id on bonbonk.purchases_ledger (user_id);

-- =============================================================================
-- 4. SÉCURITÉ ROW LEVEL SECURITY (RLS)
-- =============================================================================
alter table bonbonk.player_profiles enable row level security;
alter table bonbonk.purchases_ledger enable row level security;

-- Politiques RLS pour player_profiles :
create policy "Les joueurs peuvent lire leur propre profil"
    on bonbonk.player_profiles for select
    using (auth.uid() = id);

create policy "Les joueurs peuvent créer leur propre profil"
    on bonbonk.player_profiles for insert
    with check (auth.uid() = id);

create policy "Les joueurs peuvent modifier leur propre profil"
    on bonbonk.player_profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- Politiques RLS pour purchases_ledger :
create policy "Les joueurs peuvent consulter leurs achats"
    on bonbonk.purchases_ledger for select
    using (auth.uid() = user_id);

create policy "Les joueurs peuvent enregistrer un achat"
    on bonbonk.purchases_ledger for insert
    with check (auth.uid() = user_id);

-- =============================================================================
-- 5. TRIGGERS AUTOMATIQUES
-- =============================================================================

-- A. Création automatique du profil lors de l'inscription
create or replace function bonbonk.handle_new_user()
returns trigger as $$
begin
    insert into bonbonk.player_profiles (id, display_name, account_type, linked_providers, email, created_at, updated_at)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'display_name', 'Gourmand_' || substr(new.id::text, 1, 6)),
        case when coalesce(new.is_anonymous, false) then 'guest' else 'cloud' end,
        case when coalesce(new.is_anonymous, false) then array['anonymous']::text[] else array[coalesce(new.raw_app_meta_data->>'provider', 'email')]::text[] end,
        new.email,
        now(),
        now()
    )
    on conflict (id) do nothing;
    return new;
end;
$$ language plpgsql security definer;

-- Déclencheur à la création d'un utilisateur dans auth.users
drop trigger if exists on_auth_user_created_bonbonk on auth.users;
create trigger on_auth_user_created_bonbonk
after insert on auth.users
for each row execute function bonbonk.handle_new_user();

-- B. Mise à jour automatique des linked_providers lors d'une liaison de compte
create or replace function bonbonk.handle_identity_linked()
returns trigger as $$
begin
    update bonbonk.player_profiles
    set 
        linked_providers = array_append(linked_providers, new.provider),
        account_type = 'cloud',
        email = coalesce(email, new.identity_data->>'email'),
        updated_at = now()
    where id = new.user_id
      and not (new.provider = any(linked_providers));
    return new;
end;
$$ language plpgsql security definer;

-- Déclencheur sur la table interne auth.identities
drop trigger if exists on_identity_linked_bonbonk on auth.identities;
create trigger on_identity_linked_bonbonk
after insert on auth.identities
for each row execute function bonbonk.handle_identity_linked();

-- =============================================================================
-- 6. VUE & RPC PUBLIQUES DES CLASSEMENTS (LEADERBOARDS)
-- =============================================================================
create or replace view bonbonk.leaderboard_survival as
select
    id as user_id,
    display_name,
    survival_best_wave,
    survival_best_score,
    updated_at as recorded_at
from bonbonk.player_profiles
where survival_best_score > 0
order by survival_best_wave desc, survival_best_score desc;

grant select on bonbonk.leaderboard_survival to anon, authenticated;

-- RPC Security Definer : garantit l'accès aux classements pour tous sans divulguer les données privées
create or replace function bonbonk.get_survival_leaderboard(limit_count int default 50)
returns table (
    user_id uuid,
    display_name text,
    survival_best_wave int,
    survival_best_score int,
    recorded_at timestamptz
)
language sql
security definer
set search_path = bonbonk, public
as $$
    select id, display_name, survival_best_wave, survival_best_score, updated_at
    from bonbonk.player_profiles
    where survival_best_score > 0
    order by survival_best_wave desc, survival_best_score desc
    limit limit_count;
$$;

grant execute on function bonbonk.get_survival_leaderboard(int) to anon, authenticated;

-- =============================================================================
-- FIN DU SCRIPT SQL
-- =============================================================================
