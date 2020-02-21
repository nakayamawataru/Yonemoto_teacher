/* eslint-disable require-jsdoc */
/* eslint-disable valid-jsdoc */
const {crawlerData} = require('./crawler');
const {GeoSearch} = require('./geo_location');
const {logger} = require('./logger');
const setup = require('./starter-kit/setup');
const AWS = require('aws-sdk');
// Params test local
const initParams = {
  business: {id: 1, name: 'シースリー札幌大通店', cid: '7501024302981129203'},
  benchmarkBusiness: [
    {id: 1, name: 'シースリー札幌大通店'},
    {id: 2, name: 'シースリー札幌大通店'},
  ],
  keywords: [{id: 1, value: '札幌　脱毛'}],
  baseLocation: 'Sapporo,Hokkaido,Japan',
  baseLocationJapanese: '北海道札幌市',
  date: '2019-08-02',
};

exports.handler = async (event, context, callback) => {
  logger(event);
  // For keeping the browser launch
  const params = {
    business: event.business,
    benchmarkBusiness:
     event.benchmark_business == undefined ? [] : event.benchmark_business,
    keywords: event.keywords,
    baseLocation: event.base_location,
    baseLocationJapanese: event.base_location_japanese,
    date: event.date,
  };
  context.callbackWaitsForEmptyEventLoop = false;
  const browser = await setup.getBrowser();
  try {
    const result = await exports.run(browser, params);
    callback(null, result);
  } catch (e) {
    callback(e);
  }
};

exports.run = async (browser, params=initParams) => {
  // Init brower
  const page = await browser.newPage();

  page.setViewport({
    width: 1920,
    height: 1080,
  });

  // Init params
  const business = params.business;
  const benchmarkBusiness =
    params.benchmarkBusiness == undefined ? [] : params.benchmarkBusiness;
  const keywords = params.keywords;
  const baseLocation = params.baseLocation;
  const baseLocationJapanese = params.baseLocationJapanese;
  const date = params.date;
  const results = [];
  const geo = new GeoSearch();

  // Process all keywords
  for (let keyword of keywords) {
    const url = geo.build({query: keyword.value, location: baseLocation});
    const data = await crawlerData(page, date, url, business,
      benchmarkBusiness, keyword);
    results.push({
      id: keyword.id,
      data: data,
      base_location: baseLocation,
      base_location_japanese: baseLocationJapanese,
    });
  }
  const dataCrawler = {
      date: date,
      business: business,
      keywords: results,
  };

  // Write to DynamoDB
  AWS.config.update({
    region: process.env.DYNAMO_DB_REGION,
    accessKeyId: process.env.ACCESS_KEY_ID,
    secretAccessKey: process.env.SECRET_ACCESS_KEY,
  });

  const docClient = new AWS.DynamoDB.DocumentClient();
  const table = process.env.DYNAMO_DB_TABLE;
  const itemKey = date.replace(/\-/g, '') + '-'+ business.id;
  const paramsDB = {
    TableName: table,
    Item: {
      'key': itemKey,
      'value': JSON.stringify(dataCrawler),
    },
  };

  const dbResult = await new Promise((resolve, reject) => {
    docClient.put(paramsDB, function(err, data) {
      if (err) {
        reject('Unable to add item. Error JSON:',
            JSON.stringify(err, null, 2));
      } else {
        resolve('Added item successful');
      }
    });
  });
  logger(dbResult);
  logger(results);
  await browser.close();
  return 'DONE';
};
