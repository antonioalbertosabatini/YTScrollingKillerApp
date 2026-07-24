const SHORTS_RE = /(?:youtube\.com|youtu\.be)\/shorts\/([\w-]{11})/i;

browser.tabs.onUpdated.addListener((tabId, changeInfo, tab) => {
  if (!changeInfo.url) return;
  const match = changeInfo.url.match(SHORTS_RE);
  if (!match) return;
  const videoId = match[1];
  browser.tabs.update(tabId, { url: `ytsk://short/${videoId}` }).catch(() => {
    // Fallback: content script will try location assign.
  });
});
