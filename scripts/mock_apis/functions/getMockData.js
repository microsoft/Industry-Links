module.exports = async function (context, req) {
  context.log("Return some mock data.");

  const response = [
    {
      id: 1,
      name: "one",
      description: "The number one",
    },
    {
      id: 2,
      name: "two",
      description: "The number two",
    },
    {
      id: 3,
      name: "three",
      description: "The number three",
    },
    {
      id: 4,
      name: "four",
      description: "The number four",
    },
    {
      id: 5,
      name: "five",
      description: "The number five",
    },
    {
      id: 6,
      name: "six",
      description: "The number six",
    },
    {
      id: 7,
      name: "seven",
      description: "The number seven",
    },
  ];

  context.res = {
    headers: { "Content-Type": "application/json" },
    // status: 200, /* Defaults to 200 */
    body: response,
  };
};
