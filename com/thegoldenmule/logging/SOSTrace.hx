package com.thegoldenmule.logging;

import flash.errors.Error;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.XMLSocket;
import haxe.Log;
import haxe.PosInfos;

/**
 * SOS XML socket trace target.
 * 
 * @author thegoldenmule
 */

class SOSTrace {
	
	private var _socket:XMLSocket;
	private var _server:String;
	private var _port:Int;
	private var _history:Array<Dynamic>;
	
	public function new(server:String = "localhost", port:Int = 4444) {
		_socket = new XMLSocket();
		_server = server;
		_port = port;
		_history = new Array<Dynamic>();
		
		Log.trace = sostrace;
	}
	
	private function sostrace(v:Dynamic, ?inf:PosInfos) {
		if (null == _socket) return;
		
		var logObj:Dynamic = {
			message:Std.string(v),
			parameters:inf
		};
		
		if (_socket.connected) {
			send(logObj);
			return;
		} else if (!_socket.hasEventListener(Event.CONNECT)) {
			_socket.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			_socket.addEventListener(Event.CONNECT, connectHandler, false, 0, true);
			_socket.connect(_server, _port);
			
		}
		
		_history.push(logObj);
	}
	
	private function connectHandler(event:Event):Void {
		// send all items in history
		var log:Dynamic;
		for (log in _history) {
			send(log);
		}
		
		_history = [];
	}
	
	private function errorHandler(event:Event):Void {
		_socket = null;
		_history = [];
	}
	
	private function send(log:Dynamic):Void {
		var message:String = log.message;
		_socket.send("!SOS"
			+ "<showMessage key='debug'>"
			+ log.parameters.fileName + ":" + log.parameters.className + ":" + log.parameters.methodName + ":" + log.parameters.lineNumber + "  "
			+ message
			+ "</showMessage>"
			+ "\n");
	}
}