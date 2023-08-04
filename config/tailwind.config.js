const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    colors: {
      ...require('tailwindcss/colors'),
      'green-down-2': '#E8F2EC',
      'dark-palette-p1': '#17161E',
      'dark-palette-p2': '#282733',
      'dark-palette-p3': '#3A3847',
      'dark-palette-p4': '#4D4B5C',
      'dark-gray-palette-p1': '#605E70',
      'dark-gray-palette-p2': '#737185',
      'dark-gray-palette-p3': '#888599',
      'dark-gray-palette-p4': '#9C99AD',
      'dark-gray-palette-p5': '#B1AEC2',
      'light-palette-p1': '#CBC8DB',
      'light-palette-p2': '#E7E6EF',
      'light-palette-p3': '#F2F1F7',
      'light-palette-p4': '#FAF9FD',
      'light-palette-p5': '#FFFFFF',
      'brand-palette-01': '#121D3A',
      'brand-palette-02': '#31388D',
      'brand-palette-03': '#6857D9',
      'brand-palette-04': '#8686E8',
      'brand-palette-05': '#B8C0F4',
      'brand-palette-06': '#D9DEFF',
      'brand-palette-07': '#EDF1FD',
      'brand-palette-08': '#F6F8FE',
      'auxiliary-palette-green': '#259C50',
      'auxiliary-palette-green-down': '#D8F2E1',
      'auxiliary-palette-green-down-2': '#EDF9F1',
      'auxiliary-palette-red': '#CF4F27',
      'auxiliary-palette-red-down': '#FBE0D8',
      'auxiliary-palette-red-down-2': '#FAEEEB',
      'auxiliary-palette-blue': '#5491F5',
      'auxiliary-palette-blue-down': '#DAE8FE',
    },
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
