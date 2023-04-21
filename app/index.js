const express = require("express");

const app = express();

app.get("/", (req, res) => {
  res.send("ふわふわのアザラシ");
});

const port = 8080;
app.listen(port, () => {
  console.log(`Server is runnig at port ${port}`);
});
