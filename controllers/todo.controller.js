const db = require("../models");
const Todo = db.todos;

exports.create = async (req, res) => {
  try {
    const todo = await Todo.create({ title: req.body.title });
    res.json(todo);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.findAll = async (req, res) => {
  try {
    const todos = await Todo.findAll();
    res.json(todos);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.update = async (req, res) => {
  try {
    const [updated] = await Todo.update(
      { completed: req.body.completed },
      { where: { id: req.params.id } }
    );
    res.json({ updated });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};

exports.delete = async (req, res) => {
  try {
    const deleted = await Todo.destroy({ where: { id: req.params.id } });
    res.json({ deleted });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
};
