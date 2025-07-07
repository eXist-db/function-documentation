/**
 * an example gulpfile to make ant-less existdb package builds a reality
 */
const { src, dest, series, parallel } = require("gulp");
const del = require("delete");
const rename = require('gulp-rename')
const header = require('gulp-header')

// Styles
const sass = require('gulp-sass')(require('sass'))
const prefix = require('gulp-autoprefixer')
const minify = require('gulp-cssnano')
const sourcemaps = require('gulp-sourcemaps')

// SVGs
const svgmin = require('gulp-svgmin')

const pkg = require('./package.json')


const settings = {
  clean: true,
  scripts: true,
  hjs: false,
  polyfills: false,
  styles: true,
  svgs: true,
  vendor: true
}

/**
 * Template for banner to add to file headers
 */

const banner = {
  full: '/*!\n' +
    ' * <%= package.name %> v<%= package.version %>\n' +
    ' * <%= package.description %>\n' +
    ' * (c) ' + new Date().getFullYear() + ' <%= package.author.name %>\n' +
    ' * <%= package.license %> License\n' +
    ' * <%= package.repository.url %>\n' +
    ' */\n\n',
  min: '/*!' +
    ' <%= package.name %> v<%= package.version %>' +
    ' | (c) ' + new Date().getFullYear() + ' <%= package.author.name %>' +
    ' | <%= package.license %> License' +
    ' | <%= package.repository.url %>' +
    ' */\n'
}

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
    input: "src/main/frontend/sass/*",
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
      "node_modules/@popperjs/core/dist/umd/popper.min.*",
      "node_modules/@highlightjs/cdn-assets/highlight.min.js", 
      "node_modules/@highlightjs/cdn-assets/languages/xquery.min.js",
      "node_modules/zero-md/dist/index.min.js"
    ],
    styles: [
      "node_modules/bootstrap/dist/css/bootstrap.min.*",
      "node_modules/@highlightjs/cdn-assets/styles/atom-one-dark.min.css",
      "node_modules/@neos21/bootstrap3-glyphicons/dist/css/*"
    ],
    fonts: ["node_modules/@neos21/bootstrap3-glyphicons/dist/fonts/*"],
  },
  svgs: {
    input: 'src/main/frontend/svg/*.svg',
    output: 'target/generated-resources/frontend/xar-resources/resources/images/'
  },
};

/**
 * Use the `delete` module directly, instead of using gulp-rimraf
 */
function clean(cb) {
  del(paths.output, cb);
}
exports.clean = clean;

// Process, lint, and minify Sass files
function buildStyles (done) {
  // Make sure this feature is activated before running
  if (!settings.styles) return done()

  // Run tasks on all Sass files
  src(paths.styles.input)
    .pipe(sourcemaps.init())
    .pipe(sass({
      outputStyle: 'expanded',
      sourceComments: true
    }))
    .pipe(prefix({
      cascade: true,
      remove: true
    }))
    // Uncomment if you want the non minified files
    // .pipe(header(banner.full, {
    //   package: pkg
    // }))
    // .pipe(dest(paths.styles.output))
    .pipe(rename({
      suffix: '.min'
    }))
    .pipe(minify({
      discardComments: {
        removeAll: true
      }
    }))
    .pipe(header(banner.min, {
      package: pkg
    }))
    .pipe(sourcemaps.write('.'))
    .pipe(dest(paths.styles.output))

  // Signal completion
  done()
}
exports.styles = buildStyles;

// Optimize SVG files
function minifySvg(done) {
  // Make sure this feature is activated before running
  if (!settings.svgs) return done()

  // Optimize SVG files
  src(paths.svgs.input)
    .pipe(svgmin())
    .pipe(dest(paths.svgs.output))

  // Signal completion
  done()
}

exports.minifySvg = minifySvg;

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
  return src(paths.fonts.input, {encoding: false}).pipe(
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
  return src(paths.vendor.fonts, {encoding: false}).pipe(
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

const build = series(clean, buildStyles, minifySvg, minifyEs, copyStatic);

exports.build = build;

// main task for day to day development
exports.default = build;
