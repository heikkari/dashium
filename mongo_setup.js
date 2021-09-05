for(const env of ["dev", "prod", "test"]) {
  db = connect(`localhost:27017/${env}`);
  db.users.createIndex({ username: "text" });
}
