// Diagnostic harness removed once the pull-to-refresh root cause was found:
// GeometryReader does not re-evaluate on pure translation, so the classic
// PreferenceKey scroll-offset trick fires exactly once. Kept as a file so the
// technique is discoverable — instrument, measure, then fix.
