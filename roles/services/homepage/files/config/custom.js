// https://github.com/gethomepage/homepage/discussions/1892#discussioncomment-10132072

// Function to update theme class on #page_wrapper
function updateTheme() {
    const wrapper = document.getElementById('page_wrapper');
    if (!wrapper) return;

    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
        wrapper.className = 'relative dark scheme-dark theme-neutral';
    } else {
        wrapper.className = 'relative light scheme-light theme-neutral';
    }
}

// Update theme on page load
updateTheme();

// Listen to system color scheme changes
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateTheme);
