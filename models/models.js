/* FILE: models.js
 * PURPOSE: Represent MongoDB schemas in a common location
 * AUTHOR: Jay Vana <jsvana@mtu.edu>
 */

var mongoose = require('mongoose');
var Schema = mongoose.Schema;
var ObjectId = mongoose.ObjectId;

module.exports = {
	"Users": new Schema({
		"username" : String,
		"password" : String
	}),
	"Projects": new Schema({
		"owner": String,
		"name": String,
		"public": Boolean,
		"allowed": [String]
	}),
	"Files": new Schema({
		"name": String,
		"path": String,
		"parent": String,
		"directory": Boolean,
		"project": String,
	})
};