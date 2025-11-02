/**
 * Shared UI System - Element Identification & Navigation
 * Matches iOS DevTools annotation system for cross-platform consistency
 *
 * Features:
 * - Element name overlays with click-to-copy
 * - Color-coded component types
 * - Unified navigation across all pages
 * - localStorage persistence
 */

// ============================================================================
// ELEMENT IDENTIFICATION SYSTEM
// ============================================================================

class ElementIdentificationSystem {
    constructor() {
        this.isEnabled = localStorage.getItem('showElementNames') === 'true';
        this.componentTypes = {
            interactive: { color: 'rgba(0, 122, 255, 0.9)', icon: '👆', label: 'Interactive' },
            layout: { color: 'rgba(175, 82, 222, 0.9)', icon: '📐', label: 'Layout' },
            text: { color: 'rgba(52, 199, 89, 0.9)', icon: '📝', label: 'Text' },
            status: { color: 'rgba(255, 149, 0, 0.9)', icon: '🔔', label: 'Status' },
            decoration: { color: 'rgba(142, 142, 147, 0.9)', icon: '🎨', label: 'Decoration' }
        };
        this.overlays = [];
    }

    toggle() {
        this.isEnabled = !this.isEnabled;
        localStorage.setItem('showElementNames', this.isEnabled);

        if (this.isEnabled) {
            this.showAllLabels();
        } else {
            this.hideAllLabels();
        }

        // Update toggle button state
        this.updateToggleButton();

        return this.isEnabled;
    }

    showAllLabels() {
        // Find all elements with data-element-name attribute
        const elements = document.querySelectorAll('[data-element-name]');

        elements.forEach(element => {
            const name = element.getAttribute('data-element-name');
            const type = element.getAttribute('data-element-type') || 'interactive';

            this.createOverlay(element, name, type);
        });
    }

    hideAllLabels() {
        this.overlays.forEach(overlay => overlay.remove());
        this.overlays = [];
    }

    createOverlay(element, name, type) {
        const typeConfig = this.componentTypes[type] || this.componentTypes.interactive;

        // Create overlay container
        const overlay = document.createElement('div');
        overlay.className = 'element-name-overlay';
        overlay.style.cssText = `
            position: absolute;
            z-index: 9999;
            padding: 4px 10px;
            background: ${typeConfig.color};
            color: white;
            font-size: 11px;
            font-weight: 600;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            border-radius: 12px;
            cursor: pointer;
            pointer-events: auto;
            box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
            white-space: nowrap;
            display: flex;
            align-items: center;
            gap: 4px;
            transition: all 0.2s ease;
        `;

        // Add icon and name
        overlay.innerHTML = `
            <span style="font-size: 10px;">${typeConfig.icon}</span>
            <span>${name}</span>
        `;

        // Add click-to-copy functionality
        overlay.addEventListener('click', (e) => {
            e.stopPropagation();
            this.copyToClipboard(name);
            this.showCopyConfirmation(overlay);
        });

        // Hover effect
        overlay.addEventListener('mouseenter', () => {
            overlay.style.transform = 'scale(1.05)';
            overlay.style.boxShadow = '0 4px 12px rgba(0, 0, 0, 0.4)';
        });

        overlay.addEventListener('mouseleave', () => {
            overlay.style.transform = 'scale(1)';
            overlay.style.boxShadow = '0 2px 8px rgba(0, 0, 0, 0.3)';
        });

        // Position overlay above element
        this.positionOverlay(overlay, element);

        document.body.appendChild(overlay);
        this.overlays.push(overlay);

        // Update position on scroll and resize
        const updatePosition = () => this.positionOverlay(overlay, element);
        window.addEventListener('scroll', updatePosition, true);
        window.addEventListener('resize', updatePosition);
    }

    positionOverlay(overlay, element) {
        const rect = element.getBoundingClientRect();
        const overlayRect = overlay.getBoundingClientRect();

        // Position above element, centered
        let left = rect.left + (rect.width / 2) - (overlayRect.width / 2);
        let top = rect.top - overlayRect.height - 8;

        // Keep within viewport
        left = Math.max(8, Math.min(left, window.innerWidth - overlayRect.width - 8));

        // If not enough space above, position below
        if (top < 8) {
            top = rect.bottom + 8;
        }

        overlay.style.left = `${left}px`;
        overlay.style.top = `${top}px`;
    }

