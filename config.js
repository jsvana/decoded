/* FILE: config.js
 * PURPOSE: Configuration for Decoded
 * AUTHOR: Jay Vana <jsvana@mtu.edu>
 */

var config = {
	port: 8080,
	db: {
		hostname: 'localhost',
		username: '',
		password: '',
		database: 'test',
		port: 0
	},
	session: {
		key: 'squemish ossifrage'
	},
	log: {
		file: 'decoded.log'
	}
};

module.exports = config;