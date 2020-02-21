const btoa = require('btoa');

const GeoSearch = function() {
  this.baseUrl = 'https://www.google.co.jp/search?';
  this.lang = 'JA';
  this.glp = 1;
  this.tbm = 'lcl';

  let key = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
      'abcdefghijklmnopqrstuvwxyz0123456789-_';

  let makeHash = function(loc) {
    loc = unescape(encodeURIComponent(loc));
    return 'w+CAIQICI' +
        key[loc.length%key.length] +
        btoa(loc).replace(/\=/g, '').trim();
  };

  this.build = function(input) {
    let hash = makeHash(input.location);
    let params = {
      q: encodeURIComponent(input.query),
      uule: hash,
    };

    if (this.lang) params.hl = this.lang;
    if (this.glp) params.glp = this.glp;
    if (this.tbm) params.tbm = this.tbm;

    let urlParams = Object.keys(params).map(function(k) {
      return k + '=' + params[k];
    }).join('&');

    return this.baseUrl + urlParams;
  };
};

exports.GeoSearch = GeoSearch;
