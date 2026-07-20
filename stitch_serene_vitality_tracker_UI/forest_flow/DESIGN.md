---
name: Forest Flow
colors:
  surface: '#0a1611'
  surface-dim: '#0a1611'
  surface-bright: '#2f3c36'
  surface-container-lowest: '#05100c'
  surface-container-low: '#121e19'
  surface-container: '#16221d'
  surface-container-high: '#202d27'
  surface-container-highest: '#2b3732'
  on-surface: '#d8e6dd'
  on-surface-variant: '#e1bfb5'
  inverse-surface: '#d8e6dd'
  inverse-on-surface: '#27332d'
  outline: '#a98a80'
  outline-variant: '#594139'
  surface-tint: '#ffb59d'
  primary: '#ffb59d'
  on-primary: '#5d1900'
  primary-container: '#ff6b35'
  on-primary-container: '#5f1900'
  inverse-primary: '#ab3500'
  secondary: '#b1cdbe'
  on-secondary: '#1d352b'
  secondary-container: '#334c41'
  on-secondary-container: '#a0bbad'
  tertiary: '#b8cbbf'
  on-tertiary: '#23342b'
  tertiary-container: '#8b9e92'
  on-tertiary-container: '#24352c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59d'
  on-primary-fixed: '#390c00'
  on-primary-fixed-variant: '#832600'
  secondary-fixed: '#cde9da'
  secondary-fixed-dim: '#b1cdbe'
  on-secondary-fixed: '#072016'
  on-secondary-fixed-variant: '#334c41'
  tertiary-fixed: '#d4e7da'
  tertiary-fixed-dim: '#b8cbbf'
  on-tertiary-fixed: '#0e1f17'
  on-tertiary-fixed-variant: '#394b41'
  background: '#0a1611'
  on-background: '#d8e6dd'
  surface-variant: '#2b3732'
typography:
  display-lg:
    fontFamily: Playfair Display
    fontSize: 48px
    fontWeight: '900'
    lineHeight: 52px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Playfair Display
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md-mobile:
    fontFamily: Playfair Display
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  stat-lg:
    fontFamily: Playfair Display
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  body-base:
    fontFamily: Epilogue
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-bold:
    fontFamily: Epilogue
    fontSize: 16px
    fontWeight: '700'
    lineHeight: 24px
  label-caps:
    fontFamily: DM Mono
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.15em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base_unit: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  gutter: 16px
  margin-mobile: 16px
  margin-desktop: 32px
---

## Brand & Style

The brand personality is a unique intersection of therapeutic tranquility and high-performance physical capability. It is designed to feel like a "sanctuary for strength," moving away from the aggressive, neon-soaked aesthetics of traditional fitness apps toward a more grounded, premium, and nature-inspired experience.

The design style is **Modern Organic with Glassmorphism**. It combines the deep, structural reliability of a dark "Forest" palette with the ethereal, high-end feel of frosted surfaces. The emotional response should be one of "focused calm"—lowering the heart rate through generous whitespace and soft curves, while sparking motivation through vibrant, high-energy accent colors that mimic the sun breaking through a dense canopy.

**Key Visual Pillars:**
- **Organic Fluidity:** High corner radiuses that mimic river stones and leaf contours.
- **Atmospheric Depth:** Multi-layered glassmorphic surfaces with heavy backdrop blurs to simulate mist and dew.
- **Kinetic Accents:** Strategic use of "Sunset Orange" to guide the eye to primary actions amidst a sea of deep greens.

## Colors

The palette is rooted in the "Forest Night" (`#0D1914`) background, providing a glare-free environment essential for early morning or late-night training.

- **Primary (Sunset Orange):** Used for critical path actions (Start Workout, Save, Complete Set). It represents raw energy.
- **Secondary (Moss Canopy):** Used for structural surfaces and container backgrounds.
- **Tertiary (Soft Sage):** A soothing silver-green used for secondary text and subtle iconography.
- **Neutral (Forest Night):** The deep canvas for the entire application.
- **Glassmorphic Layers:** Use the `surface` glass token with a `12px` to `20px` backdrop blur to create the "Mist" effect. Use the `border` glass token for 1px hairline strokes to define container edges.
- **Functional Accents:** Utilize specific colors for workout categories (Push, Pull, Legs) to provide instant visual categorization without requiring text reading.

## Typography

