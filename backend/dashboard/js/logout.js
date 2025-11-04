/**
 * Logout Functionality
 * Reusable logout component for all dashboard pages
 */

// Create and inject logout button
function createLogoutButton() {
  const button = document.createElement('button');
  button.id = 'logoutButton';
  button.innerHTML = '🚪 Logout';
  button.style.cssText = `
    position: fixed;
    top: 20px;
    right: 20px;
    padding: 10px 20px;
    background: rgba(239, 68, 68, 0.8);
    color: white;
    border: 1px solid rgba(255, 255, 255, 0.3);
    border-radius: 8px;
    cursor: pointer;
    font-size: 14px;
    font-weight: 600;
    z-index: 10000;
    backdrop-filter: blur(10px);
    transition: all 0.3s ease;
  `;

  button.addEventListener('mouseover', () => {
    button.style.background = 'rgba(239, 68, 68, 1)';
    button.style.transform = 'translateY(-2px)';
    button.style.boxShadow = '0 4px 12px rgba(239, 68, 68, 0.4)';
  });

  button.addEventListener('mouseout', () => {
    button.style.background = 'rgba(239, 68, 68, 0.8)';
    button.style.transform = 'translateY(0)';
    button.style.boxShadow = 'none';
  });

  button.addEventListener('click', logout);

  document.body.appendChild(button);
}

// Logout function
async function logout() {
  try {
    const button = document.getElementById('logoutButton');
    if (button) {
      button.textContent = '⏳ Logging out...';
      button.disabled = true;
    }

    const response = await fetch('/auth/logout', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      }
    });

    const result = await response.json();

    if (result.success) {
      // Redirect to splash page
      window.location.href = '/splash.html';
    } else {
      alert('Logout failed. Please try again.');
      if (button) {
        button.textContent = '🚪 Logout';
        button.disabled = false;
      }
    }
  } catch (error) {
    console.error('Logout error:', error);
    alert('Connection error. Please refresh the page.');
  }
}

// Initialize on page load
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', createLogoutButton);
} else {
  createLogoutButton();
}
