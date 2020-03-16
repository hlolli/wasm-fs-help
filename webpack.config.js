const webpack = require("webpack");
const path = require("path");
const { CleanWebpackPlugin } = require("clean-webpack-plugin");
const HtmlWebpackPlugin = require("html-webpack-plugin");

module.exports = {
  target: "web",
  entry: {
    main: "./src/index.js"
  },
  output: {
    path: path.resolve(__dirname, "public")
  },
  devtool: "source-map",
  devServer: {
    open: true,
    contentBase: path.resolve(__dirname, "public"),
    inline: false
  },
  module: {
    rules: [
      // prevent webpack from doing some black magic
      {
        test: /\.wasm$/i,
        type: "javascript/auto",
        use: "arraybuffer-loader"
      }
    ]
  },
  plugins: [
    new CleanWebpackPlugin(),
    new HtmlWebpackPlugin({ template: "./src/index.html" })
  ]
};
