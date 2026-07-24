(function () {
  const SHORTS_RE = /\/shorts\/([\w-]{11})/i;

  function videoIdFromLocation() {
    const fromPath = window.location.pathname.match(SHORTS_RE);
    if (fromPath) return fromPath[1];
    return null;
  }

  function redirectToApp(videoId) {
    if (!videoId) return;
    const key = `ytsk-redirected-${videoId}`;
    if (sessionStorage.getItem(key)) return;
    sessionStorage.setItem(key, "1");
    window.location.href = `ytsk://short/${videoId}`;
  }

  function check() {
    redirectToApp(videoIdFromLocation());
  }

  check();

  let lastHref = location.href;
  const observer = new MutationObserver(() => {
    if (location.href !== lastHref) {
      lastHref = location.href;
      check();
    }
  });
  observer.observe(document.documentElement, { childList: true, subtree: true });

  window.addEventListener("yt-navigate-finish", check);
  window.addEventListener("popstate", check);
})();
