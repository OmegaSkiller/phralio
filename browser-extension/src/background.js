import { Store } from "./store.js";
const api = globalThis.browser || globalThis.chrome;
const store = new Store(api.storage.local);
const reader = api.runtime.getURL("reader.html");
async function openReader(query) {
  await api.tabs.create({ url: reader + query });
}
api.action.onClicked.addListener(async (tab) => {
  try {
    if (tab.incognito) throw Error("privatePage");
    if (!/^https?:\/\//.test(tab.url || "")) throw Error("restrictedPage");
    const results = await api.scripting.executeScript({
      target: { tabId: tab.id },
      files: ["capture.js"],
    });
    const value = results[0]?.result;
    if (!value?.reading) throw Error(value?.error || "emptyPage");
    const id = await store.handle({ type: "add", reading: value.reading });
    await openReader("?id=" + id + "&play=1");
  } catch (error) {
    const known = [
      "privatePage",
      "restrictedPage",
      "emptyPage",
      "pasteInvalid",
      "pageTooLarge",
    ];
    await openReader(
      "?error=" +
        (known.includes(error.message) ? error.message : "captureFailed"),
    );
  }
});
// Only our top-level reader can request privileged operations. Content scripts
// do not have a message bridge and there is no externally_connectable surface.
api.runtime.onMessage.addListener((message, sender, reply) => {
  if (
    sender.id !== api.runtime.id ||
    sender.url?.split("?")[0].split("#")[0] !== reader
  )
    return false;
  store.handle(message).then(
    (value) => reply({ value }),
    (error) =>
      reply({
        error: ["otherReader", "pasteInvalid", "readingUnavailable"].includes(
          error.message,
        )
          ? error.message
          : "storageFailed",
      }),
  );
  return true;
});
