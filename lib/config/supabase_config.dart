/// Identifiants de connexion au projet Supabase. La clé publique
/// ("publishable"/anon) est conçue pour être embarquée dans le client
/// (protection réelle assurée côté Supabase par les règles RLS, pas
/// par le secret de cette clé).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url =
      'https://xcugfdjaifdibwowlrpi.supabase.co';

  static const String publishableKey =
      'sb_publishable_3j5-ynSda2sUBJD6my4KEQ_-_gICd11';
}
