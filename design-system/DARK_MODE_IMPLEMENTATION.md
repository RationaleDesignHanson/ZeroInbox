# Dark Mode Implementation Plan

**Status**: Design Phase
**Target**: v2.1.0
**Complexity**: Medium
**Estimated Effort**: 2-3 weeks

---

## Overview

Add comprehensive dark mode support to Zero Inbox with adaptive color tokens that respond to system appearance.

**Current State:**
- ✅ Design system with semantic tokens
- ❌ No dark mode color scheme
- ❌ No adaptive color tokens

**Target State:**
- ✅ Adaptive color tokens (light + dark)
- ✅ SwiftUI environment-aware colors
- ✅ Smooth appearance transitions
- ✅ User preference override

---

## Architecture

### Token Structure

```json
{
  "colors": {
    "background": {
      "primary": {
        "$type": "color",
        "$value": {
          "light": "#000000",
          "dark": "#FFFFFF"
        },
        "$description": "Main background color - adapts to appearance"
      },
      "secondary": {
        "$type": "color",
        "$value": {
          "light": "#1A1A1A",
          "dark": "#F5F5F5"
        }
      }
    },
    "text": {
      "primary": {
        "$type": "color",
        "$value": {
          "light": "#FFFFFF",
          "dark": "#000000"
        }
      },
      "secondary": {
        "$type": "color",
        "$value": {
          "light": "rgba(255, 255, 255, 0.9)",
          "dark": "rgba(0, 0, 0, 0.9)"
        }
      }
    }
  }
}
```

### Swift Implementation

```swift
enum DesignTokens {
    enum Colors {
        // Adaptive colors that respond to @Environment(\.colorScheme)
        static let backgroundPrimary = Color("BackgroundPrimary", bundle: .main)
        static let textPrimary = Color("TextPrimary", bundle: .main)

        // Or programmatic approach:
        static func backgroundPrimary(for colorScheme: ColorScheme) -> Color {
            switch colorScheme {
            case .light: return Color.black
            case .dark: return Color.white
            @unknown default: return Color.black
            }
        }
    }
}
```

---

## Phase 1: Color Asset Catalog (Recommended)

### Why Asset Catalog?

✅ **Pros:**
- Native SwiftUI support
- Automatic appearance handling
- Interface Builder integration
- No boilerplate code
- Xcode color picker

❌ **Cons:**
- Not programmatically generated
- Separate from tokens.json
- Requires manual sync

### Implementation

**1. Create Asset Catalog**

```bash
# Location
Zero_ios_2/Zero/Resources/Colors.xcassets/

# Structure
Colors.xcassets/
├── BackgroundPrimary.colorset/
│   └── Contents.json
├── TextPrimary.colorset/
│   └── Contents.json
└── ... (all adaptive colors)
```

**2. Contents.json Format**

```json
{
  "colors": [
    {
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "0.000",
          "green": "0.000",
          "blue": "0.000",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    },
    {
      "appearances": [
        {
          "appearance": "luminosity",
          "value": "dark"
        }
      ],
      "color": {
        "color-space": "srgb",
        "components": {
          "red": "1.000",
          "green": "1.000",
          "blue": "1.000",
          "alpha": "1.000"
        }
      },
      "idiom": "universal"
    }
  ],
  "info": {
    "author": "xcode",
    "version": 1
  }
}
```

**3. Usage in SwiftUI**

```swift
// Automatic appearance handling
Text("Hello")
    .foregroundColor(Color("TextPrimary"))
    .background(Color("BackgroundPrimary"))

// Or with DesignTokens wrapper
Text("Hello")
    .foregroundColor(DesignTokens.Colors.textPrimary)
```

---

## Phase 2: Programmatic Approach (Alternative)

### Environment-Based Colors

```swift
struct AdaptiveColor {
    let light: Color
    let dark: Color

    func color(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? dark : light
    }
}

enum DesignTokens {
    enum Colors {
        static let backgroundPrimary = AdaptiveColor(
            light: .black,
            dark: .white
        )

        static let textPrimary = AdaptiveColor(
            light: .white,
            dark: .black
        )
    }
}

// Usage with environment
struct MyView: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        Text("Hello")
            .foregroundColor(DesignTokens.Colors.textPrimary.color(for: colorScheme))
    }
}
```

### ViewModifier Extension

```swift
extension View {
    func adaptiveColor(_ adaptiveColor: AdaptiveColor) -> some View {
        modifier(AdaptiveColorModifier(adaptiveColor: adaptiveColor))
    }
}

struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let adaptiveColor: AdaptiveColor

    func body(content: Content) -> some View {
        content.foregroundColor(adaptiveColor.color(for: colorScheme))
    }
}

// Usage
Text("Hello")
    .adaptiveColor(DesignTokens.Colors.textPrimary)
```

---

## Color Token Mapping

### Light Mode (Current)

| Token | Value | Usage |
|-------|-------|-------|
| `background.primary` | `#000000` | Main background |
| `background.secondary` | `#1A1A1A` | Card backgrounds |
| `text.primary` | `#FFFFFF` | Primary text |
| `text.secondary` | `rgba(255,255,255,0.9)` | Secondary text |
| `text.tertiary` | `rgba(255,255,255,0.8)` | Tertiary text |
| `border.primary` | `rgba(255,255,255,0.2)` | Primary borders |

### Dark Mode (Proposed)

