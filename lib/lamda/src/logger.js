exports.logger = (content) => {
  if (process.env.DEBUG == 1) {
    console.log(content);
  }
};
