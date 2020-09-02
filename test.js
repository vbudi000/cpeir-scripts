// Load the http module to create an http server.
const http = require("http");
const shell = require("shelljs");
const express = require("express");
const Router = require("express-promise-router");

const app = express();
const PORT = 8090;
const cloudPakRouter = new Router();

cloudPakRouter.get("/set-environment", async (req, res) => {
  shell.exec("/usr/src/CP4MCM_20/0-setup_env.sh");
  shell.exec("printenv");
  res.status(200).send("Environment set.");
});

// Listen on port 8000, IP defaults to 127.0.0.1
app.use(cloudPakRouter);
app.listen(PORT, () => {
  console.log("=".repeat(50));
  console.log("CP4MCM");
  console.log("server port: ", PORT);
  console.log("=".repeat(50));
});
