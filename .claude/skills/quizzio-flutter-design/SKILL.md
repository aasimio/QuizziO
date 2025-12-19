---
name: quizzio-flutter-design
description: Create distinctive, production-grade Flutter mobile interfaces with high design quality for QuizziO. Use this skill when building screens, widgets, components, or styling any UI element. Generates polished, accessible code that avoids generic AI aesthetics while maintaining Material 3 consistency.
---

# QuizziO Flutter Design Skill

This skill guides creation of distinctive, production-grade Flutter mobile interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices tailored for our teacher-focused OMR scanner app.

## 🎯 Design Thinking (Before Coding)

Before implementing any UI, understand the context:

### User Context
- **Primary User**: Teachers/professors (Mrs. Priya persona) - not deeply technical, needs intuitive UX
- **Environment**: Classrooms, exam halls, often with poor lighting and time pressure
- **Device**: Mid-range smartphones, varying screen sizes (4.7" - 12.9")
- **Mental State**: Busy, task-focused, needs confidence that scanning worked correctly

### Tone & Aesthetic Direction
QuizziO should feel:
- **Professional but Warm**: Not sterile corporate, not playful toy-like
- **Confident & Clear**: Strong visual hierarchy, obvious affordances
- **Trustworthy**: Teachers need to trust the grading accuracy—UI should reinforce reliability
- **Efficient**: Minimal cognitive load, fast task completion

**Recommended Aesthetic**: Clean editorial meets utility tool—think "premium productivity app" with purposeful use of color for status/feedback.

---

## 🎨 Flutter Aesthetics Guidelines

### Typography
```dart
// ❌ AVOID: Generic system defaults
fontFamily: null, // Falls back to Roboto

// ✅ PREFER: Distinctive, readable choices
// Display/Headers: Something with character
// Body: Highly legible, professional

// Recommended pairings for QuizziO:
// Option A: Outfit (headers) + Source Sans 3 (body)
// Option B: Plus Jakarta Sans (headers) + DM Sans (body)  
// Option C: Manrope (headers) + Inter (body only if paired distinctively)
```

**Typography Rules**:
- Use `GoogleFonts` package for custom fonts
- Headers: Bold/semibold, generous sizing (24-32sp for screen titles)
- Body: Regular weight, 14-16sp for readability
- Scores/Numbers: Consider monospace or tabular figures for alignment

### Color & Theme
```dart
// ❌ AVOID: Generic purple gradients, bland grays
// ❌ AVOID: Too many competing colors

// ✅ PREFER: Strong primary with purposeful accents
// Build around semantic meaning:

// Primary: Action/Interactive (scanning button, CTAs)
// Success: Correct answers, successful scans (green family)
// Warning: Multiple marks, blanks (amber family)
// Error: Failed scans, incorrect answers (red family)
// Neutral: Backgrounds, cards, dividers

// Example palette direction:
// Deep teal primary (#0D7377) - trustworthy, professional
// Warm coral accent (#FF6B6B) - energy for actions
// Soft mint success (#4ECDC4) - calm confirmation
// Cream/off-white backgrounds (#F7F7F2) - easy on eyes
```

**Color Rules**:
- Use `ColorScheme.fromSeed()` with M3, then customize
- Dark mode: Not just inverted—consider teacher grading at night
- High contrast for scanner alignment guides (must be visible in varied lighting)
- Score displays: Color-code ranges (green >80%, amber 50-80%, red <50%)

### Motion & Micro-interactions
```dart
// ❌ AVOID: No animations (feels dead) OR excessive bouncing (feels toy-like)

// ✅ PREFER: Purposeful, confidence-building animations

// High-impact moments for QuizziO:
// 1. Scanner alignment: Smooth guide transitions (red → green)
// 2. Capture success: Satisfying "shutter" animation + haptic
// 3. Score reveal: Brief count-up or scale-in for impact
// 4. List items: Staggered fade-in on screen load
// 5. Button feedback: Subtle scale + color shift on press
```

**Animation Specs**:
- Use `flutter_animate` or built-in `AnimatedContainer`/`AnimatedOpacity`
- Standard duration: 200-300ms for micro-interactions
- Easing: `Curves.easeOutCubic` for entries, `Curves.easeInCubic` for exits
- Haptics: `HapticFeedback.mediumImpact()` on successful scan capture

