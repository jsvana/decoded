# FILE: user.coffee
# PURPOSE: Client-side logic for user.jade
# AUTHOR: Jay Vana <jsvana@mtu.edu>

# forEach iterator
forEach = (array, action) ->
	for element in array
		action element

# Generates HTML tag as JSON
tag = (name, content, attributes) ->
	name: name
	attributes: attributes
	content: content

# Shorthand for 'a' tag
link = (content, attributes) ->
	tag "a", content, attributes

# Shorthand for 'img' tag
image = (attributes) ->
	tag "img", [], attributes

# Escapes text for HTML rendering
escapeHTML = (text) ->
	replacements = [[/&/g, '&amp;']
					[/"/g, '&quot;']
					[/</g, '&lt;']
					[/>/g, '&gt;']]
	forEach replacements, (replace) ->
		text = text.replace replace[0], replace[1]
	text

# Renders HTML
renderHTML = (element) ->
	pieces = []

	renderAttributes = (attributes) ->
		result = []
		if attributes
			for name of attributes 
				result.push ' ' + name + '="' + escapeHTML(attributes[name]) + '"'
		result.join ''
	
	render = (element) ->
		# Text node
		if typeof element is 'string'
			pieces.push escapeHTML element
		# Empty tag
		else if not element.content or element.content.length is 0
			pieces.push '<' + element.name + renderAttributes(element.attributes) + '/>'
		# Tag with content
		else
			pieces.push '<' + element.name + renderAttributes(element.attributes) + '>'
			forEach element.content, render
			pieces.push '</' + element.name + '>'

	forEach element, render
	pieces.join ''

# Handles resizing elements
setCSS = (hide = false) ->
	if hide
		$('#addProject').hide()
		$('#project').hide()
		$('#editProject').hide()
	
	width = $(window).width()

	$('#projects').css minHeight: "#{$(window).height() - 102}px"

	projectsHeight = $('#projects').height()

	$('#addProject').css
		top: '102px'
		left: '302px'
		width: "#{width - 322}px"
		height: "#{projectsHeight - 20}px"
	
	$('#project').css
		top: '102px'
		left: '302px'
		width: "#{width - 322}px"
		height: "#{projectsHeight - 20}px"
	
	$('#editProject').css
		top: '102px'
		left: '302px'
		width: "#{width - 322}px"
		height: "#{projectsHeight - 20}px"
	
	$('#line1').css
		top: '70px'
		left: "#{width - width / 5}px"
		width: "#{width / 5}px"
	
	$('#line2').css
		top: '80px'
		left: "#{width - width / 3}px"
		width: "#{width / 3}px"
	
	$('#line3').css
		top: '90px'
		left: "#{width - width / 1.8}px"
		width: "#{width / 1.8}px"
	
	$('#line4').css
		top: '0px'
		left: "#{width - 70}px"
		height: '100px'
	
	$('#line5').css
		top: '0px'
		left: "#{width - 80}px"
		height: '100px'
	
	$('#line6').css
		top: '0px'
		left: "#{width - 90}px"
		height: '100px'
	
	$('#logout').css
		top: '25px'
		left: "#{width - 57}px"

# Gets file listings from the server
getFiles = (filename, owner, project) ->
	$.ajax
		url: "/user/#{owner}/#{project}/"
		type: 'post'
		data:
			parent: filename
			trail: $('span#projectName').html()
		success: (data) ->
			data.files.sort (a, b) ->
				if a.directory and not b.directory
					return -1
				else if not a.directory and b.directory
					return 1
				else
					return 0

			data.files.sort (a, b) ->
				aName = a.name.toLowerCase()
				bName = b.name.toLowerCase()
				if a.directory is b.directory
					if aName < bName
						return -1
					else if aName > bName
						return 1
					else
						return 0
				else
					return 0
			
			if data.files.length is 0
				ret = [ tag('span', [ 'No files in this directory.' ]) ];
			else
				ret = []

				if data.trail.length > 1
					p = data.trail[data.trail.length - 2]
					upOne = if p is data.project then '' else p

					ret.push link([ tag('p', [ image( { src: '/images/folder_plain.png', style: 'vertical-align:bottom' } ), tag('span', ['..']) ]) ], { href: '#', 'data-parent': upOne, 'data-owner': owner, 'data-project': project, class: 'trailUp' })

				for file in data.files
					ret.push link([ tag('p', [ image( { src: "/images/#{if file.directory then 'folder_plain.png' else 'file_plain.png'}", style: "vertical-align:#{if file.directory then 'bottom' else 'middle'}"}), tag('span', [file.name]), ]) ], { href: '#', class: 'selectFile', 'data-type': (if file.directory then 'directory' else 'file'), 'data-project': project, 'data-owner': owner, 'data-filename': file.name })
			
			trail = []

			for crumb in data.trail
				trail.push link [ crumb ], 
					href: '#'
					class: 'breadcrumb'
					'data-parent': if data.parent is data.project then '' else data.parent
					'data-owner': owner
					'data-project': project

				trail.push tag 'span', [ ' / ' ], style: 'font-size:1em'
			
			$('span#projectName').html renderHTML trail
			$('#projectFiles').html renderHTML ret
			$('#project').show()

# Controller for the dialog box
class Dialog
	constructor: () ->
		@visible = false
		@callback = null
	
	resize: () ->
		maskHeight = $(document).height()
		maskWidth = $(window).width()
		
		dialogTop = (maskHeight / 3 - $('#dialog').height())
		dialogLeft = (maskWidth / 2 - $('#dialog').width() / 2)

		$('#dialog-overlay').css height: maskHeight, width: maskWidth
		$('#dialog').css top: dialogTop, left: dialogLeft
	
	show: (message, type, callback) ->
		@callback = callback
		@visible = true

		@resize()

		if type is 'alert'
			$('#dialog-yes').hide()
			$('#dialog-no').hide()
			$('#dialog-confirm').show()
		else
			$('#dialog-yes').show()
			$('#dialog-no').show()
			$('#dialog-confirm').hide()
		
		$('#dialog-overlay').show()
		$('#dialog').show()
		
		if message?
			$('#dialog-message').html message
	
	close: (type) ->
		$('#dialog-overlay, #dialog').hide()
		@visible = false

		@callback type
	
	isVisible: () ->
		@visible

# $(document).ready()
$ ->
	# Initialize
	setCSS(true)

	dialog = new Dialog()

	# Dialog box close handlers
	$('#dialog-confirm').live 'click', () ->
		dialog.close('confirm')
	
	$('#dialog-yes').live 'click', () ->
		dialog.close('yes')

	$('#dialog-no').live 'click', () ->
		dialog.close('no')
	
	$('.toggle').live 'click', () ->
		$(this).toggleClass 'toggleOn'
		$(this).html if $(this).html() is 'On' then 'Off' else 'On'
	
	# Open project window
	$('.selectProject').live 'click', () ->
		$('#addProject').hide()
		$('#editProject').hide()

		$('span#projectName').html ''
		$('#projectFiles').html ''

		project = $(this).attr 'data-project'
		owner = $(this).attr 'data-owner'

		getFiles '', owner, project

		#dialog.show 'Test', 'confirmation', (type) ->
		#	console.log type
	
	# Close project window
	$('#closeProject').live 'click', () ->
		$('span#projectName').html ''
		$('#projectFiles').html ''
		$('#project').hide()

	# Open project edit window
	$('.editProject').live 'click', () ->
		$('#project').hide()
		$('#addProject').hide()
		$('#editProject').show()

		id = $(this).attr 'data-id'
		project = $(this).attr 'data-project'
		owner = $(this).attr 'data-owner'
		public = if $(this).attr('data-public') is 'true' then 'On' else 'Off'
		allowed = $(this).attr 'data-allowed'

		$('#editProjectName').val project
		$('#editProjectOwner').attr('href', "/user/#{owner}").html owner
		$('#editProjectView').html public
		if public is 'On'
			$('#editProjectView').addClass 'toggleOn'
		else
			$('#editProjectView').removeClass 'toggleOn'
		$('#editProjectAllowed').val allowed
		$('#editProjectSubmit').attr 'data-id': id
	
	# Close project edit window
	$('#closeEditProject').live 'click', () ->
		$('#editProject').hide()
	
	# Open add project window
	$('#openAddProject').on 'click', () =>
		$('#project').hide()
		$('#editProject').hide()
		$('#addProject').show()
	
	# Close add project window
	$('#closeAddProject').on 'click', () =>
		$('#addProject').hide()
		$('#projectName').val ''
	
	# Navigate up one directory
	$('.trailUp').live 'click', () ->
		parent = $(this).attr 'data-parent'
		owner = $(this).attr 'data-owner'
		project = $(this).attr 'data-project'

		getFiles parent, owner, project

	# Navigate to clicked directory in breadcrumb trail
	$('.breadcrumb').live 'click', () ->
		filename = $(this).html()
		owner = $(this).attr 'data-owner'
		project = $(this).attr 'data-project'

		filename = if filename is project then '' else filename

		getFiles filename, owner, project
	
	# Handle clicked file in file listing
	$('.selectFile').live 'click', () ->
		filename = $(this).attr 'data-filename'
		owner = $(this).attr 'data-owner'
		project = $(this).attr 'data-project'
		type = $(this).attr 'data-type'

		if type is 'directory'
			getFiles filename, owner, project
	
	# Submit add project handler
	$('#addProjectSubmit').on 'click', () ->
		name = $('#projectName').val()
		owner = $(this).attr 'data-owner'
		public = $('#addView').hasClass 'toggleOn'
		allowed = $('#addProjectAllowed').val()

		if name.length is 0
			dialog.show 'Your project must have a name!', 'alert', ->
			return

		$.ajax
			url: "/user/#{owner}/add"
			type: 'post'
			data:
				owner: owner
				name: name
				public: public
				allowed: allowed
			success: (data) ->
				html = [ tag('div', [ link( [ image({src: '/images/pencil.png'}) ], { href: '#', style: 'float:left', 'data-project': data.name, 'data-owner': owner, 'data-public': (if data.public then 'true' else 'false'), 'data-allowed': data.allowed, class: 'editProject x' }), tag('div', [ tag('h2', [ link([ data.name ], { href: '#', class: 'selectProject', 'data-project': data.name, 'data-owner': data.owner }) ]), tag('span', [ 'owned by ', link([ data.owner ], { href: "/user/#{data.owner}" })]) ], { style: 'margin-left:40px' }) ], { class: 'project' })]
				
				$('.addProject').before renderHTML html

				$(window).resize()
	
	$('#editProjectSubmit').on 'click', () ->
		id = $(this).attr 'data-id'
		name = $('#editProjectName').val()
		owner = $(this).attr 'data-owner'
		public = $('#editProjectView').hasClass 'toggleOn'
		allowed = $('#editProjectAllowed').val()

		if name.length is 0
			dialog.show 'Your project must have a name!', 'alert', ->
			return

		$.ajax
			url: "/user/#{owner}/edit"
			type: 'post'
			data:
				id: id
				owner: owner
				name: name
				public: public
				allowed: allowed
			success: (data) ->
				console.log data
	
	# Handle keypresses
	$(document).keydown (e) =>
		key = e.keyCode or e.which

		if key is 27 and not dialog.isVisible()
			$('#addProject').hide()
			$('#project').hide()
			$('#editProject').hide()
	
	# Window resize handler
	$(window).resize () ->
		setCSS()