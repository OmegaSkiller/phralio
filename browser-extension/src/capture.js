import { extractPage } from "./extract.js";
// executeScript returns this last expression; no page-to-extension message bridge.
export const result = (() => {
  try {
    return { reading: extractPage(document) };
  } catch (error) {
    return {
      error: ["pasteInvalid", "pageTooLarge", "emptyPage"].includes(
        error.message,
      )
        ? error.message
        : "emptyPage",
    };
  }
})();
