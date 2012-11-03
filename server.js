(function() {
  var Connection, app, colors, compile, config, connect, crypto, err, express, fs, log, models, mongoose, nib, stylus;

  fs = require('fs');

  crypto = require('crypto');

  mongoose = require('mongoose');

  connect = require('connect');

  stylus = require('stylus');

  nib = require('nib');

  colors = require('colors');

  express = require('express');

  app = express.createServer();

  config = require('./config');

  models = require('./models/models');

  Connection = require('./controllers/mongo');

  compile = function(str, path) {
    return stylus(str).set('filename', path).set('compress', true);
  };

  log = function(message) {
    return console.log(("" + ((new Date()).toString())).cyan + (" " + '[Info]'.green + " " + message));
  };

  err = function(message) {
    return console.log(("" + ((new Date()).toString())).cyan + (" " + '[Error]'.red + " " + message));
  };

  app.use(stylus.middleware({
    src: __dirname + '/views',
    dest: __dirname + '/public',
    compile: function(str, path) {
      return stylus(str).set('filename', path).set('compress', true).use(nib());
    }
  }));

  app.use(require('connect-assets')({
    src: 'public'
  }));

  app.use(express.bodyParser());

  app.use(express.cookieParser());

  app.use(express.session({
    secret: config.session.key
  }));

  app.use(express.favicon(__dirname + '/public/images/favicon.ico'));

  app.set('views', __dirname + '/views');

  app.set('view engine', 'jade');

  app.use(express.static(__dirname + '/public'));

  app.get('/', function(req, res) {
    if (!req.session.authenticated) {
      res.writeHead(302, {
        'Location': '/login'
      });
      return res.end();
    } else {
      res.writeHead(302, {
        'Location': "/user/" + req.session.username
      });
      return res.end();
    }
  });

  app.get('/login', function(req, res) {
    var opts;
    opts = {
      title: 'Login',
      success: true
    };
    return res.render('login.jade', {
      locals: opts
    });
  });

  app.get('/logout', function(req, res) {
    var opts;
    req.session.authenticated = false;
    req.session.username = '';
    opts = {
      title: 'Login',
      success: true
    };
    return res.render('login.jade', {
      locals: opts
    });
  });

  app.get('/user/:username', function(req, res) {
    var ProjectsModel;
    if (!req.session.authenticated) {
      res.writeHead(302, {
        'Location': '/login'
      });
      res.end();
      return;
    } else if (req.params.username !== req.session.username) {
      res.writeHead(302, {
        'Location': "/user/" + req.session.username
      });
      res.end();
      return;
    }
    Connection.connect();
    ProjectsModel = mongoose.model('Projects', models.Projects);
    return ProjectsModel.find({
      $or: [
        {
          owner: req.params.username
        }, {
          allowed: req.params.username
        }
      ]
    }, function(err, projects) {
      var opts, project, _i, _len;
      opts = {
        title: "" + req.params.username + "'s Projects",
        user: req.params.username,
        projects: []
      };
      for (_i = 0, _len = projects.length; _i < _len; _i++) {
        project = projects[_i];
        opts.projects.push({
          id: project.id,
          owner: project.owner,
          name: project.name,
          public: project.public ? 'true' : 'false',
          allowed: project.allowed.join(', ')
        });
      }
      res.render('user.jade', {
        locals: opts
      });
      return Connection.disconnect();
    });
  });

  app.post('/user/:username/add', function(req, res) {
    var ProjectsModel, allowed, newProject;
    Connection.connect();
    ProjectsModel = mongoose.model('Projects', models.Projects);
    newProject = new ProjectsModel();
    newProject.owner = req.body.owner;
    newProject.name = req.body.name;
    newProject.public = req.body.public;
    if (req.body.allowed === '') {
      newProject.allowed = [];
    } else {
      allowed = req.body.allowed;
      allowed = allowed.replace(/\s+/g, '');
      newProject.allowed = allowed.split(',');
    }
    return newProject.save(function() {
      console.log(newProject.id);
      res.send({
        owner: owner,
        name: name,
        public: public,
        allowed: allowed
      });
      return Connection.disconnect();
    });
  });

  app.post('/user/:username/edit', function(req, res) {
    var allowed, editProject, name, owner, public;
    owner = req.body.owner;
    name = req.body.name;
    public = req.body.public;
    if (req.body.allowed === '') {
      allowed = [];
    } else {
      allowed = req.body.allowed.replace(/\s+/g, '').split(',');
    }
    Connection.connect();
    editProject = new ProjectsModel();
    editProject.owner = owner;
    editProject.name = name;
    editProject.public = public;
    return editProject.allowed = allowed;
  });

  app.post('/user/:username/:project', function(req, res) {
    var FilesModel, currentFile, findStuff, parent, project, queue, trail, username;
    username = req.params.username;
    project = req.params.project;
    parent = req.body.parent;
    trail = req.body.trail;
    Connection.connect();
    FilesModel = mongoose.model('Files', models.Files);
    queue = [];
    currentFile = parent;
    queue.push(currentFile);
    findStuff = function(currentFile, callback) {
      return FilesModel.findOne({
        name: currentFile
      }, function(err, file) {
        var _ref;
        currentFile = (_ref = file.parent) != null ? _ref : '';
        queue.push(currentFile);
        if (currentFile === '') {
          return callback();
        } else {
          return findStuff(currentFile, callback);
        }
      });
    };
    if (currentFile !== '') {
      return findStuff(currentFile, function() {
        queue[queue.length - 1] = project;
        trail = queue.reverse();
        return FilesModel.find({
          parent: parent,
          project: project
        }, function(err, files) {
          var ret;
          ret = {
            project: project,
            parent: parent === '' ? project : parent,
            trail: trail,
            files: files
          };
          res.send(ret);
          return Connection.disconnect();
        });
      });
    } else {
      trail = [];
      trail.push(project);
      return FilesModel.find({
        parent: parent,
        project: project
      }, function(err, files) {
        var ret;
        ret = {
          project: project,
          parent: parent === '' ? project : parent,
          trail: trail,
          files: files
        };
        res.send(ret);
        return Connection.disconnect();
      });
    }
  });

  app.post('/login/check', function(req, res) {
    var UsersModel, password, username;
    username = req.body.username;
    password = crypto.createHash('md5').update(req.body.password).digest('hex');
    Connection.connect();
    UsersModel = mongoose.model('Users', models.Users);
    return UsersModel.find({
      username: username,
      password: password
    }, function(err, users) {
      var opts;
      if (users.length === 1) {
        log("User " + users[0].username + " logged in");
        req.session.authenticated = true;
        req.session.username = users[0].username;
        res.writeHead(302, {
          'Location': "/user/" + req.session.username
        });
        return res.end();
      } else {
        opts = {
          title: 'Login',
          success: false
        };
        res.render('login.jade', {
          locals: opts
        });
        return Connection.disconnect();
      }
    });
  });

  app.get('*', function(req, res) {
    err("Unknown page: '" + req.url + "'");
    return res.render('404.jade', {
      locals: {
        title: 'Page not found',
        styles: '404'
      }
    });
  });

  app.listen(config.port);

  log("Server listening on port " + config.port);

}).call(this);
