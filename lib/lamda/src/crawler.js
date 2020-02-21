const {screenShoots} = require('./screen_shoots');
const {uploadFile} = require('./upload_s3');
const dir = '/tmp/';

const crawlerData = async (page, date, url, business, benchmarkBusiness,
  keyword) => {
  let resultKeyword;

  try {
    await page.goto(
      url,
      {waitUntil: ['domcontentloaded', 'networkidle2']}
    );

    const businessCid = await page.evaluate((business) => {
      let businesses = [];
      if (business.cid !== '') {
        let selector = 'div.rl-qs-crs-t > div > a:first-child';
        let titleResults =
            document.querySelectorAll(selector);
        titleResults = [...titleResults];
        for (let i = 0; i < titleResults.length; i++) {
          const item = titleResults[i];
          const tagNameBusiness =
            item.querySelectorAll('div.dbg0pd > div')[0].firstChild.tagName;
          if (tagNameBusiness === undefined) {
            const business =
                {business_cid: item.getAttribute('data-cid')};
            businesses.push(business);
          }
        }

        return businesses;
      }
    }, business);

    const businessName = await page.evaluate((business) => {
      let businesses = [];
      let selector = 'div.dbg0pd > div';
      let titleResults =
        document.querySelectorAll(selector);
      titleResults = [...titleResults];
      for (let i = 0; i < titleResults.length; i++) {
        const item = titleResults[i];
        if (item.firstChild.tagName == undefined) {
          const business = {
            business_name: item.innerText.replace(/\s/g, ''),
          };
          businesses.push(business);
        }
      }

      return businesses;
    }, business);

    await page.waitFor(2000);
    // ScreenShoot ranking business
    const linkScreenShoots = await screenShoots(page, date, business, keyword);

    // Get ranking business
    const rank = getRankBusiness(business, benchmarkBusiness,
      businessCid, businessName);

    // eslint-disable-next-line require-jsdoc
    function getRankBusiness(business, benchmarkBusiness,
      businessCid, businessName) {
      let rankBusiness = 21;
      const rankBenchmarkBusiness = [];
      benchmarkBusiness.forEach((item, _index) => {
        let rankBB = rankByName(businessName, item.name);
        rankBenchmarkBusiness.push({id: item.id, rank: rankBB});
      });


      if (business.cid !== '') {
        businessCid.forEach((item, index) => {
          if (item.business_cid === business.cid) {
            rankBusiness = ++index;
          }
        });
      } else {
        rankBusiness = rankByName(businessName, business.name);
      }

      return [rankBusiness, rankBenchmarkBusiness];
    }

    // eslint-disable-next-line require-jsdoc
    function rankByName(businessName, name) {
      let rank = 21;
      businessName.forEach((item, index) => {
        if (item.business_name === name.replace(/\s/g, '')) {
          rank = ++index;
        }
      });

      return rank;
    }

    resultKeyword = {
      date: date,
      rank: rank[0],
      rankBenchmarkBusiness: rank[1],
      images: linkScreenShoots,
      error: null,
    };
  } catch (e) {
    const imageNamePrefix = Date.now();
    await page.screenshot({
      path: dir + '-' + 'error.png',
      fullPage: true,
    });

    const fileName = ('meo_tools/crawlers-error/' + date + '/businesses/' +
        business.id + '/keywords/' + keyword.id + '/' +
        imageNamePrefix + '-' + 'error.png').toString();
    const image = await uploadFile(dir + '-' + 'error.png', fileName);

    resultKeyword = {
      date: date,
      images: [image],
      error: e.toString(),
    };
  }
  return resultKeyword;
};

exports.crawlerData = crawlerData;
