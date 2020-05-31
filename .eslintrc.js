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
};
