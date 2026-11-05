# Swift Kit UI

**55 free, MIT-licensed SwiftUI components** with the motion, haptics and accessibility already done. One file each, no dependencies beyond a single foundation file.

**Browse every component with a live preview: https://theswiftk.it.com/ui**

- Copy-paste: each component is one `.swift` file.
- No packages: everything depends only on `SwiftKitUI.swift` (tokens, spring curves, haptics, Liquid Glass surfaces).
- iOS 17+ and macOS 14+. `SKRefreshableScrollView` needs iOS 18.
- Built for AI agents too: point Cursor, Claude Code or Copilot at https://theswiftk.it.com/ui/llms.txt

## Install

**Copy the files:** add [`Sources/SwiftKitUI/SwiftKitUI.swift`](Sources/SwiftKitUI/SwiftKitUI.swift) to your app once, then copy any file from [`Sources/SwiftKitUI/Components/`](Sources/SwiftKitUI/Components/).

**Or use Swift Package Manager:** in Xcode choose *File → Add Package Dependencies…* and enter `https://github.com/adgan11/swift-kit-ui`, then `import SwiftKitUI`.

## Components

### Controls

| Component | Live preview + docs |
|---|---|
| **Toggle** — A toggle you can *drag*, not just tap | [theswiftk.it.com/swiftui/toggle](https://theswiftk.it.com/swiftui/toggle) |
| **Wheel Picker** — A horizontal ruler picker — the control you want for weight, age, duration, tempo | [theswiftk.it.com/swiftui/wheel-picker](https://theswiftk.it.com/swiftui/wheel-picker) |
| **Slider** — A slider that grows under your thumb and ticks haptically as it crosses steps | [theswiftk.it.com/swiftui/slider](https://theswiftk.it.com/swiftui/slider) |
| **Color Swatch Picker** — A swatch grid | [theswiftk.it.com/swiftui/color-picker](https://theswiftk.it.com/swiftui/color-picker) |
| **Segmented Control** — The indicator slides between segments via matchedGeometryEffect rather than cutting | [theswiftk.it.com/swiftui/segmented-control](https://theswiftk.it.com/swiftui/segmented-control) |
| **Stepper** — Minus / value / plus, with press-and-hold repeat that accelerates | [theswiftk.it.com/swiftui/stepper](https://theswiftk.it.com/swiftui/stepper) |
| **Rating** — Star rating you can tap or drag across | [theswiftk.it.com/swiftui/rating](https://theswiftk.it.com/swiftui/rating) |
| **Chip** — A selectable tag | [theswiftk.it.com/swiftui/chip](https://theswiftk.it.com/swiftui/chip) |

### Feedback

| Component | Live preview + docs |
|---|---|
| **Activity Indicator** — Three loading indicators that are not the system spinner: bouncing dots, a pulsing arc, and equaliser bars | [theswiftk.it.com/swiftui/progressview](https://theswiftk.it.com/swiftui/progressview) |
| **Tooltip** — A pointed bubble anchored to whatever it is explaining | [theswiftk.it.com/swiftui/tooltip](https://theswiftk.it.com/swiftui/tooltip) |
| **Badge** — A small status pill | [theswiftk.it.com/swiftui/badge](https://theswiftk.it.com/swiftui/badge) |
| **Progress Ring** — A closed circular progress ring, determinate or indeterminate | [theswiftk.it.com/swiftui/progress-ring](https://theswiftk.it.com/swiftui/progress-ring) |
| **Toast** — A transient message, presented as a modifier so it overlays the whole screen instead of being wedged into your layout | [theswiftk.it.com/swiftui/toast](https://theswiftk.it.com/swiftui/toast) |
| **Empty State** — The screen you see when there is nothing to see | [theswiftk.it.com/swiftui/empty-state](https://theswiftk.it.com/swiftui/empty-state) |
| **Skeleton** — Placeholder shapes for loading states | [theswiftk.it.com/swiftui/skeleton](https://theswiftk.it.com/swiftui/skeleton) |

### Actions

| Component | Live preview + docs |
|---|---|
| **Button** — Five button roles on one interruptible press animation | [theswiftk.it.com/swiftui/button](https://theswiftk.it.com/swiftui/button) |
| **Floating Action Button** — A FAB that fans out secondary actions when expanded | [theswiftk.it.com/swiftui/floating-action-button](https://theswiftk.it.com/swiftui/floating-action-button) |

### Navigation

| Component | Live preview + docs |
|---|---|
| **Custom Tab Bar** — A custom tab bar where the selection indicator *travels* between tabs rather than cutting | [theswiftk.it.com/swiftui/custom-tab-bar](https://theswiftk.it.com/swiftui/custom-tab-bar) |
| **Navigation Bar** — A navigation bar that fades in its background as content scrolls under it, rather than sitting on an opaque slab from the first pixel | [theswiftk.it.com/swiftui/navigation-bar](https://theswiftk.it.com/swiftui/navigation-bar) |
| **Page Indicator** — Page dots where the active one stretches into a capsule instead of just changing colour | [theswiftk.it.com/swiftui/page-indicator](https://theswiftk.it.com/swiftui/page-indicator) |
| **Side Menu** — A drawer that slides in from the edge, with the main content pushed and scaled behind it | [theswiftk.it.com/swiftui/side-menu](https://theswiftk.it.com/swiftui/side-menu) |

### Overlays

| Component | Live preview + docs |
|---|---|
| **Alert** — A styled alert that can carry a text field — the thing the system alert technically supports but gives you no control over | [theswiftk.it.com/swiftui/alert](https://theswiftk.it.com/swiftui/alert) |
| **Bottom Sheet** — A draggable bottom sheet you can actually style — grabber, corner radius, backdrop and detents all yours | [theswiftk.it.com/swiftui/sheet](https://theswiftk.it.com/swiftui/sheet) |

### Surfaces

| Component | Live preview + docs |
|---|---|
| **Glass Panel** — iOS 26 Liquid Glass, with a fallback that is actually worth shipping below iOS 26 rather than a flat rectangle | [theswiftk.it.com/swiftui/liquid-glass](https://theswiftk.it.com/swiftui/liquid-glass) |
| **Card** — A container with the kit's standard internal padding | [theswiftk.it.com/swiftui/card](https://theswiftk.it.com/swiftui/card) |
| **Neumorphic Card** — Soft UI: two shadows, one light from the top-left and one dark from the bottom-right, so the surface appears extruded from its background | [theswiftk.it.com/swiftui/neumorphism](https://theswiftk.it.com/swiftui/neumorphism) |

### Inputs

| Component | Live preview + docs |
|---|---|
| **Text Field** — A text field with a label that rises out of the way on focus, a focus ring, and an error state that does not resize the layout when it appears | [theswiftk.it.com/swiftui/textfield](https://theswiftk.it.com/swiftui/textfield) |
| **Search Bar** — Search field with a Cancel button that slides in on focus | [theswiftk.it.com/swiftui/search-bar](https://theswiftk.it.com/swiftui/search-bar) |
| **OTP Field** — One-time-code entry | [theswiftk.it.com/swiftui/otp-field](https://theswiftk.it.com/swiftui/otp-field) |

### Data

| Component | Live preview + docs |
|---|---|
| **Gauge** — An arc gauge | [theswiftk.it.com/swiftui/gauge](https://theswiftk.it.com/swiftui/gauge) |
| **Sparkline** — A compact trend line for cards and rows — no axes, no legend, no chart framework | [theswiftk.it.com/swiftui/sparkline](https://theswiftk.it.com/swiftui/sparkline) |

### Lists

| Component | Live preview + docs |
|---|---|
| **Row** — A list row: optional leading symbol, title, optional subtitle, and whatever you want on the trailing edge | [theswiftk.it.com/swiftui/row](https://theswiftk.it.com/swiftui/row) |
| **Section** — A titled group | [theswiftk.it.com/swiftui/section](https://theswiftk.it.com/swiftui/section) |

### Layout

| Component | Live preview + docs |
|---|---|
| **Accordion** — Expand/collapse with the chevron rotating on the same spring as the height change, so the two read as one movement instead of two | [theswiftk.it.com/swiftui/accordion](https://theswiftk.it.com/swiftui/accordion) |
| **Timeline** — A vertical timeline: order status, activity feeds, onboarding progress | [theswiftk.it.com/swiftui/timeline](https://theswiftk.it.com/swiftui/timeline) |
| **Carousel** — A snapping card carousel | [theswiftk.it.com/swiftui/carousel](https://theswiftk.it.com/swiftui/carousel) |

### Display

| Component | Live preview + docs |
|---|---|
| **Avatar** — Avatar with an initials fallback, an optional presence dot, and a stacked group variant | [theswiftk.it.com/swiftui/avatar](https://theswiftk.it.com/swiftui/avatar) |

### Interaction

| Component | Live preview + docs |
|---|---|
| **Pull To Refresh** — A pull-to-refresh indicator you can brand, unlike `.refreshable`'s fixed system spinner | [theswiftk.it.com/swiftui/pull-to-refresh](https://theswiftk.it.com/swiftui/pull-to-refresh) |

### Decoration

| Component | Live preview + docs |
|---|---|
| **Icon Bubble** — A tinted container for an SF Symbol | [theswiftk.it.com/swiftui/icon-bubble](https://theswiftk.it.com/swiftui/icon-bubble) |

### Delight

| Component | Live preview + docs |
|---|---|
| **Confetti** — A celebration burst for purchases, streaks and completions | [theswiftk.it.com/swiftui/confetti](https://theswiftk.it.com/swiftui/confetti) |

### Ai

| Component | Live preview + docs |
|---|---|
| **Chat Bubble** — A message bubble whose body and tail are one continuous path, so a border follows the silhouette instead of running around two shapes | [theswiftk.it.com/swiftui/chat-bubble](https://theswiftk.it.com/swiftui/chat-bubble) |
| **Streaming Text** — Renders a model response at a steady reading cadence no matter how erratically the tokens arrive | [theswiftk.it.com/swiftui/streaming-text](https://theswiftk.it.com/swiftui/streaming-text) |
| **Chat Composer** — A growing input bar whose trailing button changes job rather than multiplying: dictate when empty, send when there is a draft, stop while the model is answering | [theswiftk.it.com/swiftui/chat-composer](https://theswiftk.it.com/swiftui/chat-composer) |
| **Markdown View** — Markdown rendered as real blocks — headings, lists, quotes, rules and fenced code — with inline parsing handed to Foundation so bold, links and inline code still work inside a bullet | [theswiftk.it.com/swiftui/markdown-view](https://theswiftk.it.com/swiftui/markdown-view) |
| **Code Block** — A code surface with copy-in-place confirmation, an optional gutter, and horizontal scrolling rather than wrapping | [theswiftk.it.com/swiftui/code-block](https://theswiftk.it.com/swiftui/code-block) |
| **Reasoning Block** — The collapsible thinking disclosure, showing the line the model is currently on rather than a spinner | [theswiftk.it.com/swiftui/reasoning-block](https://theswiftk.it.com/swiftui/reasoning-block) |
| **Tool Call Card** — Names the action an agent is taking while it takes it, with an indeterminate bar that proves the app is alive without pretending to measure progress | [theswiftk.it.com/swiftui/tool-call-card](https://theswiftk.it.com/swiftui/tool-call-card) |
| **Citation Chip** — An inline source marker sized to sit inside a sentence without breaking its rhythm, with a fixed minimum width so one- and two-digit citations do not jitter the line | [theswiftk.it.com/swiftui/citation-chip](https://theswiftk.it.com/swiftui/citation-chip) |
| **Token Meter** — Quota usage that changes colour at 70% and 90%, where the copy changes and the upgrade action appears | [theswiftk.it.com/swiftui/token-meter](https://theswiftk.it.com/swiftui/token-meter) |
| **Model Picker** — Model selection in plain language: every row carries a subtitle saying what the trade is and a badge for fast, balanced or powerful, with the raw identifier kept in monospace for the people who want it | [theswiftk.it.com/swiftui/model-picker](https://theswiftk.it.com/swiftui/model-picker) |
| **Prompt Suggestions** — The starter prompts on an empty assistant screen | [theswiftk.it.com/swiftui/prompt-suggestions](https://theswiftk.it.com/swiftui/prompt-suggestions) |
| **Voice Orb** — A microphone target whose ring reacts to real audio level, drawn in a single Canvas so 44 bars cost one draw instead of 44 layout passes | [theswiftk.it.com/swiftui/voice-orb](https://theswiftk.it.com/swiftui/voice-orb) |
| **Message Actions** — Copy, regenerate and rate under a reply | [theswiftk.it.com/swiftui/message-actions](https://theswiftk.it.com/swiftui/message-actions) |
| **Attachment Tray** — Files staged for sending, each with its own progress ring on the thumbnail rather than one shared bar — three uploads at three speeds cannot be described by a single percentage | [theswiftk.it.com/swiftui/attachment-tray](https://theswiftk.it.com/swiftui/attachment-tray) |
| **Conversation Row** — A row for the conversation list, with a timestamp that adapts to age — a time today, a weekday this week, a date beyond | [theswiftk.it.com/swiftui/conversation-row](https://theswiftk.it.com/swiftui/conversation-row) |

## Building a whole app?

These components come from [**The Swift Kit**](https://theswiftk.it.com), a SwiftUI starter project with Sign in with Apple, Supabase, RevenueCat paywalls, onboarding, AI features and analytics already wired up, so you start on the part of your app that is yours.

## License

MIT © Ahmed Gagan. Use it in personal and commercial apps; keep the licence notice with the code.
