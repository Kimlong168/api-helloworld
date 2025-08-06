const express = require("express");
const router = express.Router();
const todoController = require("../controllers/todo.controller.js");

router.post("/", todoController.create);
router.get("/", todoController.findAll);
router.put("/:id", todoController.update);
router.delete("/:id", todoController.delete);

module.exports = router;
