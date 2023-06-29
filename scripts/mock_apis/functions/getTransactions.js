module.exports = async function (context, req) {
  context.log("Return some mock transactions data.");

  var response;
  try {
    response = require("./transactions.json");
  } catch {
    response = {};
  }

  context.res = {
    headers: { "Content-Type": "application/json" },
    // status: 200, /* Defaults to 200 */
    body: response,
  };
};
