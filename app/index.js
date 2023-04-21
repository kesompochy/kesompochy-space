const express = require("express");

const app = express();

app.get("/", (req, res) => {
  res.send("ふわふわのアザラシ　セカンドシーズン　改");
});

app.get("toilet", (req, res) => {
  res.send("kesompochyの排泄物コーナー 改");
});

const port = 80;
app.listen(port, () => {
  console.log(`Server is runnig at port ${port}`);
});
