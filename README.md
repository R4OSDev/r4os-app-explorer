# EXPLORER.R4X

`EXPLORER.R4X` is an independent R4OS application implemented in Zig.

## Package

- Version: `0.1.8`
- Image target: `/R4OS/SOFTWARE/DESKTOP/EXPLORER.R4X`
- Image scope: `slim`
- Canonical project manifest: `module.R4MF`

The manifest is the single source of truth for the artifact, imports, image
target, and package metadata.

File opening, R4LNK file targets, and Open With share the R4STD handler
resolver for ordinary applications and installed subsystem R4X hosts. The
shipped `.BAS` default resolves to `r4os.basic`; Notepad remains available in
the same Open With list for source editing. An unambiguous association uses
file metadata only. Unknown or ambiguous paths fall back to a bounded 256 KiB
range probe, while the selected subsystem remains the sole owner of its full
guest source load.

## Build

On Windows:

    Build.bat

On Linux or macOS:

    ./Build.sh

The build starters resolve the current local R4OS dependency checkouts through
`Settings.R4S`. The URL and hash entries in `build.zig.zon` record the
last verified standalone dependency identities; workspace builds use the
mapped local checkouts.

## Documentation

Detailed German technical notes from the migration are preserved in
`DOCUMENTATION.de.txt`. Source-transfer provenance is recorded in
`PROVENANCE.txt`.

## License

Original R4OS material is licensed under Apache License 2.0. See `LICENSE`
and `NOTICE`. Any repository-specific external material is documented in
`THIRD_PARTY_NOTICES.md`.
