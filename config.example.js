// Copy this file to `config.js` and fill in your Supabase project credentials.
// `config.js` is gitignored — `config.example.js` is the template that gets committed.
//
// Find these values in your Supabase project: Settings → API
//   - Project URL    → SUPABASE_URL
//   - anon public key → SUPABASE_ANON_KEY
//
// Both values are safe to expose publicly because Row Level Security (RLS)
// restricts every row to its owning auth.uid().

window.HABBIT_CONFIG = {
  SUPABASE_URL:      "https://YOUR-PROJECT-REF.supabase.co",
  SUPABASE_ANON_KEY: "YOUR-ANON-PUBLIC-KEY",
  // Restrict sign-in to a single email (yours). Leave as "" to allow any email.
  ALLOWED_EMAIL:     "tylercklok@gmail.com"
};
