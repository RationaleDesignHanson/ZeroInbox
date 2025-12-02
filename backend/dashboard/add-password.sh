#!/bin/bash

PASSWORD_SCRIPT='
    <!-- Password Protection -->
    <script>
        (function() {
            const CORRECT_PASSWORD = '"'"'ZERO2025'"'"';
            const isAuthenticated = sessionStorage.getItem('"'"'dashboardAuth'"'"') === '"'"'true'"'"';

            if (!isAuthenticated) {
                document.addEventListener('"'"'DOMContentLoaded'"'"', function() {
                    document.body.style.display = '"'"'none'"'"';
                    const gate = document.createElement('"'"'div'"'"');
                    gate.id = '"'"'password-gate'"'"';
                    gate.innerHTML = `
                        <style>
                            #password-gate {
                                position: fixed;
                                inset: 0;
                                background: linear-gradient(135deg, #1a1a2e 0%, #2d1b4e 30%, #4a1942 60%, #1f1f3a 100%);
                                display: flex;
                                align-items: center;
                                justify-center;
                                z-index: 99999;
                                font-family: -apple-system, BlinkMacSystemFont, '"'"'Segoe UI'"'"', Roboto, sans-serif;
                            }
                            #password-gate .gate-container {
                                background: rgba(255, 255, 255, 0.1);
                                backdrop-filter: blur(10px);
                                border: 1px solid rgba(255, 255, 255, 0.2);
                                border-radius: 24px;
                                padding: 48px;
                                max-width: 400px;
                                width: 90%;
                                text-align: center;
                            }
                            #password-gate h2 {
                                color: white;
                                font-size: 32px;
                                margin-bottom: 12px;
                                background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
                                -webkit-background-clip: text;
                                -webkit-text-fill-color: transparent;
                            }
                            #password-gate p {
                                color: rgba(255, 255, 255, 0.7);
                                margin-bottom: 32px;
                                font-size: 14px;
                            }
                            #password-gate input {
                                width: 100%;
                                padding: 16px;
                                background: rgba(255, 255, 255, 0.1);
                                border: 1px solid rgba(255, 255, 255, 0.2);
                                border-radius: 12px;
                                color: white;
                                font-size: 16px;
                                margin-bottom: 16px;
                                text-align: center;
                            }
                            #password-gate input::placeholder {
                                color: rgba(255, 255, 255, 0.4);
                            }
                            #password-gate input:focus {
                                outline: none;
                                border-color: #667eea;
                                background: rgba(255, 255, 255, 0.15);
                            }
                            #password-gate button {
                                width: 100%;
                                padding: 16px;
                                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                                border: none;
                                border-radius: 12px;
                                color: white;
                                font-size: 16px;
                                font-weight: 600;
                                cursor: pointer;
                                transition: transform 0.2s, box-shadow 0.2s;
                            }
                            #password-gate button:hover {
                                transform: translateY(-2px);
                                box-shadow: 0 8px 24px rgba(102, 126, 234, 0.4);
                            }
                            #password-gate .error {
                                color: #ff3b30;
                                font-size: 14px;
                                margin-top: 12px;
                                display: none;
                            }
                            #password-gate .hint {
                                color: rgba(255, 255, 255, 0.5);
                                font-size: 12px;
                                margin-top: 24px;
                            }
                        </style>
                        <div class="gate-container">
                            <h2>🔒 Beta Testers Only</h2>
                            <p>Enter the password from your TestFlight instructions</p>
                            <input type="password" id="password-input" placeholder="Enter password" />
                            <button onclick="checkPassword()">Access Dashboard</button>
                            <div class="error" id="error-message">Incorrect password</div>
                            <div class="hint">Find the password in your TestFlight welcome email</div>
                        </div>
                    `;
                    document.body.appendChild(gate);
                    document.body.style.display = '"'"'block'"'"';

                    window.checkPassword = function() {
                        const input = document.getElementById('"'"'password-input'"'"');
                        const error = document.getElementById('"'"'error-message'"'"');
                        if (input.value === CORRECT_PASSWORD) {
                            sessionStorage.setItem('"'"'dashboardAuth'"'"', '"'"'true'"'"');
                            document.getElementById('"'"'password-gate'"'"').remove();
                            document.body.style.display = '"'"'block'"'"';
                            location.reload();
                        } else {
                            error.style.display = '"'"'block'"'"';
                            input.value = '"'"''"'"';
                            input.focus();
                        }
                    };
                    document.getElementById('"'"'password-input'"'"').addEventListener('"'"'keypress'"'"', function(e) {
                        if (e.key === '"'"'Enter'"'"') {
                            checkPassword();
                        }
                    });
                    document.getElementById('"'"'password-input'"'"').focus();
                });
            }
        })();
    </script>
'

# Add password protection to files that don't have it yet
for file in analytics-dashboard.html intent-action-explorer.html action-modal-explorer.html; do
    if [ -f "$file" ] && ! grep -q "ZERO2025" "$file"; then
        echo "Adding password protection to $file..."
        # Insert after <title> tag
        sed -i.backup '/<\/title>/a\
'"$PASSWORD_SCRIPT" "$file"
        echo "✓ Done: $file"
    fi
done

echo "Password protection added!"
