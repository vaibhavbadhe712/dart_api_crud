import 'dart:io';
import 'package:alfred/alfred.dart';
import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  final app = Alfred();

  // MongoDB connection setup
  final db = Db('mongodb://localhost:27017/'); // Replace with your actual database name
  try {
    await db.open();
    print('MongoDB connected successfully!');
  } catch (e) {
    print('Failed to connect to MongoDB: $e');
    exit(1); // Exit the application with a non-zero status code to indicate failure
  }

  // Define collections
  final usersCollection = db.collection('users');
  final tasksCollection = db.collection('tasks');

  // Insert a test document
  try {
    await usersCollection.insertOne({'username': 'testuser', 'password': 'testpassword'});
    print('Test document inserted successfully!');
  } catch (e) {
    print('Failed to insert test document: $e');
  }
  try {
    await tasksCollection.insertOne({'title': 'task', 'description': 'it is test task created?'}); // Fixed 'titletitle' to 'title'
    print('Task inserted successfully!');
  } catch (e) {
    print('Failed to insert task document: $e');
  }

  // Simple GET endpoint
  app.get('/helloworld', (req, res) => "Hello world! I am Vaibhav");

  // Redirect endpoint
  app.get('/totallynotarickroll', (req, res) => res.redirect(Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ')));

  // Simple login POST API
  app.post('/login', (req, res) async {
    final body = await req.bodyAsJsonMap;
    final username = body['username'];
    final password = body['password'];

    if (username == null || password == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'Username and password are required'};
    }

    // Authenticate user with MongoDB
    try {
      final user = await usersCollection.findOne({'username': username, 'password': password});
      if (user != null) {
        return {'message': 'Login successful', 'token': 'mock-token-123'};
      } else {
        res.statusCode = HttpStatus.unauthorized;
        return {'error': 'Invalid username or password'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while processing the request'};
    }
  });

  // CREATE: Add a new user
  app.post('/users', (req, res) async {
    final body = await req.bodyAsJsonMap;
    final username = body['username'];
    final password = body['password'];

    if (username == null || password == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'Username and password are required'};
    }

    try {
      await usersCollection.insertOne({'username': username, 'password': password});
      return {'message': 'User created successfully'};
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while creating the user'};
    }
  });

  // READ: Get user by ID
  app.get('/users/:id', (req, res) async {
    final id = req.params['id'];
          print("ctId $id");

    if (id == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'ID is required'};
    }

    try {
      final objectId = ObjectId.parse(id);
      print("objectId $objectId");
      final user = await usersCollection.findOne({'_id': objectId});
      print(user);
      if (user != null) {
        return user;
      } else {
        res.statusCode = HttpStatus.notFound;
        return {'error': 'User not found'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while retrieving the user'};
    }
  });

  // READ ALL: Get all users
  app.get('/users', (req, res) async {
    try {
      final users = await usersCollection.find().toList();
      return users;
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while retrieving users'};
    }
  });

  // UPDATE: Update user by ID
  app.put('/users/:id', (req, res) async {
    final id = req.params['id'];
    final body = await req.bodyAsJsonMap;
    final username = body['username'];
    final password = body['password'];

    if (id == null || (username == null && password == null)) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'ID and at least one field (username or password) are required'};
    }

    try {
      final objectId = ObjectId.parse(id);
      final result = await usersCollection.updateOne({
        '_id': objectId
      }, {
        if (username != null) '\$set': {'username': username},
        if (password != null) '\$set': {'password': password}
      });

      if (result.isAcknowledged) {
        return {'message': 'User updated successfully'};
      } else {
        res.statusCode = HttpStatus.notFound;
        return {'error': 'User not found'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while updating the user'};
    }
  });

  // DELETE: Delete user by ID
  app.delete('/users/:id', (req, res) async {
    final id = req.params['id'];
    if (id == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'ID is required'};
    }

    try {
      final objectId = ObjectId.parse(id);
      final result = await usersCollection.deleteOne({'_id': objectId});
      if (result.isAcknowledged) {
        return {'message': 'User deleted successfully'};
      } else {
        res.statusCode = HttpStatus.notFound;
        return {'error': 'User not found'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while deleting the user'};
    }
  });

  // CREATE: Add a new task
  app.post('/tasks', (req, res) async {
    final body = await req.bodyAsJsonMap;
    final title = body['title'];
    final description = body['description'];
    final completed = body['completed'] ?? false;

    if (title == null || description == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'Title and description are required'};
    }

    try {
      await tasksCollection.insertOne({
        'title': title,
        'description': description,
        'completed': completed
      });
      return {'message': 'Task created successfully'};
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while creating the task'};
    }
  });

  // READ: Get task by ID
  app.get('/tasks/:id', (req, res) async {
    final id = req.params['id'];
    if (id == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'ID is required'};
    }

    try {
      final objectId = ObjectId.parse(id);
      final task = await tasksCollection.findOne({'_id': objectId});
      if (task != null) {
        return task;
      } else {
        res.statusCode = HttpStatus.notFound;
        return {'error': 'Task not found'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while retrieving the task'};
    }
  });

  // READ ALL: Get all tasks
  app.get('/tasks', (req, res) async {
    try {
      final tasks = await tasksCollection.find().toList();
      return tasks;
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while retrieving tasks'};
    }
  });

  // UPDATE: Update task by ID
  app.put('/tasks/:id', (req, res) async {
    final id = req.params['id'];
    final body = await req.bodyAsJsonMap;
    final title = body['title'];
    final description = body['description'];
    final completed = body['completed'];

    if (id == null || (title == null && description == null && completed == null)) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'ID and at least one field (title, description, or completed) are required'};
    }

    final updateFields = {};
    if (title != null) updateFields['title'] = title;
    if (description != null) updateFields['description'] = description;
    if (completed != null) updateFields['completed'] = completed;

    if (updateFields.isEmpty) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'No fields to update'};
    }

    try {
      final objectId = ObjectId.parse(id);
      final result = await tasksCollection.updateOne(
        {'_id': objectId},
        {'\$set': updateFields}
      );

      if (result.isAcknowledged) {
        return {'message': 'Task updated successfully'};
      } else {
        res.statusCode = HttpStatus.notFound;
        return {'error': 'Task not found'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while updating the task'};
    }
  });

  // DELETE: Delete task by ID
  app.delete('/tasks/:id', (req, res) async {
    final id = req.params['id'];
    if (id == null) {
      res.statusCode = HttpStatus.badRequest;
      return {'error': 'ID is required'};
    }

    try {
      final objectId = ObjectId.parse(id);
      final result = await tasksCollection.deleteOne({'_id': objectId});
      if (result.isAcknowledged) {
        return {'message': 'Task deleted successfully'};
      } else {
        res.statusCode = HttpStatus.notFound;
        return {'error': 'Task not found'};
      }
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      return {'error': 'An error occurred while deleting the task'};
    }
  });

  final envPort = Platform.environment['PORT'];
  final port = envPort != null ? int.parse(envPort) : 10048; // Changed port to 10048
  final server = await app.listen(port);
  print("Listening on ${server.port}");
}
