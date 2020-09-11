// Load the http module to create an http server.
const http = require("http");
const shell = require("shelljs");
const express = require("express");
const Router = require("express-promise-router");
const bodyParser = require("body-parser");

const app = express();
const PORT = 8090;
const cloudPakRouter = new Router();

app.use(bodyParser.json({ limit: "10mb", extended: true }));

cloudPakRouter.get("/create-mcmcore", async (req, res) => {
  const { ppaKey, ocToken, clusterApiAddress } = req.body;
  const loginCommand = "oc login";
  const loginCommand2 = loginCommand.concat(` --token=${ocToken}`);
  const loginCommand3 = loginCommand2.concat(` --server=${clusterApiAddress}`);
  res.status(200).send("MCM core creation in progress...");
  shell.exec(loginCommand3);
  shell.env["ENTITLED_REGISTRY_KEY"] = ppaKey;
  shell.exec("make -C /usr/src/CP4MCM_20 mcmcore");
});

// Listen on port 8000, IP defaults to 127.0.0.1
app.use(cloudPakRouter);
app.listen(PORT, () => {
  console.log("=".repeat(50));
  console.log("CP4MCM");
  console.log("server port: ", PORT);
  console.log("=".repeat(50));
});
