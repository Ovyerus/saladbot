module.exports = {
  extends: ["clarity/typescript", "plugin:import/typescript"],
  parserOptions: {
    ecmaVersion: 2019,
    sourceType: "module",
    project: "./tsconfig.eslint.json",
  },
  settings: {
    "import/parsers": {
      "@typescript-eslint/parser": [".ts", ".tsx"],
    },
    "import/resolver": {
      typescript: {
        alwaysTryTypes: true,
      },
    },
  },
  overrides: [
    {
      files: ["migrations/*"],
      rules: {
        "import/prefer-default-export": "off",
        "require-await": "off",
      },
    },
  ],
  rules: {
    "new-cap": "off",
    "@typescript-eslint/no-invalid-this": "off",
    "require-atomic-updates": "off",
  },
};
