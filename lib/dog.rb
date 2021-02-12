class Dog
  attr_accessor :id, :name, :breed
  def self.all
    DB[:conn].execute("SELECT * FROM dogs").collect {|row|
      self.new_from_db(row)
    }
  end

  def initialize(id:nil, name:, breed:)
    @id, @name, @breed = id, name, breed
  end

  def self.create_table
    sql = <<~SQL
      CREATE TABLE IF NOT EXISTS dogs (
        id INTEGER PRIMARY KEY,
        name TEXT,
        breed TEXT
      )
    SQL

    DB[:conn].execute(sql)
  end

  def self.drop_table
    sql = <<~SQL
      DROP TABLE IF EXISTS dogs
    SQL

    DB[:conn].execute(sql)
  end

  def save
    if self.id
      self.update
    else
      sql = <<~SQL
      INSERT INTO dogs (name, breed) 
      VALUES (?, ?)
    SQL

    DB[:conn].execute(sql, self.name, self.breed)
    self.id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs").first[0]
    end
    
    self
  end

  def self.create(hash)
    Dog.new(name: hash[:name], breed: hash[:breed]).save
  end

  def self.new_from_db(row)
    Dog.new(id: row[0], name: row[1], breed:row[2])
  end

  def self.find_by_id(id)
    sql =<<~SQL
      SELECT * FROM dogs WHERE id = ?
    SQL

    self.new_from_db(DB[:conn].execute(sql, id).flatten)
  end

  def self.find_or_create_by(name:, breed:)
    sql =<<~SQL
      SELECT * FROM dogs WHERE name = ? AND breed = ? LIMIT 1
    SQL

    found = DB[:conn].execute(sql, name, breed)[0]
    found ? self.new_from_db(found) : self.create(name: name, breed: breed)
  end

  def self.find_by_name(name)
    sql =<<~SQL
      SELECT * FROM dogs WHERE name = ?
    SQL

    found = DB[:conn].execute(sql, name)[0]
    found ? self.new_from_db(found) : nil
  end

  def update
    sql =<<~SQL
      UPDATE dogs SET name=?, breed=? WHERE id=?
    SQL

    DB[:conn].execute(sql, self.name, self.breed, self.id)
    self
  end
end