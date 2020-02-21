// ScreenShoot ranking business
const {uploadFile} = require('./upload_s3');
const fs = require('fs');
const dir = '/tmp/';

const screenShoots = async (page, date, business, keyword) => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir);
  }
  let images = [];
  let hintHeight = await page.evaluate((_) => {
    return Promise.resolve(document.querySelector('#center_col').scrollHeight);
  });
  let stepHeight = await page.evaluate((_) => {
    return Promise.resolve(document.querySelector('#center_col').offsetHeight);
  });
  const imageNamePrefix = Date.now();

  const numberHandleScroll = [...Array(10).keys()];
  for (let i of numberHandleScroll) {
    const scroll = i * stepHeight;
    await page.evaluate((position) => {
      const container = document.querySelector('#center_col');
      container.scrollTop = position;
    }, scroll);
    await page.screenshot({
      path: dir + '-' + scroll + '.png',
      fullPage: true,
    });
    const fileName = ('meo_tools/crawlers/' + date + '/businesses/' +
        business.id + '/keywords/' + keyword.id + '/' +
        imageNamePrefix + '-' + scroll + '.png').toString();
    const image = await uploadFile(dir + '-' + scroll + '.png', fileName);
    images.push(image);

    if (scroll + stepHeight > hintHeight) {
      break;
    }
  }

  return images;
};

exports.screenShoots = screenShoots;
