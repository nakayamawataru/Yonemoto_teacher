const config = require('./config');
const chromium = require('chrome-aws-lambda');

exports.getBrowser = (() => {
  let browser;
  return async () => {
    await chromium.font('https://raw.githack.com/googlefonts/noto-cjk/master/NotoSansJP-Regular.otf');
    if (typeof browser === 'undefined' || !await isBrowserAvailable(browser)) {
      browser = await chromium.puppeteer.launch({
        args: chromium.args,
        defaultViewport: chromium.defaultViewport,
        executablePath: await chromium.executablePath,
        headless: chromium.headless,
      });
      debugLog(async (b) => `launch done: ${await browser.version()}`);
    }
    return browser;
  };
})();

const isBrowserAvailable = async (browser) => {
  try {
    await browser.version();
  } catch (e) {
    debugLog(e); // not opened etc.
    return false;
  }
  return true;
};

const debugLog = (log) => {
  if (config.DEBUG) {
    let message = log;
    if (typeof log === 'function') message = log();
    Promise.resolve(message).then(
      (message) => console.log(message)
    );
  }
};
