const fs = require("fs");
const path = require("path");

const builtConfig = path.resolve(__dirname, "storage/build/config/tailwind.config.js");
const defaultConfig = path.resolve(__dirname, "config/tailwind.config.js");
const tailwindConfig = fs.existsSync(builtConfig) ? builtConfig : defaultConfig;

module.exports = {
  plugins: {
    "postcss-import": {},
    "tailwindcss/nesting": {},
    tailwindcss: { config: tailwindConfig },
    autoprefixer: {},
  },
};
