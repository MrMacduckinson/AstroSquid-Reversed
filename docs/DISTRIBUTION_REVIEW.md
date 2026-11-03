# Distribution review — 2026-11-03

This review covers the current source/resource/documentation files and packaged
application bundles distributed in the repository snapshot, then the generated
release ZIPs. It does not certify historical Git objects or unrelated private
working directories. The distributable repository snapshot excludes `.git`.

## Language

The remaining Russian prose in README, status, changelog, source guide, application
instructions, compatibility guides, provenance, comparison and known-gap notes
was translated into English. A UTF-8 text scan found no remaining Cyrillic in the
current distributable project files. Original game resources and numerical
fixtures were preserved; historical commits were not rewritten.

## Private material

Checks covered private-key PEM/OpenSSH markers, common credential/token formats,
credential assignments, sensitive key/config filenames, and known personal paths
and private test-machine addresses. No matching secrets or private operational
context were found in the distributable files. No SSH keys, SSH configuration,
user preference/score profiles, migration archive or private access notes are
included. The two tracked validation screenshots were visually reviewed and
contain game frames, not the user's desktop or account information.

This is a targeted review, not proof that every possible encoding of a secret can
be recognized. Third-party author/copyright information and original game assets
are intentionally retained; see THIRD_PARTY.md.

## Packaging

The repository archive is generated from `git archive` and therefore contains
only committed project files, plus its source revision record. Application and
source ZIPs exclude nonessential resource forks, extended attributes and
quarantine metadata. These are modern macOS bundles; their required game resources
are ordinary files and are retained. The ZIPs do not include the private build SDK.

Current application payload hashes are checked against Applications/SHA256SUMS.
The completed ZIPs are checked for archive integrity, source revision, excluded
metadata and credential/language candidates. Review the newly generated archives
again if adding files, logs or screenshots in a later release.
