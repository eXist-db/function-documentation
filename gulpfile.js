/*
 * SPDX LGPL-2.1-or-later
 * Copyright (C) 2014 The eXist-db Authors
 */
import { src, dest, series, parallel, watch as gulpWatch } from "gulp";
import { createClient, readOptionsFromEnv } from "@existdb/gulp-exist";
import replace from "@existdb/gulp-replace-tmpl";
import rename from "gulp-rename";
import zip from "gulp-zip";
import header from "gulp-header";
import sourcemaps from "gulp-sourcemaps";
import gulpSass from "gulp-sass";
import * as dartSass from "sass";
import cssnano from "gulp-cssnano";
import svgmin from "gulp-svgmin";
import del from "delete";
import { readFileSync } from "node:fs";

const sass = gulpSass(dartSass);

const packageJson = JSON.parse(readFileSync("./package.json", "utf-8"));
const { version, license, app } = packageJson;

const replacements = [app, { version, license }];

const defaultOptions = { basic_auth: { user: "admin", pass: "" } };
const connectionOptions = Object.assign(defaultOptions, readOptionsFromEnv());

let existClient;
try {
  existClient = createClient(connectionOptions);
} catch (e) {
  // client creation may fail if server is not available; OK for build-only usage
}

const packageFilename = `exist-function-documentation-${version}.xar`;

const paths = {
  input: "src/main/xar-resources",
  staging: ".build",
  output: "dist",
  styles: {
    input: "src/main/frontend/sass/*",
    output: ".build/resources/css",
  },
  svgs: {
    input: "src/main/frontend/svg/*.svg",
    output: ".build/resources/images",
  },
  vendor: {
    scripts: [
      "node_modules/bootstrap/dist/js/bootstrap.min.*",
      "node_modules/@popperjs/core/dist/umd/popper.min.*",
      "node_modules/@highlightjs/cdn-assets/highlight.min.js",
      "node_modules/@highlightjs/cdn-assets/languages/xquery.min.js",
      "node_modules/zero-md/dist/index.min.js",
    ],
    styles: [
      "node_modules/bootstrap/dist/css/bootstrap.min.*",
      "node_modules/@highlightjs/cdn-assets/styles/atom-one-dark.min.css",
      "node_modules/@neos21/bootstrap3-glyphicons/dist/css/*",
    ],
    fonts: ["node_modules/@neos21/bootstrap3-glyphicons/dist/fonts/*"],
  },
};

const banner = {
  min:
    "/*!" +
    ` ${packageJson.name} v${version}` +
    " | (c) " +
    new Date().getFullYear() +
    ` ${packageJson.author}` +
    ` | ${license} License` +
    ` | ${packageJson.repository.url}` +
    " */\n",
};

function clean(cb) {
  del([paths.staging, paths.output], cb);
}
export { clean };

function copyXarResources() {
  return src(`${paths.input}/**/*`, { encoding: false }).pipe(
    dest(paths.staging),
  );
}

function copyProjectFiles() {
  return src(["README.md", "LICENSE"], {
    allowEmpty: true,
    encoding: false,
  }).pipe(dest(paths.staging));
}

function templates() {
  return src("*.tmpl")
    .pipe(replace(replacements, { unprefixed: true }))
    .pipe(
      rename((path) => {
        path.extname = "";
      }),
    )
    .pipe(dest(paths.staging));
}

async function buildStyles() {
  const { default: prefix } = await import("gulp-autoprefixer");
  return src(paths.styles.input)
    .pipe(sourcemaps.init())
    .pipe(sass.sync({ outputStyle: "expanded" }).on("error", sass.logError))
    .pipe(prefix({ cascade: true }))
    .pipe(rename({ suffix: ".min" }))
    .pipe(cssnano({ discardComments: { removeAll: true } }))
    .pipe(header(banner.min))
    .pipe(sourcemaps.write("."))
    .pipe(dest(paths.styles.output));
}

function buildSvgs() {
  return src(paths.svgs.input).pipe(svgmin()).pipe(dest(paths.svgs.output));
}

function copyVendorScripts() {
  return src(paths.vendor.scripts).pipe(
    dest(`${paths.staging}/resources/scripts`),
  );
}

function copyVendorStyles() {
  return src(paths.vendor.styles).pipe(dest(`${paths.staging}/resources/css`));
}

function copyVendorFonts() {
  return src(paths.vendor.fonts, { encoding: false }).pipe(
    dest(`${paths.staging}/resources/fonts`),
  );
}

const copyStatic = parallel(copyVendorFonts, copyVendorScripts, copyVendorStyles);

function createXar() {
  return src(`${paths.staging}/**/*`, { encoding: false, base: paths.staging })
    .pipe(zip(packageFilename))
    .pipe(dest(paths.output));
}

function deployXar() {
  return src(`${paths.output}/${packageFilename}`, { encoding: false }).pipe(
    existClient.install({ packageUri: app.namespace }),
  );
}

const build = series(
  clean,
  parallel(copyXarResources, copyProjectFiles),
  parallel(buildStyles, buildSvgs, copyStatic),
  templates,
  createXar,
);

const install = series(build, deployXar);

export { build, install };

export default series(build, deployXar, function watchTask() {
  gulpWatch(`${paths.input}/**/*`, build);
});
