import plugin from "tailwindcss";

/** @type {import('tailwindcss').Config} */
export default {
  theme: {
    extend: {},
  },
  content: ["./src/**/*.{html,js,svelte,ts}"],
  plugins: [
    plugin(function ({ matchUtilities, e, config, theme }) {
      const textBorderSize = `--tw${config("prefix")}-text-border-size`;

      matchUtilities(
        {
          "text-border": (value) => ({
            "text-shadow": `0 0 var(${textBorderSize},1px) ${toColorValue(
              value
            )}`,
          }),
        },
        {
          values: (({ DEFAULT: _, ...colors }) => colors)(
            flattenColorPalette(theme("borderColor"))
          ),
          type: "color",
        }
      );

      matchUtilities(
        {
          "text-border-size": (value) => ({
            [textBorderSize]: value,
          }),
        },
        { values: theme("borderWidth") }
      );
    }),
  ],
};
