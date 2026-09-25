import type { GoldieConfig } from "goldie";

const appRoot = "/Users/omegaskiller/SideProjects/flashread-workspace/phralio";

const config: GoldieConfig = {
  appRoot,
  // Flutter does not support Release mode on simulators. This normal Debug
  // build has its debug banner disabled; captured screens are checked below.
  appPath: `${appRoot}/build/ios/iphonesimulator/Runner.app`,
  bundleId: "io.github.omegaskiller.phralio",
  devices: ["iphone-6.9"],
  locales: ["en-US"],
  appearance: "light",
  frame: { variant: "17-pro-silver" },
  theme: {
    background: "linear-gradient(155deg, #F4F0E7 0%, #E7EDE7 100%)",
    headlineColor: "#182523",
    subheadColor: "#40514C",
    fontFamily: '-apple-system, "SF Pro Display", system-ui, sans-serif',
    copyHeightRatio: 0.24,
    deviceWidthRatio: 0.84,
    template: ["hero", "tilt-right", "classic", "offset"],
    layout: "classic",
  },
  // Listing details here only supply the local studio preview. They are not
  // submitted to App Store Connect.
  store: {
    name: "Phralio",
    subtitle: { "en-US": "Read at your own pace" },
    developer: "Phralio",
    category: "Books",
    rating: 0,
    ratingCount: "New",
    ageRating: "4+",
    price: "Free",
    description: {
      "en-US":
        "Make room for a good read. Phralio brings each word to a steady focal point while keeping the surrounding passage close when you pause.\n\nSave text, TXT, Markdown and EPUB readings on your device. Return to your place, star a reading, or bookmark a word. Set a pace that suits the page.",
    },
  },
  scenes: [
    {
      kind: "screenshot",
      id: "context",
      flow: "store-01-context",
      layout: "classic",
      headline: { "en-US": "Read in your own rhythm" },
      subhead: { "en-US": "One clear word, with the passage still close." },
    },
    {
      kind: "screenshot",
      id: "focus",
      flow: "store-02-focus",
      headline: { "en-US": "One word. Full attention." },
      subhead: { "en-US": "Tap into a quiet, focused reading space." },
    },
    {
      kind: "screenshot",
      id: "library",
      flow: "store-03-library",
      headline: { "en-US": "Your place is waiting" },
      subhead: { "en-US": "Come back to the page you left." },
    },
    {
      kind: "screenshot",
      id: "saved",
      flow: "store-04-saved",
      layout: "classic",
      headline: { "en-US": "Keep what matters" },
      subhead: { "en-US": "Star a reading or bookmark a word." },
    },
    {
      kind: "preview",
      id: "preview",
      segments: [
        { id: "open", flow: "store-preview-01-open", holdSeconds: 1.5 },
        { id: "read", flow: "store-preview-02-read", holdSeconds: 1.5 },
        { id: "save", flow: "store-preview-03-save", holdSeconds: 2 },
      ],
    },
  ],
};

export default config;
