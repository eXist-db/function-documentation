/**
 * an example gulpfile to make ant-less existdb package builds a reality
 */
const { src, dest, series, parallel } = require("gulp");
const del = require("delete");
// const gulpEsbuild = require("gulp-esbuild");

const paths = {
  input: "src/main/xar-resources/resources",
  output: "target/generated-resources/frontend/xar-resources/resources/",
  images: {
    input: "src/main/xar-resources/resources/img/*",
    output: "target/generated-resources/frontend/xar-resources/resources/img/",
  },
  scripts: {
    input: "src/main/xar-resources/resources/scripts/*",
    output:
      "target/generated-resources/frontend/xar-resources/resources/scripts/",
  },
  styles: {
    input: "src/main/xar-resources/resources/css/*",
    output: "target/generated-resources/frontend/xar-resources/resources/css/",
  },
  fonts: {
    input: "src/main/xar-resources/resources/fonts/*",
    output:
      "target/generated-resources/frontend/xar-resources/resources/fonts/",
  },
  vendor: {
    scripts: [
      "src/main/xar-resources/resources/scripts/*",
      "node_modules/bootstrap/dist/js/bootstrap.min.*",
      "node_modules/jquery/dist/jquery.min.*",
      "node_modules/prismjs/prism.js",
      "node_modules/prismjs/components/prism-xquery.min.js",
      "node_modules/prismjs/components/prism-java.min.js",
      "node_modules/zero-md/dist/index.min.js"
    ],
    styles: [
      "src/main/xar-resources/resources/css/*",
      "node_modules/bootstrap/dist/css/bootstrap.min.*",
      // 'node_modules/prismjs/themes/*.css'
    ],
    fonts: ["node_modules/bootstrap/dist/fonts/*"],
  },
};

/**
 * Use the `delete` module directly, instead of using gulp-rimraf
 */
function clean(cb) {
  del(paths.output, cb);
}
exports.clean = clean;

function styles() {
  return src(paths.styles.input).pipe(dest(paths.styles.output));
}
exports.styles = styles;

/**
 * minify EcmaSript files and put them into 'build/app/js'
 */
function minifyEs() {
  return (
    src(paths.scripts.input)
      // .pipe(gulpEsbuild())
      .pipe(dest(paths.scripts.output))
  );
}
exports.minify = minifyEs;

// copy fonts
function copyFonts() {
  return src(paths.fonts.input).pipe(
    dest(paths.fonts.output)
  );
}

// copy vendor scripts
function copyVendorScripts() {
  return src(paths.vendor.scripts).pipe(dest(paths.scripts.output));
}

// copy vendor Styles
function copyVendorStyles() {
  return src(paths.vendor.styles).pipe(dest(paths.styles.output));
}

// copy vendor fonts
function copyVendorFonts() {
  return src(paths.vendor.fonts).pipe(
    dest(paths.fonts.output)
  );
}

/**
 * copy vendor scripts, styles and fonts
 */
const copyStatic = parallel(copyFonts, copyVendorFonts, copyVendorScripts, copyVendorStyles);
// exports.copy = copyStatic;

// ///////////////// //
//  composed tasks   //
// ///////////////// //

const build = series(clean, styles, minifyEs, copyStatic);

exports.build = build;

// main task for day to day development
exports.default = build;
