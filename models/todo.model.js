module.exports = (sequelize, DataTypes) => {
  const Todo = sequelize.define("todo", {
    title: {
      type: DataTypes.STRING,
      allowNull: false
    },
    completed: {
      type: DataTypes.BOOLEAN,
      defaultValue: false
    }
  });

  return Todo;
};
