# Data: multilingual Scratch wiki revision histories

Six anonymized revision-history datasets, one per Scratch wiki language
community, collected via the MediaWiki Action API using
`../scripts/collect_wiki_data.R`.

| File | Community | Status |
|---|---|---|
| `wiki_df_events_id.csv` | id.scratch-wiki.info (Indonesian) | included in this repository |
| `wiki_df_events_en.csv` | scratch-wiki.info (English) | included in this repository |
| `wiki_df_events_fr.csv` | fr.scratch-wiki.info (French) | included in this repository |
| `wiki_df_events_de.csv` | de.scratch-wiki.info (German) | included in this repository|
| `wiki_df_events_ru.csv` | ru.scratch-wiki.info (Russian) | included in this repository |
| `wiki_df_events_ja.csv` | ja.scratch-wiki.info (Japanese) | included in this repository|

All six files share an identical schema (see Table 0 in the paper, Section 2.2):

| Column | Description |
|---|---|
| `pageid` | Numeric MediaWiki page identifier |
| `page_title` | Page title at time of extraction (may change if the page was renamed) |
| `revid` | Revision identifier |
| `parentid` | Identifier of the preceding revision on the same page (if any) |
| `commit_time` | Revision timestamp, ISO 8601 UTC |
| `author_id` | Numeric MediaWiki user identifier |
| `author_name` | Username at time of extraction (may change if the user was renamed) |
| `author_type` | `human`, `bot`, or `system`, assigned from the MediaWiki user-group / bot flag |
| `rev_size` | Revision size in bytes |
| `minor` | Minor-edit flag |
| `anon` | Anonymous-edit flag |
| ... | additional fields as produced by `collect_wiki_data.R` |

## Anonymization / privacy note

Usernames are the pseudonymous handles already publicly visible in each wiki's
own page-history interface; no additional identifying information is included.
No IP addresses are retained for anonymous edits. See the paper's Section 2.4
for the full ethics statement covering this data.
