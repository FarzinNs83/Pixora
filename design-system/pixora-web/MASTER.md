# Design System Master File

> **LOGIC:** When building a specific page, first check `design-system/pages/[page-name].md`.
> If that file exists, its rules **override** this Master file.
> If not, strictly follow the rules below.

---

**Project:** Pixora Web
**Generated:** 2026-09-15 10:59:09
**Category:** Productivity Tool
**Design Dials:** Variance 6/10 (Balanced / Modern) | Motion 4/10 (Restrained) | Density 5/10 (Standard)

---

## Global Rules

### Color Palette

| Role | Hex | CSS Variable |
|------|-----|--------------|
| Primary | `#5454C7` | `--color-primary` |
| On Primary | `#FFFFFF` | `--color-on-primary` |
| Secondary | `#EEEEFF` | `--color-secondary` |
| Accent/CTA | `#4F4FBD` | `--color-accent` |
| Background | `#F6F6F8` | `--color-background` |
| Foreground | `#202027` | `--color-foreground` |
| Muted | `#F3F3F6` | `--color-muted` |
| Border | `#DEDEE5` | `--color-border` |
| Destructive | `#DC2626` | `--color-destructive` |
| Ring | `#5454C7` | `--color-ring` |

**Color Notes:** Cool neutral surfaces with one restrained cobalt accent. Semantic colors are reserved for real state.

### Typography

- **Heading Font:** Segoe UI Variable / system sans
- **Body Font:** Segoe UI Variable / system sans
- **Mood:** flat, clean, system, bold, geometric, cross-platform, icon, poster, minimal, functional, responsive
- **Font loading:** Local system fonts only. No runtime network request.

**CSS:** use the local system font stack with `font-display: swap`; do not request fonts at runtime.

### Spacing Variables

*Density: 5/10 — Standard*

| Token | Value | Usage |
|-------|-------|-------|
| `--space-xs` | `4px` / `0.25rem` | Tight gaps |
| `--space-sm` | `8px` / `0.5rem` | Icon gaps, inline spacing |
| `--space-md` | `16px` / `1rem` | Standard padding |
| `--space-lg` | `24px` / `1.5rem` | Section padding |
| `--space-xl` | `32px` / `2rem` | Large gaps |
| `--space-2xl` | `48px` / `3rem` | Section margins |
| `--space-3xl` | `64px` / `4rem` | Hero padding |

### Shadow Depths

| Level | Value | Usage |
|-------|-------|-------|
| `--shadow-sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle lift |
| `--shadow-md` | `0 4px 6px rgba(0,0,0,0.1)` | Cards, buttons |
| `--shadow-lg` | `0 10px 15px rgba(0,0,0,0.1)` | Modals, dropdowns |
| `--shadow-xl` | `0 20px 25px rgba(0,0,0,0.15)` | Hero images, featured cards |

---

## Component Specs

### Buttons

```css
/* Primary Button */
.btn-primary {
  background: #4F4FBD;
  color: white;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}

.btn-primary:hover {
  opacity: 0.9;
  transform: translateY(-1px);
}

/* Secondary Button */
.btn-secondary {
  background: transparent;
  color: #4F4FBD;
  border: 2px solid #4F4FBD;
  padding: 12px 24px;
  border-radius: 8px;
  font-weight: 600;
  transition: all 200ms ease;
  cursor: pointer;
}
```

### Cards

```css
.card {
  background: #FFFFFF;
  border-radius: 12px;
  padding: 24px;
  box-shadow: var(--shadow-md);
  transition: all 200ms ease;
  cursor: pointer;
}

.card:hover {
  box-shadow: var(--shadow-lg);
  transform: translateY(-2px);
}
```

### Inputs

```css
.input {
  padding: 12px 16px;
  border: 1px solid #E2E8F0;
  border-radius: 8px;
  font-size: 16px;
  transition: border-color 200ms ease;
}

.input:focus {
  border-color: #5454C7;
  outline: none;
  box-shadow: 0 0 0 3px #5454C733;
}
```

### Modals

```css
.modal-overlay {
  background: rgba(0, 0, 0, 0.5);
  backdrop-filter: blur(4px);
}

.modal {
  background: white;
  border-radius: 16px;
  padding: 32px;
  box-shadow: var(--shadow-xl);
  max-width: 500px;
  width: 90%;
}
```

---

## Style Guidelines

**Style:** Micro-interactions

**Keywords:** Small animations, gesture-based, tactile feedback, subtle animations, contextual interactions, responsive

**Best For:** Mobile apps, touchscreen UIs, productivity tools, user-friendly, consumer apps, interactive components

**Key Effects:** Small hover (50-100ms), loading spinners, success/error state anim, gesture-triggered (swipe/pinch), haptic

### Page Pattern

**Pattern Name:** Responsive tool workspace

- **Layout Strategy:** Persistent tool navigation, concise page header and one primary work surface.
- **Action Placement:** Primary action stays beside its settings and exposes loading, success and error states.
- **Responsive order:** compact rail below 900px, bottom navigation below 620px, single-column tool controls.

---

## Motion

**Stagger List** (Restrained) - Trigger: page or tool change | Duration: 180-280ms | Easing: ease-out

Use `motion/react` for opacity and small translate transitions. Never animate dimensions.

**Framework notes:** use `useReducedMotion()` and disable entry transforms when requested by the user.

- Keep motion tied to navigation, loading, success and error feedback.
- Avoid decorative loops and overshoot easing in tool workspaces.

---

## Anti-Patterns (Do NOT Use)

- ❌ Complex onboarding
- ❌ Slow performance

### Additional Forbidden Patterns

- ❌ **Emojis as icons** — Use SVG icons (Heroicons, Lucide, Simple Icons)
- ❌ **Missing cursor:pointer** — All clickable elements must have cursor:pointer
- ❌ **Layout-shifting hovers** — Avoid scale transforms that shift layout
- ❌ **Low contrast text** — Maintain 4.5:1 minimum contrast ratio
- ❌ **Instant state changes** — Always use transitions (150-300ms)
- ❌ **Invisible focus states** — Focus states must be visible for a11y

---

## Pre-Delivery Checklist

Before delivering any UI code, verify:

- [ ] No emojis used as icons (use SVG instead)
- [ ] All icons from consistent icon set (Heroicons/Lucide)
- [ ] `cursor-pointer` on all clickable elements
- [ ] Hover states with smooth transitions (150-300ms)
- [ ] Light mode: text contrast 4.5:1 minimum
- [ ] Focus states visible for keyboard navigation
- [ ] `prefers-reduced-motion` respected
- [ ] Responsive: 375px, 768px, 1024px, 1440px
- [ ] No content hidden behind fixed navbars
- [ ] No horizontal scroll on mobile
