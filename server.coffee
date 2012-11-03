# FILE: server.coffee
# PURPOSE: Main server file, to be compiled and run in node
# AUTHOR: Jay Vana <jsvana@mtu.edu>

# Module includes
fs = require 'fs'
crypto = require 'crypto'
mongoose = require 'mongoose'
connect = require 'connect'
stylus = require 'stylus'
nib = require 'nib'
colors = require 'colors'
express = require 'express'
app = express.createServer()

# Custom module includes
config = require './config'
models = require './models/models'
Connection = require './controllers/mongo'

# Compile function for .styl files
compile = (str, path) ->
	stylus(str).set('filename', path).set('compress', true)

# Logs a message to the terminal
log = (message) ->
	console.log "#{(new Date()).toString()}".cyan + " #{'[Info]'.green} #{message}"

# Logs an error to the terminal
err = (message) ->
	console.log "#{(new Date()).toString()}".cyan + " #{'[Error]'.red} #{message}"

# Express configuration
app.use stylus.middleware src: __dirname + '/views', dest: __dirname + '/public', compile: (str, path) -> stylus(str).set('filename', path).set('compress', true).use(nib())
app.use require('connect-assets') src: 'public'
app.use express.bodyParser()
app.use express.cookieParser()
app.use express.session secret: config.session.key
app.use express.favicon(__dirname + '/public/images/favicon.ico')
app.set 'views', __dirname + '/views'
app.set 'view engine', 'jade'
app.use express.static __dirname + '/public'

# Base route, redirects to proper app page
app.get '/', (req, res) ->
	if not req.session.authenticated
		res.writeHead 302, 'Location': '/login'
		res.end()
	else
		res.writeHead 302, 'Location': "/user/#{req.session.username}"
		res.end()

# Login route
app.get '/login', (req, res) ->
	opts =
		title: 'Login'
		success: true

	res.render 'login.jade', locals: opts

# Logout route
app.get '/logout', (req, res) ->
	req.session.authenticated = false
	req.session.username = ''

	opts =
		title: 'Login'
		success: true
	
	res.render 'login.jade', locals: opts

# Main user page route
app.get '/user/:username', (req, res) ->
	if not req.session.authenticated
		res.writeHead 302, 'Location': '/login'
		res.end()
		return
	else if req.params.username isnt req.session.username
		res.writeHead 302, 'Location': "/user/#{req.session.username}"
		res.end()
		return
	
	Connection.connect()
	
	ProjectsModel = mongoose.model 'Projects', models.Projects

	ProjectsModel.find { $or: [ { owner: req.params.username }, { allowed: req.params.username } ] }, (err, projects) ->
		opts = 
			title: "#{req.params.username}'s Projects"
			user: req.params.username
			projects: []

		for project in projects
			opts.projects.push {
				id: project.id
				owner: project.owner
				name: project.name
				public: if project.public then 'true' else 'false'
				allowed: project.allowed.join ', '
			}

		res.render 'user.jade', locals: opts

		Connection.disconnect()

# Route to add project
app.post '/user/:username/add', (req, res) ->
	owner = req.body.owner
	name = req.body.name
	public = req.body.public

	Connection.connect()

	ProjectsModel = mongoose.model 'Projects', models.Projects

	newProject = new ProjectsModel()

	newProject.owner = owner
	newProject.name = name
	newProject.public = public

	if req.body.allowed is ''
		newProject.allowed = []
	else
		allowed = req.body.allowed
		allowed = allowed.replace /\s+/g, ''
		newProject.allowed = allowed.split ','

	newProject.save () ->
		res.send
			id: newProject._id
			owner: owner
			name: name
			public: public
			allowed: allowed
		
		Connection.disconnect()

app.post '/user/:username/edit', (req, res) ->
	id = req.body.id
	owner = req.body.owner
	name = req.body.name
	public = if req.body.public is 'true' then true else false
	if req.body.allowed is ''
		allowed = []
	else
		allowed = req.body.allowed.replace(/\s+/g, '').split ','

	Connection.connect()

	ProjectsModel = mongoose.model 'Projects', models.Projects

	ProjectsModel.update { _id: id }, { $set: { name: name, public: public, allowed: allowed } }, {}, () ->
		# Return data

# Route to list files in project
app.post '/user/:username/:project', (req, res) ->
	username = req.params.username
	project = req.params.project
	parent = req.body.parent
	trail = req.body.trail

	Connection.connect()

	FilesModel = mongoose.model 'Files', models.Files

	queue = []
	currentFile = parent

	queue.push currentFile

	findStuff = (currentFile, callback) ->
		FilesModel.findOne { name: currentFile }, (err, file) ->
			currentFile = file.parent ? ''
			queue.push currentFile
			if currentFile is ''
				callback()
			else
				findStuff currentFile, callback
	
	if currentFile isnt ''
		findStuff currentFile, () ->
			queue[queue.length - 1] = project
			trail = queue.reverse()

			FilesModel.find { parent: parent, project: project }, (err, files) ->
				ret = 
					project: project
					parent: if parent is '' then project else parent
					trail: trail
					files: files
				
				res.send ret

				Connection.disconnect()
	else
		trail = []
		trail.push project
	
		FilesModel.find { parent: parent, project: project }, (err, files) ->
			ret = 
				project: project
				parent: if parent is '' then project else parent
				trail: trail
				files: files
			
			res.send ret

			Connection.disconnect()

# Perform login check
app.post '/login/check', (req, res) ->
	username = req.body.username
	password = crypto.createHash('md5').update(req.body.password).digest 'hex'
	
	Connection.connect()

	UsersModel = mongoose.model 'Users', models.Users

	UsersModel.find { username: username, password: password }, (err, users) ->
		if users.length is 1
			log "User #{users[0].username} logged in"
			req.session.authenticated = true
			req.session.username = users[0].username

			res.writeHead 302, 'Location': "/user/#{req.session.username}"
			res.end()
		else
			opts =
				title: 'Login'
				success: false

			res.render 'login.jade', locals: opts

			Connection.disconnect()

# Unknown page, 404 route
app.get '*', (req, res) ->
	err "Unknown page: '#{req.url}'"
	res.render '404.jade',
		locals:
			title: 'Page not found'
			styles: '404'

# Bind app to port
app.listen config.port

log "Server listening on port #{config.port}"