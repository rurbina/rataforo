CREATE TABLE settings (
	"key" VARCHAR PRIMARY KEY NOT NULL UNIQUE,
	value VARCHAR
);

CREATE TABLE boards (
	board_id VARCHAR PRIMARY KEY UNIQUE NOT NULL,
	title VARCHAR NOT NULL,
	description VARCHAR,
	sort INTEGER DEFAULT (0)
);

CREATE TABLE sessions (
	session_id VARCHAR PRIMARY KEY,
	user_id VARCHAR REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	last_touch_time DATETIME DEFAULT (datetime('now'))
);

CREATE TABLE threads (
	thread_id INTEGER PRIMARY KEY NOT NULL,
	board_id VARCHAR REFERENCES boards (board_id) ON DELETE NO ACTION ON UPDATE CASCADE MATCH SIMPLE,
	author VARCHAR REFERENCES users (user_id) ON DELETE NO ACTION ON UPDATE CASCADE MATCH SIMPLE,
	subject VARCHAR NOT NULL,
	message TEXT,
	timestamp DATETIME DEFAULT (datetime('now')) NOT NULL
);

CREATE TABLE replies (
	reply_id INTEGER PRIMARY KEY NOT NULL,
	thread_id VARCHAR REFERENCES threads (thread_id) ON DELETE NO ACTION ON UPDATE CASCADE,
	author VARCHAR REFERENCES users (user_id) ON DELETE NO ACTION ON UPDATE CASCADE,
	message TEXT,
	timestamp DATETIME DEFAULT (datetime('now')) NOT NULL
);

CREATE TABLE groups (
	group_id VARCHAR PRIMARY KEY NOT NULL,
	name VARCHAR NOT NULL,
	description TEXT
);

CREATE TABLE users (
	user_id VARCHAR PRIMARY KEY NOT NULL,
	name VARCHAR NOT NULL,
	email VARCHAR,
	gravatar_email TEXT,
	about TEXT,
	timestamp DATETIME DEFAULT (datetime('now')) NOT NULL,
	passwd VARCHAR,
	disabled BOOLEAN NOT NULL DEFAULT (0),
	last_login_time DATETIME,
	confirmed BOOLEAN NOT NULL DEFAULT (0)
);

CREATE TABLE seen_threads (
	user_id VARCHAR NOT NULL REFERENCES users (user_id) ON DELETE CASCADE ON UPDATE CASCADE,
	thread_id VARCHAR NOT NULL REFERENCES threads (thread_id) ON DELETE CASCADE ON UPDATE CASCADE,
	timestamp DATETIME DEFAULT (datetime('now')) NOT NULL,
	PRIMARY KEY (user_id,thread_id)
);

CREATE TABLE new_users (
	user_id VARCHAR PRIMARY KEY NOT NULL,
	email VARCHAR NOT NULL,
	hash TEXT NOT NULL,
	timestamp DATETIME NOT NULL DEFAULT (datetime('now'))
);