| Token | Value | Usage |
|-------|-------|-------|
| `background.primary` | `#FFFFFF` | Main background |
| `background.secondary` | `#F5F5F5` | Card backgrounds |
| `text.primary` | `#000000` | Primary text |
| `text.secondary` | `rgba(0,0,0,0.9)` | Secondary text |
| `text.tertiary` | `rgba(0,0,0,0.8)` | Tertiary text |
| `border.primary` | `rgba(0,0,0,0.2)` | Primary borders |

### Gradients (Special Handling)

Gradients should remain consistent across modes:

```swift
// Mail gradient - same in light/dark
static let mailGradient = LinearGradient(
    colors: [
        Color(red: 0.40, green: 0.49, blue: 0.92),  // #667eea
        Color(red: 0.46, green: 0.29, blue: 0.64)   // #764ba2
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## Migration Strategy

### Step 1: Audit Current Colors

```bash
# Find all hardcoded colors
grep -r "Color\\.black\|Color\\.white\|#[0-9A-F]{6}" Zero_ios_2/Zero/Views/

# Find color literals
grep -r "Color(red:\|Color(hex:" Zero_ios_2/Zero/Views/
```

### Step 2: Create Asset Catalog

```bash
# Create color sets for adaptive colors
mkdir -p Zero_ios_2/Zero/Resources/Colors.xcassets/

# Generate Contents.json for each color
node design-system/scripts/generate-color-assets.js
```

### Step 3: Update DesignTokens.swift

```swift
// Add adaptive color references
enum Colors {
    // Asset catalog colors (recommended)
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let textPrimary = Color("TextPrimary")

    // Gradients (not adaptive)
    static let mailGradientStart = Color(red: 0.40, green: 0.49, blue: 0.92)
    static let mailGradientEnd = Color(red: 0.46, green: 0.29, blue: 0.64)
}
```

### Step 4: Refactor Views

```swift
// Before
Text("Hello")
    .foregroundColor(.white)
    .background(.black)

// After
Text("Hello")
    .foregroundColor(DesignTokens.Colors.textPrimary)
    .background(DesignTokens.Colors.backgroundPrimary)
```

### Step 5: Test Both Modes

```swift
// Preview with both appearances
struct MyView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MyView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            MyView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
```

---

## User Preference

### Settings UI

```swift
enum AppearanceMode: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
}

struct AppearanceSettings: View {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system

    var body: some View {
        List {
            Section("Appearance") {
                Picker("Theme", selection: $appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
        }
    }
}
```

### App-Level Override

```swift
@main
struct ZeroApp: App {
    @AppStorage("appearanceMode") private var appearanceMode = AppearanceMode.system

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

---

## Testing Strategy

### Manual Testing

- [ ] Test all views in light mode
- [ ] Test all views in dark mode
- [ ] Test dynamic appearance switching
- [ ] Test on different devices (iPhone, iPad)
- [ ] Test with accessibility settings (high contrast)

### Automated Testing

```swift
func testAppearance() {
    let view = MyView()

    // Test light mode
    let lightView = view.environment(\.colorScheme, .light)
    assertSnapshot(matching: lightView, as: .image)

    // Test dark mode
    let darkView = view.environment(\.colorScheme, .dark)
    assertSnapshot(matching: darkView, as: .image)
}
```

---

## Gradual Rollout

### Phase 1: Core Components (Week 1)
- [ ] Background colors
- [ ] Text colors
- [ ] Border colors
- [ ] Button colors

### Phase 2: Complex Components (Week 2)
- [ ] Card backgrounds
- [ ] Modal overlays
- [ ] Navigation bars
- [ ] Bottom sheets

### Phase 3: Polish (Week 3)
- [ ] Shadow adjustments
- [ ] Gradient refinements
- [ ] Accessibility improvements
- [ ] User preference UI

---

## Edge Cases

### Gradients on Different Backgrounds

```swift
// Ensure gradients are visible on both backgrounds
static let mailGradient: some View {
    LinearGradient(...)
        .overlay(
            // Subtle overlay to ensure visibility
            Color.black.opacity(colorScheme == .dark ? 0.1 : 0)
        )
}
```

### Images and Icons

```swift
// SF Symbols automatically adapt
Image(systemName: "heart")
    .foregroundColor(DesignTokens.Colors.textPrimary)

// Custom images need template rendering
Image("custom-icon")
    .renderingMode(.template)
    .foregroundColor(DesignTokens.Colors.textPrimary)
```

### Shadows

```swift
// Adjust shadow opacity for dark mode
.shadow(
    color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.4),
    radius: 20,
    y: 10
)
```

---

## Documentation Updates

After implementation:

1. Update DESIGN_SYSTEM_STATUS.md with dark mode support
2. Add dark mode screenshots to README
3. Document color token usage guidelines
4. Create Figma dark mode page
5. Update component library with both modes

---

## Success Metrics

- [ ] 100% of views support dark mode
- [ ] No hardcoded `.black` or `.white` colors in Views/
- [ ] Smooth appearance transitions
- [ ] No color contrast violations (WCAG AA)
- [ ] User preference persists across app launches

---

## References

- Apple HIG: [Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
- SwiftUI: [ColorScheme](https://developer.apple.com/documentation/swiftui/colorscheme)
- Asset Catalogs: [Color Set](https://developer.apple.com/documentation/xcode/specifying-custom-colors)
- Current tokens: `design-system/tokens.json`
- DesignTokens.swift: `Zero_ios_2/Zero/Config/DesignTokens.swift`