    copyToClipboard(text) {
        navigator.clipboard.writeText(text).then(() => {
            console.log('✅ Copied to clipboard:', text);
        }).catch(err => {
            console.error('Failed to copy:', err);
        });
    }

    showCopyConfirmation(overlay) {
        const originalBg = overlay.style.background;
        const originalContent = overlay.innerHTML;

        // Show checkmark
        overlay.innerHTML = `
            <span style="font-size: 12px;">✓</span>
            <span>Copied!</span>
        `;
        overlay.style.background = 'rgba(52, 199, 89, 0.95)';

        // Revert after 1 second
        setTimeout(() => {
            overlay.innerHTML = originalContent;
            overlay.style.background = originalBg;
        }, 1000);
    }

    updateToggleButton() {
        const button = document.getElementById('element-names-toggle');
        if (button) {
            button.textContent = this.isEnabled ? '🏷️ Hide Names' : '🏷️ Show Names';
            button.style.background = this.isEnabled
                ? 'rgba(52, 199, 89, 0.2)'
                : 'rgba(142, 142, 147, 0.1)';
        }
    }

    init() {
        // Auto-show labels if enabled
        if (this.isEnabled) {
            // Wait for DOM to be ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', () => this.showAllLabels());
            } else {
                this.showAllLabels();
            }
        }

        this.updateToggleButton();
    }
}

// Global instance
window.elementIdentification = new ElementIdentificationSystem();

// ============================================================================
// UNIFIED NAVIGATION SYSTEM
// ============================================================================

class NavigationSystem {
    constructor() {
        this.pages = [
            {
                id: 'design-system',
                name: 'Design System',
                href: 'design-system-hub.html',
                badge: null,
                icon: '🎨'
            },
            {
                id: 'action-flows',
                name: 'Action Flows',
                href: 'action-flows-studio.html',
                badge: '46',
                icon: '⚡'
            },
            {
                id: 'classification',
                name: 'Classification',
                href: 'classification-studio.html',
                badge: '89',
                icon: '🎯'
            },
            {
                id: 'registry',
                name: 'Registry',
                href: 'action-registry-explorer.html',
                badge: '75+',
                icon: '📚'
            },
            {
                id: 'live-dashboard',
                name: 'Live Test',
                href: 'live-classification-dashboard.html',
                badge: 'LIVE',
                icon: '🔬'
            }
        ];
    }

