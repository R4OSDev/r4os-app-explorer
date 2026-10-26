# EXPLORER.R4X

`EXPLORER.R4X` is an independent R4OS application implemented in Zig.

## Package

- Version: see `module.R4MF`
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

The `.sfc` and `.smc` associations resolve only the stable `r4os.snes` and
`snes.cartridge` IDs. Since SNES images provide no universal fixed-position
magic, their installed catalog entry intentionally requests zero probe bytes;
the selected R4SNES instance validates the entire cartridge and any firmware
requirement after launch.

The console `/SELFTEST` path acquires only R4SYS and its imported R4STD
helpers. It deliberately skips unused GUI, network and device contexts, so
the association/filesystem diagnostic cannot wait behind unrelated SMP work
during headless acceptance.

`/SELFTEST /FILES` selects the same real copy/move/delete cases without the
independent subsystem fixtures. Probe paths include the exact process instance
and generation. Creation is exclusive and cleanup follows actual ownership
receipts; existing files are never removed to prepare a probe.
`/SELFTEST /FILES /QUIET` silences successful probe text; errors remain visible
and every file assertion still runs. Normal background
instances declare `runtime.parallel=owned-v1` and retain one GUI producer.

## Build

On Windows:

    Build.bat

On Linux:

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


Directory generations (0.81.26)
-------------------------------
A complete bounded snapshot is sorted once per unchanged directory generation.
Page navigation reuses it. Enumeration returns metadata with each name.
A changed generation, read failure or allocation failure preserves the last
complete view until a replacement succeeds; no partial success is published.
Each snapshot is limited to 16 MB, with temporary overlap during replacement.

Unicode name dialogs (0.85.43): use whole codepoint events, exact preloads
from the full path rather than a shortened label, and checked whole UTF8 paste.
The existing48-byte name/128-byte path budgets are explicit: failure retains
input and never invents a clipped target. Unicode scalar names are accepted
within those budgets; invalid/control/path characters fail before mutation.
New empty files use create-only stream admission; an existing file is preserved.
Build.sh dialog-text-test (Build.bat on Windows) and the same-source console
fixture Tests/DialogText /DIALOGTEST cover these owners and real Unicode rename
with exact binary bytes. Display/font, normalization and graphemes are separate.

0.85.44: Rebuilt with SDK0.64.57 and the shared R4STD Unicode17.0.0
extended grapheme editing boundaries. Byte offsets, scalar font advances
and grapheme clusters are distinct; no shaping or BiDi support is implied.

Selection updates (0.87.8)
-------------------------
After a successful complete frame, ordinary single-selection changes publish
only the previous/new visible labels and status bar using the existing
immutable GUI damage contract. The toolbar, address, other icons and their
resources remain in the prior generation. Eight delta frames at most precede
a complete frame, bounding retained generations. Scroll, resize, overlays,
Select All, folder/refresh operations and failed transactions use complete
frames. A delta never acknowledges a failed complete publication.

Generation-owned folder work (0.87.44)
--------------------------------------
Main publishes a loading frame while retaining the committed view. One copied
BSP native worker reads bounded directory batches and advances a bounded heap
sort. Superseded generations stop at checkpoints and remain pinned until exact
native join. Main commits complete, validated snapshots atomically. Shortcut
contents are resolved in a separate metadata phase after the base view is
published, then privately resorted. Selection uses full entry identity across
resort; stale results cannot restore an old location or repeat history actions.
No partial unsorted rows or AP filesystem execution is introduced.

Build.sh navigation-test drive-free-test dialog-text-test (Build.bat on Windows)
checks the actual owners, sort budgets, page boundaries and selection identity.
The same-source EXPTEXT fixture adds native joins/late-result/mutation/drain
checks. SPECTRA CHECK DESKTOP /HOST /NAV explicitly checks real GUI input and
close during current product work. These checks do not measure physical latency.