The typographic system is a sophisticated dialogue between high-class editorial style and technical precision.

- **The Serif (Playfair Display):** Reserved for moments of achievement and primary navigation headers. It provides the "premium" feel. Use `display-lg` for big milestone numbers or hero screen titles.
- **The Sans (Epilogue):** The workhorse for the app. Its geometric clarity ensures readability even when the user is moving or fatigued. Use for all instructions, exercise names, and button labels.
- **The Mono (DM Mono):** Used for high-precision data. All timers, weight logs, rep counts, and macro percentages should use this font to ensure numerical alignment and a technical, biometric feel. 
- **Formatting:** Always use `label-caps` for small metadata tags (e.g., "SET 1", "REST") to distinguish them from interactive body text.

## Layout & Spacing

This design system uses a **Fluid Grid** model with a heavy emphasis on "airy" vertical rhythm to maintain the brand's "Calm" promise.

- **Margins:** Mobile screens must maintain a strict 16px safe area on left and right edges. On desktop/tablet, this expands to 32px.
- **Vertical Spacing:** Use `xl` (32px) spacing between major functional groups (e.g., between the "Active Workout" card and the "Up Next" list). Use `md` (16px) for spacing between items within a list.
- **Grid:** On mobile, a single-column layout is preferred to maintain focus. On tablet/desktop, a 12-column grid is used, with cards typically spanning 6 columns to allow for a dual-column "Dashboard" view (e.g., Workout on left, Nutrition on right).
- **Touch Targets:** All interactive elements must adhere to a minimum 48x48px touch area, even if the visual element (like a small chip) appears smaller.

## Elevation & Depth

Depth is communicated through **Glassmorphism and Tonal Layering** rather than traditional drop shadows.

- **Level 0 (Base):** Forest Night (`#0D1914`). This is the bottom-most layer.
- **Level 1 (Structural):** Moss Canopy (`#162E24`). Used for secondary containers that don't need to "float" but need separation from the base.
- **Level 2 (Floating/Interactive):** Frosted Mist Glass surfaces. These containers use a `20px` backdrop blur. This level is reserved for active session cards and navigation bars.
- **Shadows:** Avoid heavy black shadows. If a shadow is required for extra pop (e.g., on a primary CTA button), use a tinted shadow: `rgba(255, 107, 53, 0.2)` with a `15px` blur.
- **Borders:** Use 1px hairline borders for all glass containers to maintain crispness against the dark background.

## Shapes

The shape language is highly organic. Sharp corners are strictly avoided to maintain the "Soft/Nature" aesthetic.

- **Base Radius:** 0.5rem (8px) for small elements like checkboxes and inner nested items.
- **Large Radius (`rounded-lg`):** 1rem (16px) for standard exercise cards and input fields.
- **Extra Large Radius (`rounded-xl`):** 1.5rem (24px) for primary hero containers and floating action sheets.
- **Pills:** Use full roundedness (9999px) for chips, tags, and the primary "Start" button to emphasize their tactile, pebble-like nature.

## Components

**Buttons:**
- **Primary:** Sunset Orange fill, Forest Night text, bold weight, `rounded-full`.
- **Secondary:** Glassmorphic background (Mist), Soft Sage text, 1px glass border, `rounded-lg`.
- **Icon Buttons:** Circular glass containers with 2px stroke icons.

**Cards:**
- **Session Cards:** Use the Frosted Mist Glass style. Include a 4px left-accent border using the semantic category colors (Push/Pull/Legs).
- **Metric Cards:** Solid Stone Slate background with a large Playfair Display stat centered.

**Inputs:**
- **Numeric Fields:** Forest Night background with a 1px Stone Slate border. On focus, the border glows Sunset Orange and the text (Alpine Snow) increases in prominence.

**Chips/Badges:**
- Use the `label-caps` typography. Backgrounds should be low-opacity versions of the semantic colors (e.g., 10% opacity Push Rose) with a matching solid text color.

**Selection Controls:**
- **Checkboxes:** When completed, the box should fill with Pine Green and "pop" with a slight scale animation (1.1x).
- **Radio Tabs:** Use a glass container with a sliding Sunset Orange pill that moves behind the selected text.

**Progress Indicators:**
- Use organic, non-linear transitions for progress bars. Macro rings should have rounded caps on the progress stroke to match the overall shape language.