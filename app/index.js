const express = require("express");

const app = express();

app.get("/", (req, res) => {
  res.send("ふわふわのアザラシ");
});

app.get("/toilet", (req, res) => {
  res.send("排泄物コーナー");
});

const port = 80;
app.listen(port, () => {
  console.log(`Server is runnig at port ${port}`);
});