### Spatial Composition (Mobile-Specific)
```dart
// ❌ AVOID: Cramped layouts, tiny touch targets, centered-everything

// ✅ PREFER: Generous spacing, clear visual grouping

// Touch targets: Minimum 48x48dp (Material guideline)
// Card padding: 16-24dp internal, 12-16dp between cards
// Screen margins: 16-24dp horizontal
// Section spacing: 24-32dp between major sections

// Layout patterns for QuizziO:
// - Full-bleed camera preview (scanner screen)
// - Card-based lists (quizzes, graded papers)
// - Bottom sheet for scan results (quick dismiss)
// - FAB for primary action where appropriate
```

### Visual Details & Atmosphere
```dart
// ❌ AVOID: Flat white backgrounds, no depth, generic cards

// ✅ PREFER: Subtle depth, purposeful decoration

// Techniques:
// - Soft shadows on cards (elevation 2-4)
// - Subtle gradient backgrounds (not harsh)
// - Rounded corners: 12-16dp for cards, 8dp for buttons
// - Dividers: Use sparingly, prefer whitespace
// - Icons: Outlined style for consistency, filled for active states
```

---

## 📱 QuizziO-Specific UI Patterns

### Scanner Screen (Critical UX)
```dart
// Alignment Guide States - must be HIGHLY visible
// State 1: Not detected → Red, pulsing animation
// State 2: Detected → Solid green, no pulse
// State 3: All aligned → All green + "Hold steady" text
// State 4: Capturing → Brief flash overlay + haptic

// Corner guide styling:
// - Thick stroke (3-4dp) for visibility
// - Rounded corners on the L-shapes
// - Semi-transparent fill when detected
// - Drop shadow for contrast against any background
```

### Score Display
```dart
// Make scores feel impactful:
// - Large, bold fraction: "18/20"
// - Percentage with color coding
// - Circular progress indicator option
// - Subtle celebration for 100% (confetti? glow?)
```

### Result Cards (Graded Papers List)
```dart
// Each card shows:
// - Name region image (cropped, rounded corners)
// - Score prominent on right
// - Subtle status indicators (edited, low confidence)
// - Swipe actions if needed (delete, re-scan)
```

### Empty States
```dart
// ❌ AVOID: Blank screens, generic "No data" text

// ✅ PREFER: Helpful, encouraging empty states
// - Illustration or icon (simple, on-brand)
// - Clear message: "No quizzes yet"
// - Direct CTA: "Create your first quiz"
```

---

## ⚠️ Anti-Patterns to Avoid

### Generic "AI Slop" in Mobile
- Default Material blue everywhere
- System font with no customization
- Cards with harsh shadows and sharp corners
- Identical spacing throughout (no rhythm)
- Loading spinners with no context
- Generic error messages
- Overuse of icons without labels

### Common Flutter Pitfalls
- Overflow errors from fixed heights (use `Flexible`/`Expanded`)
- Ignoring safe areas (notches, home indicators)
- Text not scaling with system settings
- No loading/error states
- Blocking UI during async operations

---

## ✅ Implementation Checklist

Before marking any screen complete:

- [ ] **Typography**: Custom fonts loaded, hierarchy clear
- [ ] **Colors**: Semantic usage, accessible contrast (4.5:1 minimum)
- [ ] **Spacing**: Consistent rhythm, generous touch targets
- [ ] **States**: Loading, empty, error, success all designed
- [ ] **Motion**: Entry animations, interaction feedback
- [ ] **Accessibility**: Labels for screen readers, sufficient contrast
- [ ] **Dark Mode**: Tested and intentional (if supported)
- [ ] **Edge Cases**: Long text, extreme values, offline state

---

## 💡 Remember

Claude is capable of extraordinary creative work. Each screen in QuizziO should feel:
- **Intentionally designed** for teachers grading quizzes
- **Visually cohesive** with a clear aesthetic point-of-view
- **Functionally robust** with all states handled
- **Memorable** in small details that delight

Don't settle for "it works"—aim for "this feels great to use."