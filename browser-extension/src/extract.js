import { Readability } from "@mozilla/readability";
import { tokenize, validateReading } from "./core.js";

// Operates on a clone only. Website HTML never enters the privileged reader DOM.
export function extractPage(doc) {
  if (doc.querySelectorAll("*").length > 50000) throw Error("pageTooLarge");
  const clone = doc.cloneNode(true);
  const original = [...doc.querySelectorAll("*")],
    copies = [...clone.querySelectorAll("*")];
  let imageBudget = 0;
  original.forEach((el, i) => {
    const copy = copies[i];
    if (!copy) return;
    const style = doc.defaultView?.getComputedStyle(el);
    if (
      el.hidden ||
      el.getAttribute("aria-hidden") === "true" ||
      style?.display === "none" ||
      style?.visibility === "hidden"
    )
      copy.remove();
    if (el.tagName === "IMG") {
      copy.removeAttribute("data-phralio-image");
      // Capture already-loaded pixels only. Cross-origin taint fails closed.
      if (
        imageBudget < 24 &&
        el.complete &&
        el.naturalWidth >= 80 &&
        el.naturalHeight >= 60
      ) {
        imageBudget++;
        try {
          const canvas = doc.createElement("canvas");
          const scale = Math.min(
            1,
            1000 / el.naturalWidth,
            800 / el.naturalHeight,
          );
          canvas.width = Math.round(el.naturalWidth * scale);
          canvas.height = Math.round(el.naturalHeight * scale);
          canvas
            .getContext("2d")
            .drawImage(el, 0, 0, canvas.width, canvas.height);
          const data = canvas.toDataURL("image/jpeg", 0.72);
          if (data.length < 350000)
            copy.setAttribute("data-phralio-image", data);
        } catch {
          /* Keep an honest alt-text placeholder. */
        }
      }
    }
  });
  clone
    .querySelectorAll(
      'script,style,noscript,template,nav,header,footer,aside,form,input,textarea,select,button,iframe,canvas,svg,video,audio,[contenteditable], [role="navigation"], [role="dialog"]',
    )
    .forEach((el) => el.remove());
  const fallback =
    clone.querySelector('article,main,[role="main"]') || clone.body;
  const article = new Readability(clone.cloneNode(true), {
    maxElemsToParse: 50000,
    disableJSONLD: true,
    serializer: (el) => el,
  }).parse();
  const root = article?.content || fallback;
  if (!root) throw Error("emptyPage");
  let text = "";
  const headings = [],
    images = [];
  const boundary = () => {
    if (text && !text.endsWith("\n\n")) text = text.trimEnd() + "\n\n";
  };
  function visit(node) {
    if (node.nodeType === 3) {
      text += node.textContent.replace(/\s+/gu, " ");
      return;
    }
    if (node.nodeType !== 1) return;
    const tag = node.tagName;
    if (["SCRIPT", "STYLE", "FORM", "IFRAME", "SVG"].includes(tag)) return;
    if (tag === "IMG") {
      boundary();
      const position = tokenize(text).length;
      if (images.length < 24) {
        images.push({
          position,
          alt: node.getAttribute("alt") || "",
          data: node.getAttribute("data-phralio-image") || "",
        });
        text += "\uFFFC\n\n";
      }
      return;
    }
    const block =
      /^(P|DIV|SECTION|ARTICLE|H[1-6]|LI|BLOCKQUOTE|PRE|TR|FIGCAPTION)$/.test(
        tag,
      );
    if (block) boundary();
    if (/^H[1-6]$/.test(tag) && node.textContent.trim())
      headings.push({
        title: node.textContent.trim(),
        level: Number(tag[1]),
        position: tokenize(text).length,
      });
    if (tag === "BR") {
      text += "\n";
      return;
    }
    for (const child of node.childNodes) visit(child);
    if (block) boundary();
  }
  visit(root);
  if (!text.replace(/\uFFFC/g, "").trim()) throw Error("emptyPage");
  return validateReading({
    title: article?.title || doc.title,
    text,
    url: doc.URL,
    headings,
    images,
  });
}
