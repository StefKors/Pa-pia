# AGENTS

## DataMuse API

- Base URL: `https://api.datamuse.com`
- Endpoints:
  - `/words` for word search
  - `/sug` for autocomplete suggestions
- Common params for `/words`:
  - `ml` means-like, `sl` sounds-like, `sp` spelled-like (supports wildcards `*` and `?`)
  - `rel_[code]` related-word constraints (e.g. `rel_syn`, `rel_ant`, `rel_trg`)
  - `topics`, `lc`, `rc` as context hints
  - `v` vocabulary (default English, `es` for Spanish)
  - `md` metadata flags, `qe` query echo, `max` result cap
- Limits:
  - `max` must be <= 1000
  - default `max` is 100 for `/words` and 10 for `/sug`
  - up to 100,000 requests/day without a key
- Notes:
  - Responses are JSON lists of word objects with `word`, `score`, and optional metadata.
  - Results are ordered by semantic strength for meaning queries, otherwise by word popularity.
  - URL-encode query parameters in requests.
  - If the app is public, acknowledge the Datamuse API in docs.