    render(currentPageId) {
        return `
            <nav class="unified-nav">
                <div class="nav-container">
                    <!-- Logo / Brand -->
                    <div class="nav-brand">
                        <span class="brand-icon">⚡</span>
                        <span class="brand-text">Zero Docs</span>
                    </div>

                    <!-- Page Links -->
                    <div class="nav-links">
                        ${this.pages.map(page => `
                            <a href="${page.href}"
                               class="nav-link ${page.id === currentPageId ? 'active' : ''}"
                               data-element-name="Nav_${page.name.replace(' ', '')}"
                               data-element-type="interactive">
                                <span class="nav-icon">${page.icon}</span>
                                <span class="nav-label">${page.name}</span>
                                ${page.badge ? `<span class="nav-badge">${page.badge}</span>` : ''}
                            </a>
                        `).join('')}
                    </div>

                    <!-- Search -->
                    <div class="nav-search">
                        <input type="text"
                               id="global-search"
                               placeholder="Search..."
                               data-element-name="Nav_SearchInput"
                               data-element-type="interactive">
                    </div>

                    <!-- Element Names Toggle -->
                    <button id="element-names-toggle"
                            class="nav-toggle"
                            onclick="window.elementIdentification.toggle()">
                        🏷️ Show Names
                    </button>
                </div>
            </nav>

            <style>
                .unified-nav {
                    position: fixed;
                    top: 0;
                    left: 0;
                    right: 0;
                    z-index: 1000;
                    background: rgba(255, 255, 255, 0.05);
                    backdrop-filter: blur(20px);
                    -webkit-backdrop-filter: blur(20px);
                    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
                    padding: 12px 0;
                }

                .nav-container {
                    max-width: 1400px;
                    margin: 0 auto;
                    padding: 0 24px;
                    display: flex;
                    align-items: center;
                    gap: 24px;
                }

                .nav-brand {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    font-weight: 700;
                    font-size: 18px;
                    color: white;
                    flex-shrink: 0;
                }

                .brand-icon {
                    font-size: 24px;
                }

                .nav-links {
                    display: flex;
                    gap: 8px;
                    flex: 1;
                }

                .nav-link {
                    display: flex;
                    align-items: center;
                    gap: 6px;
                    padding: 8px 16px;
                    border-radius: 12px;
                    background: rgba(255, 255, 255, 0.05);
                    color: rgba(255, 255, 255, 0.7);
                    text-decoration: none;
                    font-size: 14px;
                    font-weight: 600;
                    transition: all 0.2s ease;
                    position: relative;
                }

                .nav-link:hover {
                    background: rgba(255, 255, 255, 0.1);
                    color: white;
                    transform: translateY(-1px);
                }

                .nav-link.active {
                    background: rgba(0, 122, 255, 0.2);
                    color: white;
                }

                .nav-icon {
                    font-size: 16px;
                }

                .nav-badge {
                    background: rgba(255, 149, 0, 0.9);
                    color: white;
                    font-size: 10px;
                    font-weight: 700;
                    padding: 2px 6px;
                    border-radius: 8px;
                    min-width: 20px;
                    text-align: center;
                }

                .nav-search {
                    flex-shrink: 0;
                }

                .nav-search input {
                    width: 200px;
                    padding: 8px 12px;
                    border-radius: 8px;
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    background: rgba(255, 255, 255, 0.08);
                    color: white;
                    font-size: 14px;
                    outline: none;
                    transition: all 0.2s ease;
                }

                .nav-search input::placeholder {
                    color: rgba(255, 255, 255, 0.5);
                }

                .nav-search input:focus {
                    border-color: rgba(0, 122, 255, 0.5);
                    background: rgba(255, 255, 255, 0.12);
                    width: 300px;
                }

                .nav-toggle {
                    flex-shrink: 0;
                    padding: 8px 16px;
                    border-radius: 12px;
                    border: none;
                    background: rgba(142, 142, 147, 0.1);
                    color: white;
                    font-size: 14px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.2s ease;
                }

                .nav-toggle:hover {
                    background: rgba(142, 142, 147, 0.2);
                    transform: translateY(-1px);
                }

                /* Mobile responsive */
                @media (max-width: 768px) {
                    .nav-container {
                        flex-wrap: wrap;
                        gap: 12px;
                    }

                    .nav-links {
                        order: 3;
                        width: 100%;
                        overflow-x: auto;
                    }

                    .nav-search input {
                        width: 150px;
                    }

                    .nav-search input:focus {
                        width: 200px;
                    }

                    .nav-label {
                        display: none;
                    }
                }

                /* Add padding to body for fixed nav */
                body {
                    padding-top: 80px;
                }
            </style>
        `;
    }

    init(currentPageId) {
        // Inject navigation at start of body
        const nav = document.createElement('div');
        nav.innerHTML = this.render(currentPageId);
        document.body.insertBefore(nav, document.body.firstChild);

        // Setup search functionality
        this.setupSearch();
    }

    setupSearch() {
        const searchInput = document.getElementById('global-search');
        if (!searchInput) return;

        searchInput.addEventListener('input', (e) => {
            const query = e.target.value.toLowerCase().trim();

            if (query.length < 2) {
                this.clearSearchHighlights();
                return;
            }

            this.performSearch(query);
        });
    }

    performSearch(query) {
        // Search through all text content on page
        const elements = document.querySelectorAll('[data-element-name], h1, h2, h3, p, span, div');

        elements.forEach(el => {
            const text = el.textContent.toLowerCase();
            const elementName = el.getAttribute('data-element-name')?.toLowerCase() || '';

            if (text.includes(query) || elementName.includes(query)) {
                el.style.outline = '2px solid rgba(255, 149, 0, 0.6)';
                el.style.outlineOffset = '2px';
            } else {
                el.style.outline = '';
                el.style.outlineOffset = '';
            }
        });
    }

    clearSearchHighlights() {
        const elements = document.querySelectorAll('[style*="outline"]');
        elements.forEach(el => {
            el.style.outline = '';
            el.style.outlineOffset = '';
        });
    }
}

// Global instance
window.navigation = new NavigationSystem();

// ============================================================================
// INITIALIZATION
// ============================================================================

// Auto-initialize on page load
document.addEventListener('DOMContentLoaded', () => {
    // Initialize element identification system
    window.elementIdentification.init();

    console.log('✅ Shared UI System initialized');
    console.log('📋 Element identification:', window.elementIdentification.isEnabled ? 'ON' : 'OFF');
});

// Export for module usage
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        ElementIdentificationSystem,
        NavigationSystem
    };
}
