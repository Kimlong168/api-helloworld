require("dotenv").config(); // 👈 MUST be at the top

const express = require("express");
const bodyParser = require("body-parser");
const db = require("./models");

const app = express();
const PORT = process.env.PORT || 3001; // 👈 use env port if available

app.use(bodyParser.json());

db.sequelize.sync().then(() => {
  console.log("Synced DB.");
});

app.get('/', (req, res) => {
  res.send('🚀 Hello from the Express API!');
});


app.use("/api/todos", require("./routes/todo.routes"));

app.listen(PORT, () => {
  console.log(`Server is running on http://localhost:${PORT}`);
});
