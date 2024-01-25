// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

import plugin from "tailwindcss/plugin"
import { readdirSync, readFileSync } from "fs"
import { join, basename } from "path"

export const content = [
  "./js/**/*.{js,ts,jsx,tsx}",
  "../lib/housing_app_web.ex",
  "../lib/housing_app_web/**/*.*ex",
  './node_modules/flowbite/**/*.js',
  // './node_modules/@rjsf/**/*.{js,ts,jsx,tsx}',
  '../deps/ash_authentication_phoenix/**/*.ex'
]

export const theme = {
  extend: {
    colors: {
      brand: "#FD4F00",
      primary: { "50": "#eff6ff", "100": "#dbeafe", "200": "#bfdbfe", "300": "#93c5fd", "400": "#60a5fa", "500": "#3b82f6", "600": "#2563eb", "700": "#1d4ed8", "800": "#1e40af", "900": "#1e3a8a", "950": "#172554" }
    }
  },
}

export const darkMode = 'class';

export const plugins = [
  require("@tailwindcss/forms"),
  require('flowbite/plugin'),
  // require("daisyui"),

  // Allows prefixing tailwind classes with LiveView classes to add rules
  // only when LiveView classes are applied, for example:
  //
  //     <div class="phx-click-loading:animate-ping">
  //
  plugin(({ addVariant }) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
  plugin(({ addVariant }) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
  plugin(({ addVariant }) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
  plugin(({ addVariant }) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
  plugin(({ addVariant }) => addVariant("drag-item", [".drag-item&", ".drag-item &"])),
  plugin(({ addVariant }) => addVariant("drag-ghost", [".drag-ghost&", ".drag-ghost &"])),

  // Embeds Heroicons (https://heroicons.com) into your app.css bundle
  // See your `CoreComponents.icon/1` for more information.
  //
  plugin(function ({ matchComponents, theme }) {
    let iconsDir = join(__dirname, "./vendor/heroicons/optimized")
    let values = {}
    let icons = [
      ["", "/24/outline"],
      ["-solid", "/24/solid"],
      ["-mini", "/20/solid"]
    ]
    icons.forEach(([suffix, dir]) => {
      readdirSync(join(iconsDir, dir)).forEach(file => {
        let name = basename(file, ".svg") + suffix
        values[name] = { name, fullPath: join(iconsDir, dir, file) }
      })
    })
    matchComponents({
      "hero": ({ name, fullPath }) => {
        let content = readFileSync(fullPath).toString().replace(/\r?\n|\r/g, "")
        return {
          [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
          "-webkit-mask": `var(--hero-${name})`,
          "mask": `var(--hero-${name})`,
          "mask-repeat": "no-repeat",
          "background-color": "currentColor",
          "vertical-align": "middle",
          "display": "inline-block",
          "width": theme("spacing.5"),
          "height": theme("spacing.5")
        }
      }
    }, { values })
  })
]

export const fontFamily = {
  'body': [
    'Inter',
    'ui-sans-serif',
    'system-ui',
    '-apple-system',
    'system-ui',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'Noto Sans',
    'sans-serif',
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
    'Noto Color Emoji'
  ],
  'sans': [
    'Inter',
    'ui-sans-serif',
    'system-ui',
    '-apple-system',
    'system-ui',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'Noto Sans',
    'sans-serif',
    'Apple Color Emoji',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
    'Noto Color Emoji'
  ]
}
