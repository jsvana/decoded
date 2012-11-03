/* FILE: mongo.js
 * PURPOSE: Class to manage connection to MongoDB
 * AUTHOR: Jay Vana <jsvana@mtu.edu>
 */

var mongoose = require('mongoose');

var Connection = function() {
	this.connected = false;

	this.connect = function() {
		mongoose.connect('mongodb://localhost/test');
		this.connected = true;
	}

	this.disconnect = function() {
		mongoose.disconnect();
		this.connected = false;
	}
};

module.exports = new Connection();