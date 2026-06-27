---
name: Kinetic Material
colors:
  surface: '#f9f9fc'
  surface-dim: '#dadadc'
  surface-bright: '#f9f9fc'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f3f6'
  surface-container: '#eeeef0'
  surface-container-high: '#e8e8ea'
  surface-container-highest: '#e2e2e5'
  on-surface: '#1a1c1e'
  on-surface-variant: '#454652'
  inverse-surface: '#2f3133'
  inverse-on-surface: '#f0f0f3'
  outline: '#757684'
  outline-variant: '#c5c5d4'
  surface-tint: '#4355b9'
  primary: '#24389c'
  on-primary: '#ffffff'
  primary-container: '#3f51b5'
  on-primary-container: '#cacfff'
  inverse-primary: '#bac3ff'
  secondary: '#006a60'
  on-secondary: '#ffffff'
  secondary-container: '#85f6e5'
  on-secondary-container: '#007166'
  tertiary: '#5c3b2f'
  on-tertiary: '#ffffff'
  tertiary-container: '#765245'
  on-tertiary-container: '#f8c8b7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dee0ff'
  primary-fixed-dim: '#bac3ff'
  on-primary-fixed: '#00105c'
  on-primary-fixed-variant: '#293ca0'
  secondary-fixed: '#85f6e5'
  secondary-fixed-dim: '#67d9c9'
  on-secondary-fixed: '#00201c'
  on-secondary-fixed-variant: '#005048'
  tertiary-fixed: '#ffdbcf'
  tertiary-fixed-dim: '#ebbcac'
  on-tertiary-fixed: '#2e150b'
  on-tertiary-fixed-variant: '#603f33'
  background: '#f9f9fc'
  on-background: '#1a1c1e'
  surface-variant: '#e2e2e5'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 57px
    fontWeight: '400'
    lineHeight: 64px
    letterSpacing: -0.25px
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-sm:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  title-lg:
    fontFamily: Hanken Grotesk
    fontSize: 22px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0.15px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0.5px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.25px
  label-lg:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: 0.1px
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  container-padding: 20px
  gutter: 16px
---

## Brand & Style

This design system is a refined interpretation of Material 3 principles tailored for the fitness and health sector. The brand personality is disciplined yet encouraging, professional yet accessible. It prioritizes clarity and high-signal data visualization to help users track progress without cognitive overwhelm.

The design style is **Minimalist / Corporate Modern**. It leverages heavy whitespace and a restricted color palette to create a "breathable" interface. While it follows Material 3's structural logic, it leans into a softer, more premium aesthetic through exaggerated roundedness and subtle, purposeful elevations that guide the eye toward actionable health insights.

## Colors

The palette is designed for high legibility and a sense of calm.

- **Primary (Indigo):** Used for key actions, progress indicators, and active states. It provides a stable, trustworthy foundation.
- **Secondary (Teal):** Reserved for "health-positive" markers, success states, and secondary data visualizations (e.g., heart rate or completed goals).
- **Surface & Background:** The background uses a slightly tinted cool white (`#F8F9FF`) to reduce eye strain and distinguish the canvas from pure white card elements.
- **On-Surface:** A deep, near-black charcoal (`#1A1C1E`) ensures optimal contrast for text and iconography.

## Typography

The design system utilizes **Hanken Grotesk** for its precise, contemporary feel that bridges the gap between technical data and human-centric design.

- **Headlines:** Use semi-bold weights for clear section hierarchy.
- **Data Points:** Large metrics (e.g., daily steps) should use `display-lg` or `headline-lg` to create focal points.
- **Body:** Standardized at 16px for primary reading and 14px for secondary descriptions to maintain accessibility.
- **Labels:** Used for buttons and small metadata, emphasizing all-caps only for specific utility labels like "NEW" or "LIVE".

## Layout & Spacing

This design system uses a **fluid grid** optimized for mobile viewports.

- **Grid System:** A 4-column grid for mobile with 16px gutters.
- **Margins:** 20px safe-area margins on the horizontal axis for all main content containers.
- **Rhythm:** An 8px linear scale (4px, 8px, 16px, 24px, 32px) governs all padding and margins. 
- **Vertical Spacing:** Use `lg` (24px) spacing between distinct cards/sections to emphasize the minimalist, airy aesthetic.

## Elevation & Depth

Hierarchy is established through **Tonal Layers** and **Ambient Shadows**.

- **Level 0 (Background):** `#F8F9FF` — The base layer.
- **Level 1 (Cards/Surfaces):** Pure White `#FFFFFF`. These elements use a subtle, highly diffused shadow (Blur: 12px, Y: 4px, Opacity: 4%, Color: `#1A1C1E`) to appear slightly lifted.
- **Level 2 (Active/Floating):** Use a more pronounced shadow for Floating Action Buttons (FAB) and active modals to denote immediate interactability.
- **Dividers:** Avoid heavy lines. Use 1px borders in a 5% opacity version of the On-Surface color or simply rely on whitespace and tonal shifts between the background and cards.

## Shapes

The shape language is purposefully **Rounded** to evoke a friendly and approachable health experience.

- **Standard Elements:** Buttons and small input fields use a `0.5rem` (8px) radius.
- **Containers & Cards:** Dashboard cards and modal sheets use a large `1.5rem` (24px) radius to create the "soft-modern" look.
- **Progress Bars:** Use fully rounded (pill-shaped) caps for all health tracking bars and sliders.

## Components

- **Buttons:** Primary buttons are filled with the Primary color, utilizing the 8px radius. Secondary buttons should be outlined with a 1.5px stroke.
- **Cards:** White background, 24px corner radius, and subtle Level 1 shadows. Content within cards should have 20px internal padding.
- **Icons:** Use **Thin-line (Light)** Material style icons. Strokes should be consistent (1px to 1.5px) to maintain the airy feel.
- **Chips:** Used for filter categories (e.g., "Weight Loss", "Cardio"). These use a pill shape and a light Primary-tonal container when active.
- **Inputs:** Outlined style with a 1px stroke. When focused, the stroke weight increases to 2px in the Primary color.
- **Progress Indicators:** Circular progress for daily goals should use a thick stroke (8px-12px) with rounded ends to match the overall shape language.
- **Bottom Navigation:** Uses the Surface color with a subtle Level 1 shadow and no top border. Active states are indicated by the Primary color and a pill-shaped indicator behind the icon.