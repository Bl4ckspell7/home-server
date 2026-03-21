// Sync Homepage's theme toggle with system color scheme
// Homepage stores theme in localStorage under "theme-mode"
function syncTheme() {
    const theme = window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
    localStorage.setItem('theme-mode', theme);
}

syncTheme();
window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    syncTheme();
    location.reload();
});